import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import '../services/audio/audio_player_service.dart';

/// 筆記詳情頁的播放器狀態。
///
/// 有真實音檔時用 just_audio 播放；示範資料無音檔時退回「虛擬時間軸」，
/// 仍可示範跳轉與進度，確保任何筆記都能 demo。
class PlayerProvider extends ChangeNotifier {
  final AudioPlayerService _player = AudioPlayerService();
  final int fallbackDurationMs;

  PlayerProvider({required this.fallbackDurationMs, required String audioPath}) {
    _init(audioPath);
  }

  bool _disposed = false;
  bool _hasAudio = false;
  bool get hasAudio => _hasAudio;

  bool _playing = false;
  bool get isPlaying => _playing;

  int _positionMs = 0;
  int get positionMs => _positionMs;

  int _durationMs = 0;
  int get durationMs => _durationMs == 0 ? fallbackDurationMs : _durationMs;

  StreamSubscription<Duration>? _posSub;
  StreamSubscription<PlayerState>? _stateSub;
  Timer? _virtualTimer;

  /// 僅在尚未 dispose 時通知，避免 await 後對已釋放的 notifier 呼叫。
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> _init(String path) async {
    if (path.isNotEmpty) {
      final d = await _player.setFile(path);
      if (_disposed) return;
      if (d != null) {
        _hasAudio = true;
        _durationMs = d.inMilliseconds;
        _posSub = _player.positionStream.listen((pos) {
          _positionMs = pos.inMilliseconds;
          _notify();
        });
        _stateSub = _player.playerStateStream.listen((st) {
          _playing = st.playing;
          if (st.processingState == ProcessingState.completed) {
            _playing = false;
            unawaited(_player.pause());
            unawaited(_player.seek(Duration.zero));
          }
          _notify();
        });
      }
    }
    _notify();
  }

  Future<void> togglePlay() async {
    if (_hasAudio) {
      if (_player.isPlaying) {
        await _player.pause();
      } else {
        await _player.play();
      }
    } else {
      _playing ? _stopVirtual() : _startVirtual();
    }
    _notify();
  }

  void _startVirtual() {
    _playing = true;
    _virtualTimer?.cancel();
    _virtualTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      _positionMs += 200;
      if (_positionMs >= durationMs) {
        _positionMs = durationMs;
        _stopVirtual();
      }
      _notify();
    });
  }

  void _stopVirtual() {
    _playing = false;
    _virtualTimer?.cancel();
    _notify();
  }

  Future<void> seekTo(int ms) async {
    final clamped = ms.clamp(0, durationMs);
    _positionMs = clamped;
    if (_hasAudio) await _player.seek(Duration(milliseconds: clamped));
    _notify();
  }

  /// 點重點 → 跳轉到時間戳並開始播放。
  Future<void> jumpAndPlay(int ms) async {
    await seekTo(ms);
    if (_hasAudio) {
      await _player.play();
    } else if (!_playing) {
      _startVirtual();
    }
    _notify();
  }

  Future<void> skip(int deltaMs) => seekTo(_positionMs + deltaMs);

  @override
  void dispose() {
    _disposed = true;
    _posSub?.cancel();
    _stateSub?.cancel();
    _virtualTimer?.cancel();
    unawaited(_player.dispose());
    super.dispose();
  }
}