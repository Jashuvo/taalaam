import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final _player = AudioPlayer();

  Future<void> playUrl(String url) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      await _player.seek(Duration.zero);
      await _player.setFilePath(file.path);
      await _player.play();
    } catch (_) {
      // Audio is supplementary — silent fail
    }
  }

  Future<void> stop() async {
    try {
      await _player.stop();
    } catch (_) {}
  }

  void dispose() => _player.dispose();
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
