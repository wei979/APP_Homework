import 'package:flutter_test/flutter_test.dart';
import 'package:voicenote/models/transcript_segment.dart';
import 'package:voicenote/services/processing/note_processor.dart';

void main() {
  const processor = NoteProcessor();

  group('NoteProcessor.buildNote', () {
    test('依停頓切章節，重點來自原始段落時間戳', () {
      final segments = <TranscriptSegment>[
        const TranscriptSegment(
            text: '堆疊是後進先出 LIFO 的線性結構', startMs: 0, endMs: 2000),
        const TranscriptSegment(
            text: '堆疊操作有 push 與 pop', startMs: 2300, endMs: 4000),
        const TranscriptSegment(
            text: '堆疊常用於函式呼叫與回溯', startMs: 4300, endMs: 6000),
        // 間隔 4000ms > 3 秒 → 新章節
        const TranscriptSegment(
            text: '佇列是先進先出 FIFO', startMs: 10000, endMs: 12000),
        const TranscriptSegment(
            text: '佇列操作有 enqueue 與 dequeue', startMs: 12300, endMs: 14000),
        const TranscriptSegment(
            text: '佇列常用於排程與 BFS', startMs: 14300, endMs: 16000),
      ];

      final note = processor.buildNote(
        title: '測試課程',
        audioPath: 'a.wav',
        durationMs: 16000,
        segments: segments,
      );

      expect(note.chapters.length, 2);
      for (final c in note.chapters) {
        expect(c.bullets, isNotEmpty);
        expect(c.bullets.length, inInclusiveRange(1, 5));
      }
      final allTs = {0, 2300, 4300, 10000, 12300, 14300};
      for (final c in note.chapters) {
        for (final b in c.bullets) {
          expect(allTs.contains(b.timestampMs), isTrue);
        }
      }
    });

    test('空標題 → 未命名錄音；空輸入 → 無章節', () {
      final note = processor.buildNote(
        title: '   ',
        audioPath: '',
        durationMs: 0,
        segments: const [],
      );
      expect(note.title, '未命名錄音');
      expect(note.chapters, isEmpty);
      expect(note.bulletCount, 0);
    });
  });
}