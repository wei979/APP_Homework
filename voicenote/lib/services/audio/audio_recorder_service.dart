import 'package:record/record.dart';

/// 錄音控制（邏輯層）。封裝 `record` 套件，輸出 16kHz 單聲道 WAV，
/// 並提供正規化（0~1）的音量串流給波形視覺化使用。
class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<bool> isRecording() => _recorder.isRecording();

  /// 音量串流，已將 dBFS 正規化為 0(安靜)~1(大聲)。
  Stream<double> amplitudeStream({
    Duration interval = const Duration(milliseconds: 120),
  }) {
    const minDb = -45.0;
    return _recorder.onAmplitudeChanged(interval).map((a) {
      final db = a.current.isFinite ? a.current : minDb;
      return ((db - minDb) / (0 - minDb)).clamp(0.0, 1.0);
    });
  }

  Future<void> start(String path) {
    return _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
  }

  Future<void> pause() => _recorder.pause();

  Future<void> resume() => _recorder.resume();

  /// 結束錄音，回傳檔案路徑。
  Future<String?> stop() => _recorder.stop();

  Future<void> dispose() => _recorder.dispose();
}