import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class StockItem {
  final String productId;
  final String productName;
  final String? sku;
  final double quantity;
  final double? reorderPoint;
  final String status; // normal | low | out

  const StockItem({
    required this.productId,
    required this.productName,
    this.sku,
    required this.quantity,
    this.reorderPoint,
    required this.status,
  });

  factory StockItem.fromJson(Map<String, dynamic> j) => StockItem(
        productId: j['productId'] as String? ?? j['id'] as String? ?? '',
        productName: j['productName'] as String? ?? j['name'] as String? ?? '',
        sku: j['sku'] as String?,
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        reorderPoint: (j['reorderPoint'] as num?)?.toDouble(),
        status: j['status'] as String? ?? 'normal',
      );
}

class StockMovement {
  final String id;
  final String productName;
  final String type;
  final double quantityChange;
  final String? note;
  final DateTime createdAt;

  const StockMovement({
    required this.id,
    required this.productName,
    required this.type,
    required this.quantityChange,
    this.note,
    required this.createdAt,
  });

  factory StockMovement.fromJson(Map<String, dynamic> j) => StockMovement(
        id: j['id'] as String,
        productName: j['productName'] as String? ?? '',
        type: j['type'] as String? ?? '',
        quantityChange: (j['quantityChange'] as num?)?.toDouble() ?? 0,
        note: j['note'] as String?,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );
}

class StockRepository {
  const StockRepository(this._api);
  final ApiClient _api;

  Future<List<StockItem>> getStock() async {
    final resp = await _api.get('/stock');
    final list = resp is List ? resp : [];
    return list
        .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<StockMovement>> getMovements({String? productId}) async {
    final resp = await _api.get('/stock/movements',
        queryParameters: {
          if (productId != null) 'productId': productId,
        });
    final list = resp is List ? resp : [];
    return list
        .map((e) => StockMovement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> adjust({
    required List<Map<String, dynamic>> adjustments,
    required String type,
    String? note,
  }) async {
    await _api.post('/stock/adjust', data: {
      'adjustments': adjustments,
      'type': type,
      if (note != null) 'note': note,
    });
  }
}

final stockRepositoryProvider = Provider<StockRepository>(
  (ref) => StockRepository(ref.watch(apiClientProvider)),
);

final stockListProvider = FutureProvider<List<StockItem>>((ref) {
  return ref.watch(stockRepositoryProvider).getStock();
});

final stockMovementsProvider = FutureProvider<List<StockMovement>>((ref) {
  return ref.watch(stockRepositoryProvider).getMovements();
});
