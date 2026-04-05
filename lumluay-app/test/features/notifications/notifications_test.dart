import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/features/notifications/data/notifications_repository.dart';

void main() {
  group('AppNotification', () {
    test('fromJson parses correctly', () {
      final json = {
        'id': 'n1',
        'title': 'New Order',
        'body': 'Order #1001 received',
        'type': 'order',
        'isRead': false,
        'createdAt': '2026-04-05T10:00:00Z',
        'metadata': {'orderId': 'order-1'},
      };

      final notif = AppNotification.fromJson(json);

      expect(notif.id, 'n1');
      expect(notif.title, 'New Order');
      expect(notif.body, 'Order #1001 received');
      expect(notif.type, 'order');
      expect(notif.isRead, isFalse);
      expect(notif.createdAt.year, 2026);
      expect(notif.metadata?['orderId'], 'order-1');
    });

    test('fromJson handles isRead as integer (SQLite compat)', () {
      final json = {
        'id': 'n1',
        'title': 'Alert',
        'body': 'Low stock',
        'type': 'stock',
        'isRead': 1,
        'createdAt': '2026-04-05T10:00:00Z',
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.isRead, isTrue);
    });

    test('fromJson handles null metadata', () {
      final json = {
        'id': 'n2',
        'title': 'System',
        'body': 'Update available',
        'type': 'system',
        'isRead': false,
        'createdAt': '2026-04-05T10:00:00Z',
      };

      final notif = AppNotification.fromJson(json);
      expect(notif.metadata, isNull);
    });

    test('copyWith creates new instance with updated isRead', () {
      final original = AppNotification(
        id: 'n1',
        title: 'Test',
        body: 'Body',
        type: 'test',
        isRead: false,
        createdAt: DateTime(2026, 4, 5),
      );

      final updated = original.copyWith(isRead: true);

      expect(updated.isRead, isTrue);
      expect(updated.id, 'n1');
      expect(updated.title, 'Test');
      // Original unchanged
      expect(original.isRead, isFalse);
    });
  });
}
