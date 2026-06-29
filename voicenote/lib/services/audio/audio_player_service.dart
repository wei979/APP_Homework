import 'package:just_audio/just_audio.dart';

/// 錄音播放（邏輯層）。封裝 `just_audio`，支援依時間戳跳轉。
class AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  AudioPlayer get raw => _player;

  Stream<Duration> get positionStream => _player.positionStream;
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Duration? get duration => _player.duration;
  bool get isPlaying => _player.playing;

  /// 載入音檔，回傳其長度（失敗回傳 null，例如示範資料無真實檔案）。
  Future<Duration?> setFile(String path) async {
    try {
      return await _player.setFilePath(path);
    } catch (_) {
      return null;
    }
  }

  Future<void> play() => _player.play();
  Future<void> pause() => _player.pause();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> dispose() => _player.dispose();
}