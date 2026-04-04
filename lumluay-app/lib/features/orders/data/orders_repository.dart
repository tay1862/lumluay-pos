import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class OrderSummary {
  final String id;
  final String receiptNumber;
  final String status;
  final String orderType;
  final String? tableName;
  final int itemCount;
  final double totalAmount;
  final DateTime createdAt;

  const OrderSummary({
    required this.id,
    required this.receiptNumber,
    required this.status,
    required this.orderType,
    this.tableName,
    required this.itemCount,
    required this.totalAmount,
    required this.createdAt,
  });

  factory OrderSummary.fromJson(Map<String, dynamic> j) => OrderSummary(
        id: j['id'] as String,
        receiptNumber: j['receiptNumber'] as String? ?? '',
        status: j['status'] as String? ?? 'open',
        orderType: j['orderType'] as String? ?? 'dine_in',
        tableName: j['tableName'] as String?,
        itemCount: (j['itemCount'] as num?)?.toInt() ??
            (j['items'] as List?)?.length ??
            0,
        totalAmount: (j['totalAmount'] as num?)?.toDouble() ?? 0,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class OrderDetail extends OrderSummary {
  final List<OrderItem> items;
  final List<Map<String, dynamic>> payments;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double serviceChargeAmount;
  final String? memberName;

  const OrderDetail({
    required super.id,
    required super.receiptNumber,
    required super.status,
    required super.orderType,
    super.tableName,
    required super.itemCount,
    required super.totalAmount,
    required super.createdAt,
    required this.items,
    required this.payments,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.serviceChargeAmount,
    this.memberName,
  });

  factory OrderDetail.fromJson(Map<String, dynamic> j) {
    final base = OrderSummary.fromJson(j);
    return OrderDetail(
      id: base.id,
      receiptNumber: base.receiptNumber,
      status: base.status,
      orderType: base.orderType,
      tableName: base.tableName,
      itemCount: base.itemCount,
      totalAmount: base.totalAmount,
      createdAt: base.createdAt,
      items: (j['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      payments: (j['payments'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      subtotal: (j['subtotal'] as num?)?.toDouble() ?? 0,
      discountAmount: (j['discountAmount'] as num?)?.toDouble() ?? 0,
      taxAmount: (j['taxAmount'] as num?)?.toDouble() ?? 0,
      serviceChargeAmount:
          (j['serviceChargeAmount'] as num?)?.toDouble() ?? 0,
      memberName: j['memberName'] as String?,
    );
  }
}

class OrderItem {
  final String id;
  final String productName;
  final String? variantName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;
  final String? note;

  const OrderItem({
    required this.id,
    required this.productName,
    this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
    this.note,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) => OrderItem(
        id: j['id'] as String,
        productName: j['productName'] as String? ?? '',
        variantName: j['variantName'] as String?,
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
        unitPrice: (j['unitPrice'] as num?)?.toDouble() ?? 0,
        lineTotal: (j['lineTotal'] as num?)?.toDouble() ?? 0,
        note: j['note'] as String?,
      );
}

class OrdersRepository {
  const OrdersRepository(this._api);
  final ApiClient _api;

  Future<List<OrderSummary>> getOrders(
      {String? status, String? search, int page = 1}) async {
    final resp = await _api.get('/orders', queryParameters: {
      if (status != null && status != 'all') 'status': status,
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page.toString(),
      'limit': '50',
    });
    final list = resp is List ? resp : (resp is Map ? (resp['data'] as List? ?? []) : []);
    return list
        .map((e) => OrderSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<OrderDetail> getOrder(String id) async {
    final resp = await _api.get('/orders/$id');
    return OrderDetail.fromJson(resp as Map<String, dynamic>);
  }

  /// 15.3.5 — Submit a refund for a completed order
  Future<void> refundOrder(String id,
      {double? amount, String? reason}) async {
    await _api.post('/orders/$id/refund', data: {
      if (amount != null) 'amount': amount,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }
}

final ordersRepositoryProvider = Provider<OrdersRepository>(
  (ref) => OrdersRepository(ref.watch(apiClientProvider)),
);

final ordersStatusFilterProvider = StateProvider<String>((ref) => 'all');

final ordersListProvider = FutureProvider<List<OrderSummary>>((ref) {
  final status = ref.watch(ordersStatusFilterProvider);
  return ref.watch(ordersRepositoryProvider).getOrders(status: status);
});

final orderDetailProvider =
    FutureProvider.family<OrderDetail, String>((ref, id) {
  return ref.watch(ordersRepositoryProvider).getOrder(id);
});
