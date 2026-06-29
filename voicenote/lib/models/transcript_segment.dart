/// 語音辨識的單段結果（含時間戳）。
///
/// 由 [SpeechRecognizer] 對整段錄音離線辨識後產出，是「章節切分」與
/// 「TextRank 摘要」的輸入單位。一段約等於一個語句。
class TranscriptSegment {
  final String text;
  final int startMs;
  final int endMs;

  const TranscriptSegment({
    required this.text,
    required this.startMs,
    required this.endMs,
  });

  int get durationMs => endMs - startMs;

  @override
  String toString() => 'TranscriptSegment($startMs-$endMs: $text)';
}