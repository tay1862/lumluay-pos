import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kThemeModeKey = 'app_theme_mode';

enum AppThemeMode { system, light, dark }

/// Notifier that persists the theme choice in SharedPreferences.
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  ThemeNotifier() : super(AppThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_kThemeModeKey);
    if (stored != null) {
      final mode = AppThemeMode.values.firstWhere(
        (m) => m.name == stored,
        orElse: () => AppThemeMode.system,
      );
      state = mode;
    }
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kThemeModeKey, mode.name);
  }
}

// ──────────────────────────────────────────────────────────────────────────────

final themeNotifierProvider =
    StateNotifierProvider<ThemeNotifier, AppThemeMode>(
  (_) => ThemeNotifier(),
);

/// Maps [AppThemeMode] to Flutter's [ThemeMode].
final themeModeProvider = Provider<ThemeMode>((ref) {
  switch (ref.watch(themeNotifierProvider)) {
    case AppThemeMode.light:
      return ThemeMode.light;
    case AppThemeMode.dark:
      return ThemeMode.dark;
    case AppThemeMode.system:
      return ThemeMode.system;
  }
});
