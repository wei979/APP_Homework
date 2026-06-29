/// 重點樹狀圖（心智圖）的節點。階層：主題 → 子主題 → 重點。
class MindNode {
  final String title;
  final int? startMs; // 對應錄音時間點（可選）
  final List<MindNode> children;

  const MindNode({required this.title, this.startMs, this.children = const []});

  factory MindNode.fromJson(Map<String, dynamic> j) => MindNode(
        title: (j['title'] as String? ?? '').trim(),
        startMs: (j['startMs'] as num?)?.toInt(),
        children: ((j['children'] as List?) ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(MindNode.fromJson)
            .where((n) => n.title.isNotEmpty)
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        if (startMs != null) 'startMs': startMs,
        if (children.isNotEmpty)
          'children': children.map((c) => c.toJson()).toList(),
      };
}