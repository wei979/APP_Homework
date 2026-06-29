import '../../models/transcript_segment.dart';

/// 即時辨識的單筆結果。
class SpeechResult {
  final String text;
  final bool isFinal;
  const SpeechResult(this.text, {this.isFinal = false});
}

/// 語音辨識抽象介面（邏輯層）。
abstract class SpeechRecognizer {
  Future<void> initialize();

  /// 錄音中的即時辨識結果串流。
  Stream<SpeechResult> get liveResults;

  /// 模型下載 / 解壓 / 載入的人類可讀狀態（如「下載辨識模型 45%」）；
  /// 無此需求的實作回傳 null。
  Stream<String>? get setupStatus;

  Future<void> startLive();
  Future<void> pauseLive();
  Future<void> resumeLive();
  Future<void> stopLive();

  /// 對整段錄音做離線辨識，輸出含時間戳的段落。
  Future<List<TranscriptSegment>> transcribeFile(
    String audioPath, {
    int? totalDurationMs,
  });

  Future<void> dispose();
}