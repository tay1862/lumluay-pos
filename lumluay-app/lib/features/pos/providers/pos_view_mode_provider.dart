import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum PosProductViewMode { grid, list }

class PosViewModeNotifier extends StateNotifier<PosProductViewMode> {
  PosViewModeNotifier() : super(PosProductViewMode.grid) {
    _load();
  }

  static const _prefKey = 'pos_product_view_mode';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == PosProductViewMode.list.name) {
      state = PosProductViewMode.list;
    } else {
      state = PosProductViewMode.grid;
    }
  }

  Future<void> setMode(PosProductViewMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, mode.name);
  }

  Future<void> toggle() async {
    final next = state == PosProductViewMode.grid
        ? PosProductViewMode.list
        : PosProductViewMode.grid;
    await setMode(next);
  }
}

final posViewModeProvider =
    StateNotifierProvider<PosViewModeNotifier, PosProductViewMode>(
  (ref) => PosViewModeNotifier(),
);
