import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/features/kitchen/data/kitchen_repository.dart';

void main() {
  group('KitchenTicket', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'ticket-1',
        'orderReceiptNumber': '#1001',
        'tableName': 'A1',
        'status': 'pending',
        'station': 'grill',
        'items': [
          {'name': 'Pad Thai', 'qty': 2}
        ],
        'createdAt': '2026-04-05T10:00:00Z',
        'startedAt': null,
      };

      final ticket = KitchenTicket.fromJson(json);

      expect(ticket.id, 'ticket-1');
      expect(ticket.orderReceiptNumber, '#1001');
      expect(ticket.tableName, 'A1');
      expect(ticket.status, 'pending');
      expect(ticket.station, 'grill');
      expect(ticket.items, hasLength(1));
      expect(ticket.createdAt.year, 2026);
      expect(ticket.startedAt, isNull);
    });

    test('waitMinutes calculates elapsed time', () {
      final ticket = KitchenTicket(
        id: '1',
        orderReceiptNumber: '#1',
        status: 'pending',
        items: const [],
        createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      );

      expect(ticket.waitMinutes, greaterThanOrEqualTo(20));
    });

    test('isUrgent returns true when waitMinutes >= 15', () {
      final urgentTicket = KitchenTicket(
        id: '1',
        orderReceiptNumber: '#1',
        status: 'pending',
        items: const [],
        createdAt: DateTime.now().subtract(const Duration(minutes: 16)),
      );
      final normalTicket = KitchenTicket(
        id: '2',
        orderReceiptNumber: '#2',
        status: 'pending',
        items: const [],
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      );

      expect(urgentTicket.isUrgent, isTrue);
      expect(normalTicket.isUrgent, isFalse);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'ticket-1',
        'status': 'pending',
        'items': <dynamic>[],
        'createdAt': '2026-04-05T10:00:00Z',
      };

      final ticket = KitchenTicket.fromJson(json);

      expect(ticket.orderReceiptNumber, '');
      expect(ticket.tableName, isNull);
      expect(ticket.station, isNull);
    });
  });
}
