import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/notifications_repository.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/services/local_notification_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────────

class NotificationState {
  final List<AppNotification> notifications;
  final bool isLoading;
  final String? error;

  const NotificationState({
    this.notifications = const [],
    this.isLoading = false,
    this.error,
  });

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  NotificationState copyWith({
    List<AppNotification>? notifications,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notifier
// ─────────────────────────────────────────────────────────────────────────────

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationsRepository _repo;
  final LocalNotificationService _localNotif;

  NotificationNotifier(this._repo, this._localNotif)
      : super(const NotificationState());

  Future<void> load({bool unreadOnly = false}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final list = await _repo.getNotifications(unreadOnly: unreadOnly);
      state = state.copyWith(notifications: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    await _repo.markAsRead(id);
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == id ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }

  Future<void> markAllAsRead() async {
    await _repo.markAllAsRead();
    state = state.copyWith(
      notifications:
          state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
  }

  Future<void> delete(String id) async {
    await _repo.deleteNotification(id);
    state = state.copyWith(
      notifications: state.notifications.where((n) => n.id != id).toList(),
    );
  }

  /// Called by WebSocket listener when a new notification arrives.
  Future<void> onWsNotificationNew(Map<String, dynamic> data) async {
    final notification = AppNotification.fromJson(data);
    state = state.copyWith(
      notifications: [notification, ...state.notifications],
    );
    await _localNotif.show(
      id: notification.id.hashCode,
      title: notification.title,
      body: notification.body,
      payload: notification.id,
    );
  }

  /// Called by WebSocket listener when a notification is read remotely.
  void onWsNotificationRead(String notificationId) {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == notificationId ? n.copyWith(isRead: true) : n)
          .toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final notificationNotifierProvider =
    StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  final notifier = NotificationNotifier(
    ref.watch(notificationsRepositoryProvider),
    ref.watch(localNotificationServiceProvider),
  );

  // React to real-time WebSocket events
  ref.listen<AsyncValue<WsEvent>>(notificationWsProvider, (_, next) {
    next.whenData((event) {
      if (event is WsNotificationNew) {
        notifier.onWsNotificationNew(event.data);
      } else if (event is WsNotificationRead) {
        notifier.onWsNotificationRead(event.notificationId);
      }
    });
  });

  // Initial load
  notifier.load();

  return notifier;
});

final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationNotifierProvider).unreadCount;
});
