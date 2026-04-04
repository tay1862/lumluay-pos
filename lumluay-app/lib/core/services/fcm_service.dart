import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Background message handler (top-level function required by FCM)
// ─────────────────────────────────────────────────────────────────────────────

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op — local notification is auto-displayed by the OS for data-only msgs.
}

// ─────────────────────────────────────────────────────────────────────────────
// FCM Service — 17.6.5
// ─────────────────────────────────────────────────────────────────────────────
//
// Steps to enable:
//   1. Add google-services.json (Android) / GoogleService-Info.plist (iOS).
//   2. Call FcmService.init() inside bootstrapApp() after
//      WidgetsFlutterBinding.ensureInitialized() and Firebase.initializeApp().
//   3. Send FCM token to the backend via the /notifications/fcm-token endpoint.

class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final _messaging = FirebaseMessaging.instance;
  final _localNotifications = FlutterLocalNotificationsPlugin();

  final _tokenController = StreamController<String>.broadcast();

  /// Stream of FCM token refreshes.
  Stream<String> get tokenStream => _tokenController.stream;

  Future<void> init() async {
    // Request permission (iOS / macOS)
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Register background handler
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Initialise local notifications for foreground messages
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _localNotifications.initialize(
      const InitializationSettings(
          android: androidSettings, iOS: iosSettings),
    );

    // Create high-importance channel (Android 8+)
    const channel = AndroidNotificationChannel(
      'lumluay_high_importance',
      'LUMLUAY Alerts',
      description: 'ออเดอร์และการแจ้งเตือนจาก LUMLUAY POS',
      importance: Importance.max,
    );
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((message) {
      _showLocalNotification(message);
    });

    // Token refresh
    _messaging.onTokenRefresh.listen((token) {
      _tokenController.add(token);
    });
  }

  /// Retrieves the current FCM registration token.
  Future<String?> getToken() => _messaging.getToken();

  void _showLocalNotification(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'lumluay_high_importance',
          'LUMLUAY Alerts',
          channelDescription: 'ออเดอร์และการแจ้งเตือนจาก LUMLUAY POS',
          importance: Importance.max,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
    );
  }

  void dispose() {
    _tokenController.close();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final fcmServiceProvider = Provider<FcmService>((ref) {
  ref.onDispose(FcmService.instance.dispose);
  return FcmService.instance;
});
