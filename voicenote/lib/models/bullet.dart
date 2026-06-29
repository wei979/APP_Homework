/// 章節重點（TextRank 摘要挑出的關鍵句）。
///
/// [timestampMs] 為該重點對應的原始錄音時間點，點擊可跳轉播放。
class Bullet {
  final int? id;
  final int? chapterId;
  final String text;
  final int timestampMs;
  final int orderIndex;
  final double score;

  const Bullet({
    this.id,
    this.chapterId,
    required this.text,
    required this.timestampMs,
    required this.orderIndex,
    this.score = 0,
  });

  Bullet copyWith({int? id, int? chapterId}) => Bullet(
        id: id ?? this.id,
        chapterId: chapterId ?? this.chapterId,
        text: text,
        timestampMs: timestampMs,
        orderIndex: orderIndex,
        score: score,
      );

  Map<String, Object?> toMap() => {
        if (id != null) 'id': id,
        'chapter_id': chapterId,
        'text': text,
        'timestamp_ms': timestampMs,
        'order_index': orderIndex,
        'score': score,
      };

  factory Bullet.fromMap(Map<String, Object?> m) => Bullet(
        id: m['id'] as int?,
        chapterId: m['chapter_id'] as int?,
        text: m['text'] as String,
        timestampMs: m['timestamp_ms'] as int,
        orderIndex: m['order_index'] as int,
        score: (m['score'] as num?)?.toDouble() ?? 0,
      );
}