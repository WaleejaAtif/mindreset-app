import 'package:just_audio/just_audio.dart';

class AudioService {
  static final AudioPlayer _player = AudioPlayer();

  static Future<void> play(String fileName) async {
    try {
      await _player.stop();
      await _player.setAsset('assets/audio/$fileName');
      await _player.setLoopMode(LoopMode.off);
      await _player.play();
    } catch (e) {
      print("Audio error: $e");
    }
  }

  static Future<void> stop() async {
    await _player.stop();
  }
}