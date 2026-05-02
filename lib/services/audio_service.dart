import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Stream<bool> get playingStream => _player.playingStream;
  static Stream<Duration> get positionStream => _player.positionStream;
  static Stream<Duration?> get durationStream => _player.durationStream;
  static Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  static bool get isPlaying => _player.playing;

  static Future<void> play(String assetPath, {bool loop = true}) async {
    try {
      await _player.stop();
      await _player.setAsset(_normalizeAssetPath(assetPath));
      await _player.setLoopMode(loop ? LoopMode.one : LoopMode.off);
      await _player.play();
    } catch (e) {
      debugPrint('Audio error: $e');
      rethrow;
    }
  }

  static Future<void> pause() => _player.pause();

  static Future<void> resume() => _player.play();

  static Future<void> seek(Duration position) => _player.seek(position);

  static Future<void> setVolume(double volume) {
    return _player.setVolume(volume.clamp(0.0, 1.0).toDouble());
  }

  static Future<void> stop() async {
    await _player.stop();
  }

  static String _normalizeAssetPath(String assetPath) {
    if (assetPath.startsWith('assets/')) {
      return assetPath;
    }
    return 'assets/audio/$assetPath';
  }
}

