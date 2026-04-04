import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../../features/auth/providers/auth_provider.dart';
import '../network/api_client.dart';
import '../constants/app_constants.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Events emitted by the server
// ─────────────────────────────────────────────────────────────────────────────
abstract class WsEvent {
  const WsEvent();
}

class WsConnected extends WsEvent {
  const WsConnected();
}

class WsDisconnected extends WsEvent {
  const WsDisconnected();
}

class WsOrderCreated extends WsEvent {
  final Map<String, dynamic> data;
  const WsOrderCreated(this.data);
}

class WsOrderUpdated extends WsEvent {
  final Map<String, dynamic> data;
  const WsOrderUpdated(this.data);
}

class WsOrderCompleted extends WsEvent {
  final Map<String, dynamic> data;
  const WsOrderCompleted(this.data);
}

class WsOrderVoided extends WsEvent {
  final Map<String, dynamic> data;
  const WsOrderVoided(this.data);
}

class WsTableStatusChanged extends WsEvent {
  final Map<String, dynamic> data;
  const WsTableStatusChanged(this.data);
}

class WsTableMerged extends WsEvent {
  final Map<String, dynamic> data;
  const WsTableMerged(this.data);
}

class WsQueueAdded extends WsEvent {
  final Map<String, dynamic> data;
  const WsQueueAdded(this.data);
}

class WsQueueCalled extends WsEvent {
  final Map<String, dynamic> data;
  const WsQueueCalled(this.data);
}

class WsQueueCompleted extends WsEvent {
  final Map<String, dynamic> data;
  const WsQueueCompleted(this.data);
}

class WsNotificationNew extends WsEvent {
  final Map<String, dynamic> data;
  const WsNotificationNew(this.data);
}

class WsNotificationRead extends WsEvent {
  final String notificationId;
  const WsNotificationRead(this.notificationId);
}

class WsKitchenTicket extends WsEvent {
  final Map<String, dynamic> data;
  const WsKitchenTicket(this.data);
}

class WsKitchenStatusChanged extends WsEvent {
  final Map<String, dynamic> data;
  const WsKitchenStatusChanged(this.data);
}

class WsOrderStatusChanged extends WsEvent {
  final Map<String, dynamic> data;
  const WsOrderStatusChanged(this.data);
}

// ─────────────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────────────
class WebSocketService {
  io.Socket? _socket;
  final _eventController = StreamController<WsEvent>.broadcast();

  Stream<WsEvent> get events => _eventController.stream;

  bool get isConnected => _socket?.connected == true;

  void connect({required String serverUrl, String? token}) {
    if (_socket != null) disconnect();

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth(token != null ? {'token': token} : {})
          .setReconnectionAttempts(5)
          .setReconnectionDelay(2000)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _emit(const WsConnected());
      })
      ..onDisconnect((_) {
        _emit(const WsDisconnected());
      })
      ..on('kitchen:new-order', (data) {
        _emit(WsKitchenTicket(_toMap(data)));
      })
      ..on('kitchen:status-changed', (data) {
        _emit(WsKitchenStatusChanged(_toMap(data)));
      })
      ..on('order:status-changed', (data) {
        _emit(WsOrderStatusChanged(_toMap(data)));
      })
      ..on('order:created', (data) {
        _emit(WsOrderCreated(_toMap(data)));
      })
      ..on('order:updated', (data) {
        _emit(WsOrderUpdated(_toMap(data)));
      })
      ..on('order:completed', (data) {
        _emit(WsOrderCompleted(_toMap(data)));
      })
      ..on('order:voided', (data) {
        _emit(WsOrderVoided(_toMap(data)));
      })
      ..on('table:status-changed', (data) {
        _emit(WsTableStatusChanged(_toMap(data)));
      })
      ..on('table:merged', (data) {
        _emit(WsTableMerged(_toMap(data)));
      })
      ..on('queue:added', (data) {
        _emit(WsQueueAdded(_toMap(data)));
      })
      ..on('queue:called', (data) {
        _emit(WsQueueCalled(_toMap(data)));
      })
      ..on('queue:completed', (data) {
        _emit(WsQueueCompleted(_toMap(data)));
      })
      ..on('notification:new', (data) {
        _emit(WsNotificationNew(_toMap(data)));
      })
      ..on('notification:read', (data) {
        final map = _toMap(data);
        _emit(WsNotificationRead(map['id'] as String? ?? ''));
      })
      ..connect();
  }

  void joinTenantRoom(String tenantId) {
    _socket?.emit('join:tenant', {'tenantId': tenantId});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }

  void _emit(WsEvent event) {
    if (!_eventController.isClosed) _eventController.add(event);
  }

  static Map<String, dynamic> _toMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    return {};
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final webSocketServiceProvider = Provider<WebSocketService>((ref) {
  final service = WebSocketService();
  ref.onDispose(service.dispose);

  // Auto-connect/disconnect based on auth state
  ref.listen<AuthState>(authProvider, (previous, next) async {
    if (next is AuthAuthenticated) {
      final apiClient = ref.read(apiClientProvider);
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.keyAccessToken);
      service.connect(serverUrl: apiClient.wsBaseUrl, token: token);
      service.joinTenantRoom(next.user.tenantId);
    } else if (next is AuthUnauthenticated) {
      service.disconnect();
    }
  });

  // Also connect immediately if already authenticated at provider creation
  final authState = ref.read(authProvider);
  if (authState is AuthAuthenticated) {
    () async {
      final apiClient = ref.read(apiClientProvider);
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: AppConstants.keyAccessToken);
      service.connect(serverUrl: apiClient.wsBaseUrl, token: token);
      service.joinTenantRoom(authState.user.tenantId);
    }();
  }

  return service;
});

/// Convenience stream provider for kitchen-only events.
final kitchenWsProvider = StreamProvider<WsEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.events.where(
    (e) => e is WsKitchenTicket || e is WsKitchenStatusChanged,
  );
});

/// Stream of order events (created / updated / status-changed / completed / voided).
final orderWsProvider = StreamProvider<WsEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.events.where(
    (e) =>
        e is WsOrderCreated ||
        e is WsOrderUpdated ||
        e is WsOrderStatusChanged ||
        e is WsOrderCompleted ||
        e is WsOrderVoided,
  );
});

/// Stream of table events.
final tableWsProvider = StreamProvider<WsEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.events.where(
    (e) => e is WsTableStatusChanged || e is WsTableMerged,
  );
});

/// Stream of queue events.
final queueWsProvider = StreamProvider<WsEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.events.where(
    (e) => e is WsQueueAdded || e is WsQueueCalled || e is WsQueueCompleted,
  );
});

/// Stream of notification events.
final notificationWsProvider = StreamProvider<WsEvent>((ref) {
  final service = ref.watch(webSocketServiceProvider);
  return service.events.where(
    (e) => e is WsNotificationNew || e is WsNotificationRead,
  );
});
