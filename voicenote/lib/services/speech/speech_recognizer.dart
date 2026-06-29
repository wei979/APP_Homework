import '../../models/transcript_segment.dart';

/// 即時辨識的單筆結果。
class SpeechResult {
  /// 目前累積的文字（partial 會持續增長，final 為該句定稿）。
  final String text;
  final bool isFinal;
  const SpeechResult(this.text, {this.isFinal = false});
}

/// 語音辨識抽象介面（邏輯層）。
///
/// 把「即時辨識」與「整檔離線辨識」抽象出來，讓 UI 與處理流程
/// 不綁定特定引擎。預設使用 [DemoSpeechRecognizer]（開箱即跑）；
/// 正式環境可換成 Vosk 等離線引擎（見 [VoskSpeechRecognizer]）。
abstract class SpeechRecognizer {
  Future<void> initialize();

  /// 錄音中的即時辨識結果串流。
  Stream<SpeechResult> get liveResults;

  Future<void> startLive();
  Future<void> pauseLive();
  Future<void> resumeLive();
  Future<void> stopLive();

  /// 對整段錄音做離線辨識，輸出含時間戳的段落（章節切分 / 摘要的輸入）。
  Future<List<TranscriptSegment>> transcribeFile(
    String audioPath, {
    int? totalDurationMs,
  });

  Future<void> dispose();
}