import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connectivity_service.dart';

sealed class ConnectivityState {
  const ConnectivityState();
}

class ConnectivityInitial extends ConnectivityState {
  const ConnectivityInitial();
}

class ConnectivityOnline extends ConnectivityState {
  const ConnectivityOnline();
}

class ConnectivityOffline extends ConnectivityState {
  const ConnectivityOffline();
}

class ConnectivityBloc {
  ConnectivityBloc(this._service) {
    _controller = StreamController<ConnectivityState>.broadcast(
      onListen: _start,
      onCancel: _stop,
    );
  }

  final ConnectivityService _service;
  late final StreamController<ConnectivityState> _controller;
  StreamSubscription<bool>? _sub;

  Stream<ConnectivityState> get stream => _controller.stream;

  Future<void> _start() async {
    final initialOnline = await _service.isOnline;
    _emit(initialOnline ? const ConnectivityOnline() : const ConnectivityOffline());

    _sub ??= _service.onlineStream.listen((online) {
      _emit(online ? const ConnectivityOnline() : const ConnectivityOffline());
    });
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
  }

  void _emit(ConnectivityState state) {
    if (!_controller.isClosed) {
      _controller.add(state);
    }
  }

  Future<void> dispose() async {
    await _stop();
    await _controller.close();
  }
}

final connectivityBlocProvider = Provider<ConnectivityBloc>((ref) {
  final bloc = ConnectivityBloc(ref.watch(connectivityServiceProvider));
  ref.onDispose(() {
    bloc.dispose();
  });
  return bloc;
});

final connectivityBlocStreamProvider = StreamProvider<ConnectivityState>((ref) {
  return ref.watch(connectivityBlocProvider).stream;
});
