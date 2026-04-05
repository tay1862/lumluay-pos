import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/database/app_database.dart';
import '../../../core/sync/sync_queue_manager.dart';
import '../providers/cart_provider.dart';

const _uuid = Uuid();

final posRepositoryProvider = Provider<PosRepository>(
  (ref) => PosRepository(
    ref.read(apiClientProvider),
    ref.read(connectivityServiceProvider),
    ref.read(appDatabaseProvider),
    ref.read(syncQueueManagerProvider),
  ),
);

/// POS reads from the local Drift cache so initial sync and background sync
/// can refresh the UI without extra provider invalidation.
final categoriesProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final repo = ref.read(posRepositoryProvider);
  return repo.watchCategories();
});

final productsProvider = StreamProvider.family<List<ProductItem>, String?>(
  (ref, categoryId) {
    final repo = ref.read(posRepositoryProvider);
    return repo.watchProducts(categoryId: categoryId);
  },
);

class PosRepository {
  final ApiClient _api;
  final ConnectivityService _connectivity;
  final AppDatabase _db;
  final SyncQueueManager _queue;

  PosRepository(this._api, this._connectivity, this._db, this._queue);

  Stream<List<Map<String, dynamic>>> watchCategories() {
    return _db.productsDao.watchAllCategories().map(
          (rows) => rows
              .map(
                (row) => <String, dynamic>{
                  'id': row.id,
                  'name': row.name,
                  'sortOrder': row.sortOrder,
                },
              )
              .toList(),
        );
  }

