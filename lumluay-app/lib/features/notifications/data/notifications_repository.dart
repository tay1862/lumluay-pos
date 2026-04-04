import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
class AppNotification {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic>? metadata;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.metadata,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) {
    return AppNotification(
      id: '${j['id']}',
      title: '${j['title']}',
      body: '${j['body']}',
      type: '${j['type']}',
      isRead: j['isRead'] == true || j['isRead'] == 1,
      createdAt:
          DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
      metadata: j['metadata'] as Map<String, dynamic>?,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      metadata: metadata,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────
class NotificationsRepository {
  const NotificationsRepository(this._client);
  final ApiClient _client;

  Future<List<AppNotification>> getNotifications({bool? unreadOnly}) async {
    final params = <String, String>{};
    if (unreadOnly == true) params['unread'] = 'true';
    final data =
        await _client.get('/notifications', queryParameters: params);
    final list = (data as List<dynamic>);
    return list
        .map((e) =>
            AppNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> markAsRead(String id) async {
    await _client.patch('/notifications/$id/read', data: {});
  }

  Future<void> markAllAsRead() async {
    await _client.patch('/notifications/read-all', data: {});
  }

  Future<void> deleteNotification(String id) async {
    await _client.delete('/notifications/$id');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final notificationsRepositoryProvider = Provider((ref) {
  return NotificationsRepository(ref.watch(apiClientProvider));
});

final notificationsUnreadOnlyProvider = StateProvider<bool>((ref) => false);

final notificationsListProvider = FutureProvider((ref) {
  final repo = ref.watch(notificationsRepositoryProvider);
  final unreadOnly = ref.watch(notificationsUnreadOnlyProvider);
  return repo.getNotifications(unreadOnly: unreadOnly);
});

final unreadCountProvider = FutureProvider((ref) async {
  final notifications = await ref.watch(notificationsListProvider.future);
  return notifications.where((n) => !n.isRead).length;
});
