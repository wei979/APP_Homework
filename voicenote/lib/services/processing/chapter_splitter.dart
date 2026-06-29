import '../../models/transcript_segment.dart';

/// 一個章節的原始辨識段落集合。
class ChapterGroup {
  final int startMs;
  final List<TranscriptSegment> segments;
  const ChapterGroup(this.startMs, this.segments);

  String get text => segments.map((s) => s.text).join(' ');
}

/// 依「停頓時間」自動切分章節。
///
/// 當相鄰段落的間隔 >= [pauseThresholdMs]（預設 3 秒，對應企劃書）時切新章節。
class ChapterSplitter {
  final int pauseThresholdMs;
  const ChapterSplitter({this.pauseThresholdMs = 3000});

  List<ChapterGroup> split(List<TranscriptSegment> segments) {
    if (segments.isEmpty) return const [];

    final groups = <ChapterGroup>[];
    var current = <TranscriptSegment>[segments.first];

    for (var i = 1; i < segments.length; i++) {
      final prev = segments[i - 1];
      final seg = segments[i];
      final gap = seg.startMs - prev.endMs;
      if (gap >= pauseThresholdMs) {
        groups.add(ChapterGroup(current.first.startMs, current));
        current = <TranscriptSegment>[seg];
      } else {
        current.add(seg);
      }
    }
    groups.add(ChapterGroup(current.first.startMs, current));
    return groups;
  }
}