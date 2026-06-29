import 'package:flutter_test/flutter_test.dart';
import 'package:voicenote/models/transcript_segment.dart';
import 'package:voicenote/services/processing/chapter_splitter.dart';

void main() {
  const splitter = ChapterSplitter(pauseThresholdMs: 3000);

  group('ChapterSplitter', () {
    test('空輸入回傳空', () {
      expect(splitter.split([]), isEmpty);
    });

    test('間隔小於門檻 → 單一章節', () {
      final segments = [
        const TranscriptSegment(text: 'a', startMs: 0, endMs: 1000),
        const TranscriptSegment(text: 'b', startMs: 1200, endMs: 2000),
      ];
      final groups = splitter.split(segments);
      expect(groups.length, 1);
      expect(groups.first.segments.length, 2);
    });

    test('間隔 >= 門檻 → 切出新章節', () {
      final segments = [
        const TranscriptSegment(text: 'a', startMs: 0, endMs: 1000),
        const TranscriptSegment(text: 'b', startMs: 4500, endMs: 5000),
      ];
      final groups = splitter.split(segments);
      expect(groups.length, 2);
      expect(groups[1].startMs, 4500);
    });
  });
}