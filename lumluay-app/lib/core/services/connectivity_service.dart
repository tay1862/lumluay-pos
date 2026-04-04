import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ConnectivityService
// ─────────────────────────────────────────────────────────────────────────────
class ConnectivityService {
  final _connectivity = Connectivity();

  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged
      .map(_isOnline)
      .asBroadcastStream();

  Future<bool> get isOnline async {
    final result = await _connectivity.checkConnectivity();
    return _isOnline(result);
  }

  static bool _isOnline(List<ConnectivityResult> results) {
    return results.isNotEmpty &&
        results.any((r) =>
            r == ConnectivityResult.mobile ||
            r == ConnectivityResult.wifi ||
            r == ConnectivityResult.ethernet);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// StreamProvider that emits `true` = online, `false` = offline.
final connectivityProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivityServiceProvider);
  // Emit initial value
  yield await service.isOnline;
  // Then listen to changes
  yield* service.onlineStream;
});
