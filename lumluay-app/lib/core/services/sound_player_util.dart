import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppSound {
  newOrder,
  kitchenReady,
  notification,
}

class SoundPlayerUtil {
  SoundPlayerUtil() {
    _loadMute();
  }

  static const _muteKey = 'sound_muted';
  final AudioPlayer _player = AudioPlayer();
  bool _muted = false;

  bool get isMuted => _muted;

  Future<void> _loadMute() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_muteKey) ?? false;
  }

  Future<void> setMuted(bool value) async {
    _muted = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_muteKey, value);
  }

  Future<void> play(AppSound sound) async {
    if (_muted) return;

    final assetPath = switch (sound) {
      AppSound.newOrder => 'sounds/new_order.mp3',
      AppSound.kitchenReady => 'sounds/kitchen_ready.mp3',
      AppSound.notification => 'sounds/notification.mp3',
    };

    try {
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      await SystemSound.play(SystemSoundType.alert);
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}

final soundPlayerProvider = Provider<SoundPlayerUtil>((ref) {
  final player = SoundPlayerUtil();
  ref.onDispose(() {
    player.dispose();
  });
  return player;
});
