import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

class AudioService {
  final _player = AudioPlayer();
  String? _currentUrl;

  /// The URL most recently loaded via [playUrl], or null if none/stopped.
  String? get currentUrl => _currentUrl;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Duration? get duration => _player.duration;
  bool get playing => _player.playing;

  Future<void> playUrl(String url) async {
    try {
      final file = await DefaultCacheManager().getSingleFile(url);
      await _player.seek(Duration.zero);
      await _player.setFilePath(file.path);
      _currentUrl = url;
      await _player.play();
    } catch (_) {
      // Audio is supplementary — silent fail
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
    } catch (_) {}
  }

  Future<void> resume() async {
    try {
      await _player.play();
    } catch (_) {}
  }

  Future<void> stop() async {
    try {
      await _player.stop();
      _currentUrl = null;
    } catch (_) {}
  }

  void dispose() => _player.dispose();
}

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});
