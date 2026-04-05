import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/features/stock/data/stock_repository.dart';

void main() {
  group('StockItem', () {
    test('fromJson parses correctly', () {
      final json = {
        'productId': 'p1',
        'productName': 'Pad Thai Sauce',
        'sku': 'PTS-001',
        'quantity': 25.5,
        'reorderPoint': 10.0,
        'status': 'normal',
      };

      final item = StockItem.fromJson(json);

      expect(item.productId, 'p1');
      expect(item.productName, 'Pad Thai Sauce');
      expect(item.sku, 'PTS-001');
      expect(item.quantity, 25.5);
      expect(item.reorderPoint, 10.0);
      expect(item.status, 'normal');
    });

    test('fromJson handles null optional fields', () {
      final json = {
        'productId': 'p1',
        'productName': 'Rice',
        'quantity': 50,
        'status': 'normal',
      };

      final item = StockItem.fromJson(json);

      expect(item.sku, isNull);
      expect(item.reorderPoint, isNull);
    });

    test('fromJson falls back to id when productId missing', () {
      final json = {
        'id': 'fallback-id',
        'name': 'Fallback Name',
        'quantity': 10,
        'status': 'low',
      };

      final item = StockItem.fromJson(json);

      expect(item.productId, 'fallback-id');
      expect(item.productName, 'Fallback Name');
    });
  });

  group('StockMovement', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'm1',
        'productName': 'Rice',
        'type': 'purchase',
        'quantityChange': 100.0,
        'note': 'Monthly restock',
        'createdAt': '2026-04-05T10:00:00Z',
      };

      final movement = StockMovement.fromJson(json);

      expect(movement.id, 'm1');
      expect(movement.productName, 'Rice');
      expect(movement.type, 'purchase');
      expect(movement.quantityChange, 100.0);
      expect(movement.note, 'Monthly restock');
      expect(movement.createdAt.year, 2026);
    });

    test('fromJson handles missing note', () {
      final json = {
        'id': 'm2',
        'productName': 'Salt',
        'type': 'adjustment',
        'quantityChange': -5.0,
        'createdAt': '2026-04-05T10:00:00Z',
      };

      final movement = StockMovement.fromJson(json);

      expect(movement.note, isNull);
      expect(movement.quantityChange, -5.0);
    });
  });
}
