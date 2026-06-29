import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../services/audio/audio_recorder_service.dart';
import '../services/speech/speech_recognizer.dart';

enum RecorderState { idle, recording, paused, finished }

/// 一次錄音完成後的結果，交給處理流程。
class RecordingResult {
  final String title;
  final String audioPath;
  final int durationMs;
  const RecordingResult({
    required this.title,
    required this.audioPath,
    required this.durationMs,
  });
}

/// 錄音畫面狀態：計時、波形音量、即時辨識文字、暫停 / 繼續 / 停止。
class RecordingProvider extends ChangeNotifier {
  final AudioRecorderService _recorder;
  final SpeechRecognizer _recognizer;
  RecordingProvider(this._recorder, this._recognizer);

  static const int maxBars = 48;

  bool _disposed = false;

  RecorderState _state = RecorderState.idle;
  RecorderState get state => _state;

  String title = '';

  int _elapsedMs = 0;
  int get elapsedMs => _elapsedMs;

  final List<double> _amplitudes = [];
  List<double> get amplitudes => List.unmodifiable(_amplitudes);

  String _liveText = '';
  String get liveText => _liveText;

  bool _permissionDenied = false;
  bool get permissionDenied => _permissionDenied;

  Timer? _ticker;
  StreamSubscription<double>? _ampSub;
  StreamSubscription<SpeechResult>? _liveSub;
  String? _path;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> start() async {
    if (!await _recorder.hasPermission()) {
      _permissionDenied = true;
      _notify();
      return;
    }
    final dir = await getApplicationDocumentsDirectory();
    _path = p.join(dir.path, 'rec_${DateTime.now().millisecondsSinceEpoch}.wav');
    await _recorder.start(_path!);
    if (_disposed) return;

    _state = RecorderState.recording;
    _elapsedMs = 0;
    _amplitudes.clear();
    _startTicker();
    _listenAmplitude();
    await _recognizer.startLive();
    _listenLive();
    _notify();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _elapsedMs += 100;
      _notify();
    });
  }

  void _listenAmplitude() {
    _ampSub?.cancel();
    _ampSub = _recorder.amplitudeStream().listen((v) {
      _amplitudes.add(v);
      if (_amplitudes.length > maxBars) _amplitudes.removeAt(0);
      _notify();
    });
  }

  void _listenLive() {
    _liveSub?.cancel();
    _liveSub = _recognizer.liveResults.listen((r) {
      _liveText = r.text;
      _notify();
    });
  }

  Future<void> pause() async {
    if (_state != RecorderState.recording) return;
    await _recorder.pause();
    await _recognizer.pauseLive();
    _ticker?.cancel();
    _state = RecorderState.paused;
    _notify();
  }

  Future<void> resume() async {
    if (_state != RecorderState.paused) return;
    await _recorder.resume();
    await _recognizer.resumeLive();
    _startTicker();
    _state = RecorderState.recording;
    _notify();
  }

  Future<RecordingResult> stop() async {
    _ticker?.cancel();
    await _ampSub?.cancel();
    await _liveSub?.cancel();
    await _recognizer.stopLive();
    final path = await _recorder.stop() ?? _path ?? '';
    _state = RecorderState.finished;
    _notify();
    return RecordingResult(
      title: title,
      audioPath: path,
      durationMs: _elapsedMs,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _ticker?.cancel();
    _ampSub?.cancel();
    _liveSub?.cancel();
    unawaited(_recorder.dispose());
    super.dispose();
  }
}