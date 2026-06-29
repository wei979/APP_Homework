import '../../models/transcript_segment.dart';
import 'speech_recognizer.dart';

/// 真實離線辨識器的接線骨架（Vosk）。
///
/// 預設未啟用：本專案開箱使用 [DemoSpeechRecognizer]，避免綁定數百 MB 模型。
/// 啟用步驟：
///   1. 於 `pubspec.yaml` 加入 `vosk_flutter: ^x.y.z`。
///   2. 下載繁體中文模型（如 vosk-model-small-cn）放入 assets 或 App 私有目錄。
///   3. 解開下方註解，依 vosk_flutter API 完成 initialize / transcribeFile。
///   4. 在 `main.dart` 把注入的 SpeechRecognizer 換成本類別。
///
/// 介面與 Demo 版完全一致，上層 UI / 處理流程不需改動。
class VoskSpeechRecognizer implements SpeechRecognizer {
  final String modelPath;
  final int sampleRate;

  VoskSpeechRecognizer({required this.modelPath, this.sampleRate = 16000});

  static const String _notEnabled =
      'VoskSpeechRecognizer 尚未啟用：請依檔頭說明加入 vosk_flutter 並載入模型，'
      '或改用 DemoSpeechRecognizer。';

  @override
  Future<void> initialize() async {
    // final vosk = VoskFlutterPlugin.instance();
    // final model = await vosk.createModel(modelPath);
    // _recognizer = await vosk.createRecognizer(model: model, sampleRate: sampleRate);
    throw UnsupportedError(_notEnabled);
  }

  @override
  Stream<SpeechResult> get liveResults =>
      Stream<SpeechResult>.error(UnsupportedError(_notEnabled));

  @override
  Future<void> startLive() async => throw UnsupportedError(_notEnabled);

  @override
  Future<void> pauseLive() async => throw UnsupportedError(_notEnabled);

  @override
  Future<void> resumeLive() async => throw UnsupportedError(_notEnabled);

  @override
  Future<void> stopLive() async => throw UnsupportedError(_notEnabled);

  @override
  Future<List<TranscriptSegment>> transcribeFile(
    String audioPath, {
    int? totalDurationMs,
  }) async {
    // 讀取 WAV PCM → 餵入 recognizer → 解析含 word 時間戳的 JSON →
    // 聚合成 TranscriptSegment 清單。
    throw UnsupportedError(_notEnabled);
  }

  @override
  Future<void> dispose() async {}
}