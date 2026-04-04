import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Model
// ─────────────────────────────────────────────────────────────────────────────

class Receipt {
  final String id;
  final String orderId;
  final String receiptNumber;
  final double subtotal;
  final double discountAmount;
  final double taxAmount;
  final double serviceCharge;
  final double total;
  final String paymentMethod;
  final DateTime createdAt;

  const Receipt({
    required this.id,
    required this.orderId,
    required this.receiptNumber,
    required this.subtotal,
    required this.discountAmount,
    required this.taxAmount,
    required this.serviceCharge,
    required this.total,
    required this.paymentMethod,
    required this.createdAt,
  });

  factory Receipt.fromJson(Map<String, dynamic> j) => Receipt(
        id: j['id'] as String,
        orderId: j['orderId'] as String,
        receiptNumber: j['receiptNumber'] as String? ?? '',
        subtotal: double.tryParse('${j['subtotal']}') ?? 0,
        discountAmount: double.tryParse('${j['discountAmount']}') ?? 0,
        taxAmount: double.tryParse('${j['taxAmount']}') ?? 0,
        serviceCharge: double.tryParse('${j['serviceCharge']}') ?? 0,
        total: double.tryParse('${j['total']}') ?? 0,
        paymentMethod: j['paymentMethod'] as String? ?? 'cash',
        createdAt: j['createdAt'] != null
            ? DateTime.tryParse(j['createdAt'] as String) ?? DateTime.now()
            : DateTime.now(),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptsRepository {
  const ReceiptsRepository(this._client);

  final ApiClient _client;

  Future<Receipt> getReceipt(String orderId) async {
    final data = await _client.get<Map<String, dynamic>>('/receipts/$orderId');
    return Receipt.fromJson(data);
  }

  Future<List<Receipt>> getReceipts({int limit = 50, int offset = 0}) async {
    final data = await _client.get<List<dynamic>>(
      '/receipts',
      queryParameters: {'limit': '$limit', 'offset': '$offset'},
    );
    return data.map((e) => Receipt.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final receiptsRepositoryProvider = Provider<ReceiptsRepository>((ref) {
  return ReceiptsRepository(ref.read(apiClientProvider));
});

final receiptProvider = FutureProvider.family<Receipt, String>((ref, orderId) {
  return ref.read(receiptsRepositoryProvider).getReceipt(orderId);
});
