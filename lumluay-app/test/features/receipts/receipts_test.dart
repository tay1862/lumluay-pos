import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/features/receipts/data/receipts_repository.dart';

void main() {
  group('Receipt', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'r1',
        'orderId': 'order-1',
        'receiptNumber': 'RCP-001',
        'subtotal': '1500.50',
        'discountAmount': '100',
        'taxAmount': '105.04',
        'serviceCharge': '0',
        'total': '1505.54',
        'paymentMethod': 'cash',
        'createdAt': '2026-04-05T10:00:00Z',
      };

      final receipt = Receipt.fromJson(json);

      expect(receipt.id, 'r1');
      expect(receipt.orderId, 'order-1');
      expect(receipt.receiptNumber, 'RCP-001');
      expect(receipt.subtotal, 1500.50);
      expect(receipt.discountAmount, 100.0);
      expect(receipt.taxAmount, 105.04);
      expect(receipt.total, 1505.54);
      expect(receipt.paymentMethod, 'cash');
    });

    test('fromJson handles null/missing fields with defaults', () {
      final json = {
        'id': 'r2',
        'orderId': 'order-2',
      };

      final receipt = Receipt.fromJson(json);

      expect(receipt.receiptNumber, '');
      expect(receipt.subtotal, 0);
      expect(receipt.discountAmount, 0);
      expect(receipt.paymentMethod, 'cash');
    });

    test('fromJson handles numeric values', () {
      final json = {
        'id': 'r3',
        'orderId': 'order-3',
        'subtotal': 1000,
        'total': 1070,
        'taxAmount': 70,
        'createdAt': '2026-04-05T10:00:00Z',
      };

      final receipt = Receipt.fromJson(json);

      expect(receipt.subtotal, 1000.0);
      expect(receipt.total, 1070.0);
    });
  });
}
