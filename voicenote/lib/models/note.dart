import 'chapter.dart';

/// 一份語音筆記（聚合根）。
///
/// 對應資料層 `notes` 表，並聚合其 [chapters] 與每個章節的重點。
class Note {
  final int? id;
  final String title;
  final DateTime createdAt;
  final int durationMs;
  final String audioPath;
  final String transcript;
  final bool bookmarked;
  final List<Chapter> chapters;

  const Note({
    this.id,
    required this.title,
    required this.createdAt,
    required this.durationMs,
    required this.audioPath,
    this.transcript = '',
    this.bookmarked = false,
    this.chapters = const [],
  });

  int get chapterCount => chapters.length;

  int get bulletCount =>
      chapters.fold(0, (sum, c) => sum + c.bullets.length);

  Note copyWith({
    int? id,
    String? title,
    bool? bookmarked,
    List<Chapter>? chapters,
  }) =>
      Note(
        id: id ?? this.id,
        title: title ?? this.title,
        createdAt: createdAt,
        durationMs: durationMs,
        audioPath: audioPath,
        transcript: transcript,
        bookmarked: bookmarked ?? this.bookmarked,
        chapters: chapters ?? this.chapters,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'title': title,
        'created_at': createdAt.millisecondsSinceEpoch,
        'duration_ms': durationMs,
        'audio_path': audioPath,
        'transcript': transcript,
        'bookmarked': bookmarked ? 1 : 0,
      };

  factory Note.fromMap(Map<String, Object?> m, {List<Chapter> chapters = const []}) =>
      Note(
        id: m['id'] as int?,
        title: m['title'] as String,
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['created_at'] as int),
        durationMs: m['duration_ms'] as int,
        audioPath: m['audio_path'] as String,
        transcript: (m['transcript'] as String?) ?? '',
        bookmarked: (m['bookmarked'] as int? ?? 0) == 1,
        chapters: chapters,
      );
}