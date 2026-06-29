import '../../models/bullet.dart';
import '../../models/chapter.dart';
import '../../models/note.dart';
import '../../models/transcript_segment.dart';
import 'chapter_splitter.dart';
import 'keyword_extractor.dart';
import 'text_rank_summarizer.dart';

/// 處理流程階段（驅動「處理中」畫面的進度列）。
enum ProcessingStage { savingAudio, recognizing, summarizing, generating, done }

/// 邏輯層核心：把離線辨識結果整理成一份結構化的 [Note]。
///
/// 純運算、不做任何 IO，方便單元測試。
class NoteProcessor {
  final ChapterSplitter splitter;
  final TextRankSummarizer summarizer;
  final KeywordExtractor keywords;

  const NoteProcessor({
    this.splitter = const ChapterSplitter(),
    this.summarizer = const TextRankSummarizer(),
    this.keywords = const KeywordExtractor(),
  });

  Note buildNote({
    required String title,
    required String audioPath,
    required int durationMs,
    required List<TranscriptSegment> segments,
    DateTime? createdAt,
  }) {
    final groups = splitter.split(segments);
    final chapters = <Chapter>[];

    for (var ci = 0; ci < groups.length; ci++) {
      final group = groups[ci];
      final sentences = group.segments.map((s) => s.text).toList();
      final picked = summarizer.summarizeIndices(sentences);

      final bullets = <Bullet>[
        for (var bi = 0; bi < picked.length; bi++)
          Bullet(
            text: sentences[picked[bi]],
            timestampMs: group.segments[picked[bi]].startMs,
            orderIndex: bi,
          ),
      ];

      chapters.add(
        Chapter(
          title: keywords.title(group.text, fallbackIndex: ci),
          startMs: group.startMs,
          orderIndex: ci,
          bullets: bullets,
        ),
      );
    }

    final cleanTitle = title.trim();
    return Note(
      title: cleanTitle.isEmpty ? '未命名錄音' : cleanTitle,
      createdAt: createdAt ?? DateTime.now(),
      durationMs: durationMs,
      audioPath: audioPath,
      transcript: segments.map((s) => s.text).join('\n'),
      chapters: chapters,
    );
  }
}