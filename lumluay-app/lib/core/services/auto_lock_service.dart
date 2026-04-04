import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';

/// Default idle minutes before triggering lock.
const int _kDefaultLockMinutes = 5;

// ---------------------------------------------------------------------------
// Provider — configurable lock timeout (minutes). 0 = disabled.
// ---------------------------------------------------------------------------
final autoLockMinutesProvider = StateProvider<int>((ref) => _kDefaultLockMinutes);

// ---------------------------------------------------------------------------
// AutoLockService
// ---------------------------------------------------------------------------
class AutoLockService {
  AutoLockService(this._ref);

  final Ref _ref;
  Timer? _timer;

  /// Must be called once from the widget tree with the root navigator context.
  void attach(BuildContext context) {
    _context = context;
    _resetTimer();
  }

  BuildContext? _context;

  void _resetTimer() {
    _timer?.cancel();
    final minutes = _ref.read(autoLockMinutesProvider);
    if (minutes <= 0) return; // disabled
    _timer = Timer(Duration(minutes: minutes), _lock);
  }

  void onUserActivity() => _resetTimer();

  void _lock() {
    final authState = _ref.read(authProvider);
    if (authState is! AuthAuthenticated) return;
    final ctx = _context;
    if (ctx == null || !ctx.mounted) return;
    ctx.go('/pin?userId=${authState.user.id}');
  }

  void dispose() {
    _timer?.cancel();
  }
}

final autoLockServiceProvider = Provider<AutoLockService>((ref) {
  final svc = AutoLockService(ref);
  ref.onDispose(svc.dispose);
  return svc;
});

// ---------------------------------------------------------------------------
// UserActivityDetector — wraps a widget tree and forwards pointer events to
// AutoLockService so the idle timer resets on any tap/scroll/drag.
// ---------------------------------------------------------------------------
class UserActivityDetector extends ConsumerWidget {
  const UserActivityDetector({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final svc = ref.read(autoLockServiceProvider);
    // Attach the current context so the service can navigate.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) svc.attach(context);
    });
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => svc.onUserActivity(),
      onPointerMove: (_) => svc.onUserActivity(),
      child: child,
    );
  }
}
