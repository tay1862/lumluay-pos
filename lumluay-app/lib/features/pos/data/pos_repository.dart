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

/// Fetches categories and products from the API.
final categoriesProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final repo = ref.read(posRepositoryProvider);
  return repo.getCategories();
});

final productsProvider = FutureProvider.family<List<ProductItem>, String?>(
  (ref, categoryId) async {
    final repo = ref.read(posRepositoryProvider);
    final items = await repo.getProducts(categoryId: categoryId);
    return items;
  },
);

class PosRepository {
  final ApiClient _api;
  final ConnectivityService _connectivity;
  final AppDatabase _db;
  final SyncQueueManager _queue;

  PosRepository(this._api, this._connectivity, this._db, this._queue);

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
    await _api.post<void>('/orders/$orderId/confirm');
  }

  Future<void> holdOrder(String orderId) async {
    await _api.post<void>('/orders/$orderId/hold');
  }

  Future<void> resumeOrder(String orderId) async {
    await _api.post<void>('/orders/$orderId/resume');
  }

  Future<void> voidOrder(String orderId, {required String reason}) async {
    await _api.post<void>(
      '/orders/$orderId/void',
      data: {'reason': reason},
    );
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
    String currency = 'THB',
    double? exchangeRate,
    String? reference,
    String? note,
  }) async {
    return _api.post<Map<String, dynamic>>(
      '/orders/$orderId/payments',
      data: {
        'amount': amount,
        'method': method,
        'currency': currency,
        if (exchangeRate != null) 'exchangeRate': exchangeRate,
        if (received != null) 'tendered': received,
        if (reference != null && reference.trim().isNotEmpty) 'reference': reference.trim(),
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }

  Future<Map<String, dynamic>> completeOrder(String orderId) async {
    return _api.post<Map<String, dynamic>>(
      '/orders/$orderId/complete',
      data: const {},
      fromJson: (d) => Map<String, dynamic>.from(d as Map),
    );
  }
}
