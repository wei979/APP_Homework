import 'bullet.dart';

/// 自動切分的章節。
///
/// 標題由該段最常出現的關鍵字組成，[startMs] 為章節在錄音中的起點。
class Chapter {
  final int? id;
  final int? noteId;
  final String title;
  final int startMs;
  final int orderIndex;
  final List<Bullet> bullets;

  const Chapter({
    this.id,
    this.noteId,
    required this.title,
    required this.startMs,
    required this.orderIndex,
    this.bullets = const [],
  });

  Chapter copyWith({int? id, int? noteId, List<Bullet>? bullets}) => Chapter(
        id: id ?? this.id,
        noteId: noteId ?? this.noteId,
        title: title,
        startMs: startMs,
        orderIndex: orderIndex,
        bullets: bullets ?? this.bullets,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'note_id': noteId,
        'title': title,
        'start_ms': startMs,
        'order_index': orderIndex,
      };

  factory Chapter.fromMap(Map<String, Object?> m, {List<Bullet> bullets = const []}) =>
      Chapter(
        id: m['id'] as int?,
        noteId: m['note_id'] as int?,
        title: m['title'] as String,
        startMs: m['start_ms'] as int,
        orderIndex: m['order_index'] as int,
        bullets: bullets,
      );
}