  Stream<List<ProductItem>> watchProducts({String? categoryId}) {
    return _db.productsDao.watchProducts(categoryId: categoryId).map(
          (rows) => rows
              .map(
                (row) => ProductItem(
                  id: row.id,
                  name: row.name,
                  imageUrl: row.imageUrl,
                  price: row.basePrice,
                  sku: row.sku,
                  productType: row.productType,
                  categoryId: row.categoryId ?? '',
                  isAvailable: row.isActive,
                ),
              )
              .toList(),
        );
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    return _api.get<List<Map<String, dynamic>>>(
      '/categories',
      fromJson: (d) =>
          (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  Future<List<ProductItem>> getProducts({String? categoryId, String? search}) async {
    final query = <String, dynamic>{};
    if (categoryId != null && categoryId.isNotEmpty) query['categoryId'] = categoryId;
    if (search != null && search.trim().isNotEmpty) query['search'] = search.trim();

    return _api.get<List<ProductItem>>(
      '/products',
      queryParameters: query.isEmpty ? null : query,
      fromJson: (d) {
        final raw = d is Map<String, dynamic> ? (d['items'] ?? d['data']) : d;
        final list = (raw as List)
            .map((e) => ProductItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        return list;
      },
    );
  }

  Future<Map<String, dynamic>> createOrder(CartState cart) async {
    final online = await _connectivity.isOnline;

    if (online) {
      return _api.post<Map<String, dynamic>>(
        '/orders',
        data: {
          'orderType': cart.orderType,
          if (cart.tableId != null) 'tableId': cart.tableId,
          if (cart.memberId != null) 'customerId': cart.memberId,
          'items': cart.items
              .map((i) => {
                    'productId': i.productId,
                    'quantity': i.quantity,
                    if (i.note != null) 'note': i.note,
                  })
              .toList(),
        },
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
    }

    // ── Offline fallback ──────────────────────────────────────────────────
    final orderId = _uuid.v4();
    final receiptNumber = 'OFF-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now().toIso8601String();

    await _db.ordersDao.insertOrder(
      LocalOrdersCompanion.insert(
        id: orderId,
        receiptNumber: receiptNumber,
        status: const Value('open'),
        orderType: Value(cart.orderType),
        tableId: Value(cart.tableId),
        memberId: Value(cart.memberId),
        subtotal: Value(cart.subtotal),
        discountAmount: Value(cart.discountAmount),
        taxAmount: const Value(0),
        totalAmount: Value(cart.total),
        createdAt: now,
        isSynced: const Value(false),
      ),
    );

    for (final item in cart.items) {
      await _db.ordersDao.insertOrderItem(
        LocalOrderItemsCompanion.insert(
          id: _uuid.v4(),
          orderId: orderId,
          productId: item.productId,
          productName: item.productName,
          unitPrice: Value(item.unitPrice),
          quantity: Value(item.quantity),
          lineTotal: Value(item.lineTotal),
          note: Value(item.note),
        ),
      );
    }

    await _queue.enqueue(
      operation: 'create',
      entityType: 'order',
      entityId: orderId,
      payload: {
        'id': orderId,
        'receiptNumber': receiptNumber,
        'orderType': cart.orderType,
        if (cart.tableId != null) 'tableId': cart.tableId,
        if (cart.memberId != null) 'customerId': cart.memberId,
        'items': cart.items
            .map((i) => {
                  'productId': i.productId,
                  'quantity': i.quantity,
                  if (i.note != null) 'note': i.note,
                })
            .toList(),
      },
    );

    return {
      'id': orderId,
      'receiptNumber': receiptNumber,
      'status': 'open',
      'offline': true,
    };
  }

  Future<void> confirmOrder(String orderId) async {
    final online = await _connectivity.isOnline;
    if (online) {
      await _api.post<void>('/orders/$orderId/confirm');
    } else {
      await _queue.enqueue(
        operation: 'update',
        entityType: 'order',
        entityId: orderId,
        payload: {'id': orderId, 'action': 'confirm'},
      );
    }
  }

  Future<void> holdOrder(String orderId) async {
    final online = await _connectivity.isOnline;
    if (online) {
      await _api.post<void>('/orders/$orderId/hold');
    } else {
      await _db.ordersDao.updateOrderStatus(orderId, 'held');
      await _queue.enqueue(
        operation: 'update',
        entityType: 'order',
        entityId: orderId,
        payload: {'id': orderId, 'action': 'hold'},
      );
    }
  }

  Future<void> resumeOrder(String orderId) async {
    final online = await _connectivity.isOnline;
    if (online) {
      await _api.post<void>('/orders/$orderId/resume');
    } else {
      await _db.ordersDao.updateOrderStatus(orderId, 'open');
      await _queue.enqueue(
        operation: 'update',
        entityType: 'order',
        entityId: orderId,
        payload: {'id': orderId, 'action': 'resume'},
      );
    }
  }

  Future<void> voidOrder(String orderId, {required String reason}) async {
    final online = await _connectivity.isOnline;
    if (online) {
      await _api.post<void>(
        '/orders/$orderId/void',
        data: {'reason': reason},
      );
    } else {
      await _db.ordersDao.updateOrderStatus(orderId, 'voided');
      await _queue.enqueue(
        operation: 'update',
        entityType: 'order',
        entityId: orderId,
        payload: {'id': orderId, 'action': 'void', 'reason': reason},
      );
    }
  }

  Future<List<Map<String, dynamic>>> getProductModifiers(
      String productId) async {
    return _api.get<List<Map<String, dynamic>>>(
      '/products/$productId/modifier-groups',
      fromJson: (d) =>
          (d as List).map((e) => Map<String, dynamic>.from(e as Map)).toList(),
    );
  }

  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required double amount,
    required String method,
    double? received,
    String currency = 'LAK',
    double? exchangeRate,
    String? reference,
    String? note,
  }) async {
    final paymentData = {
      'amount': amount,
      'method': method,
      'currency': currency,
      if (exchangeRate != null) 'exchangeRate': exchangeRate,
      if (received != null) 'tendered': received,
      if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
      if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
    };

    final online = await _connectivity.isOnline;
    if (online) {
      return _api.post<Map<String, dynamic>>(
        '/orders/$orderId/payments',
        data: paymentData,
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
    }

    // Offline: store locally and enqueue sync
    final paymentId = _uuid.v4();
    final now = DateTime.now().toIso8601String();
    await _db.paymentsDao.insertPayment(
      LocalPaymentsCompanion(
        id: Value(paymentId),
        orderId: Value(orderId),
        method: Value(method),
        amount: Value(amount),
        reference: Value(reference),
        createdAt: Value(now),
        isSynced: const Value(false),
      ),
    );
    await _queue.enqueue(
      operation: 'create',
      entityType: 'payment',
      entityId: paymentId,
      payload: {'id': paymentId, 'orderId': orderId, ...paymentData},
    );
    return {'id': paymentId, 'orderId': orderId, ...paymentData, 'createdAt': now};
  }

  Future<Map<String, dynamic>> completeOrder(String orderId) async {
    final online = await _connectivity.isOnline;
    if (online) {
      return _api.post<Map<String, dynamic>>(
        '/orders/$orderId/complete',
        data: const {},
        fromJson: (d) => Map<String, dynamic>.from(d as Map),
      );
    }

    // Offline: update local status and enqueue sync
    await _db.ordersDao.updateOrderStatus(orderId, 'completed');
    await _queue.enqueue(
      operation: 'update',
      entityType: 'order',
      entityId: orderId,
      payload: {'id': orderId, 'action': 'complete'},
    );
    return {'id': orderId, 'status': 'completed'};
  }
}
