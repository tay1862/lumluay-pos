import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:presentation_displays/displays_manager.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dual Screen Service — 17.4.2
// ─────────────────────────────────────────────────────────────────────────────
//
// Presents a named route on a secondary display (Android only) via the
// presentation_displays plugin.  Gracefully degrades to a no-op on iOS/web.
//
// Register your secondary-screen route in your app's router, e.g.:
//   '/customer-display': (ctx) => CustomerDisplayScreen()
//
// Usage:
//   await ref.read(dualScreenServiceProvider).present('/customer-display');
//   await ref.read(dualScreenServiceProvider).dismiss();

class DualScreenService {
  DualScreenService._();

  static final DualScreenService _instance = DualScreenService._();
  factory DualScreenService() => _instance;

  final DisplayManager _manager = DisplayManager();
  int? _activeDisplayId;

  /// Returns true if the device has at least one secondary display available.
  Future<bool> get isSupported async {
    if (kIsWeb) return false;
    try {
      final displays = await _manager.getDisplays(
          category: DISPLAY_CATEGORY_PRESENTATION);
      return (displays ?? []).isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Shows [routerName] on the first available secondary presentation display.
  /// [routerName] must be a route registered in your app's MaterialApp routes.
  /// Returns true if the presentation was started successfully.
  Future<bool> present(String routerName) async {
    if (kIsWeb) return false;
    try {
      final displays = await _manager.getDisplays(
          category: DISPLAY_CATEGORY_PRESENTATION);
      if (displays == null || displays.isEmpty) return false;
      final displayId = displays.first.displayId ?? 0;
      final result = await _manager.showSecondaryDisplay(
        displayId: displayId,
        routerName: routerName,
      );
      if (result == true) {
        _activeDisplayId = displayId;
      }
      return result == true;
    } catch (_) {
      return false;
    }
  }

  /// Dismisses the secondary display presentation.
  Future<void> dismiss() async {
    if (kIsWeb) return;
    final id = _activeDisplayId;
    if (id == null) return;
    try {
      await _manager.hideSecondaryDisplay(displayId: id);
      _activeDisplayId = null;
    } catch (_) {}
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final dualScreenServiceProvider = Provider<DualScreenService>((ref) {
  return DualScreenService();
});

