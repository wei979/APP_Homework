import '../models/bullet.dart';
import '../models/chapter.dart';
import '../models/note.dart';

/// 示範資料：對應設計稿的筆記列表與「資料結構 第 3 章」詳情。
///
/// 讓 App 首次啟動即可呈現完整畫面（資料庫為空時由倉儲注入）。
class SeedData {
  SeedData._();

  /// `mm:ss` → 毫秒。
  static int _ms(String mmss) {
    final parts = mmss.split(':').map(int.parse).toList();
    return (parts[0] * 60 + parts[1]) * 1000;
  }

  static Bullet _b(String ts, String text, int order) =>
      Bullet(text: text, timestampMs: _ms(ts), orderIndex: order);

  static List<Note> notes() {
    final now = DateTime.now();
    final today1015 = DateTime(now.year, now.month, now.day, 10, 15);

    return [
      _dataStructureNote(today1015),
      _simpleNote(
        title: '作業系統 行程排程',
        createdAt: now.subtract(const Duration(days: 1)),
        duration: '48:42',
        chapterTitles: ['排程目標與名詞', 'FCFS 與 SJF', '優先權與 RR', 'MLFQ 多層回饋'],
      ),
      _simpleNote(
        title: '計算機網路 TCP 三次交握',
        createdAt: DateTime(now.year, 4, 22, 14, 0),
        duration: '1:02:30',
        chapterTitles: [
          'TCP 與 UDP 比較',
          '三次交握流程',
          'SYN 與 ACK 旗標',
          '四次揮手',
          '流量控制',
          '壅塞控制',
          '重送機制',
        ],
      ),
      _simpleNote(
        title: '線性代數 特徵值與特徵向量',
        createdAt: DateTime(now.year, 4, 19, 9, 30),
        duration: '45:12',
        chapterTitles: ['特徵值定義', '特徵多項式', '對角化'],
      ),
      _simpleNote(
        title: '機器學習 期中複習',
        createdAt: DateTime(now.year, 4, 15, 16, 20),
        duration: '38:55',
        chapterTitles: ['監督式學習', '損失函數', '梯度下降', '過擬合與正則化'],
      ),
    ];
  }

  /// 主筆記：5 章節 / 18 條重點，第一章內容 1:1 對應設計稿。
  static Note _dataStructureNote(DateTime createdAt) {
    final chapters = <Chapter>[
      Chapter(
        title: '堆疊 Stack 簡介',
        startMs: _ms('00:00'),
        orderIndex: 0,
        bullets: [
          _b('00:42', '後進先出 LIFO 是堆疊最核心的特性', 0),
          _b('02:18', '主要操作為 push 與 pop，皆為 O(1)', 1),
          _b('04:05', '常見應用：函式呼叫、運算式求值、回溯', 2),
        ],
      ),
      Chapter(
        title: '陣列實作堆疊',
        startMs: _ms('10:24'),
        orderIndex: 1,
        bullets: [
          _b('11:05', '以一個 top 指標記錄堆疊頂端位置', 0),
          _b('13:20', 'push 時 top 加一寫入，pop 時讀出並 top 減一', 1),
          _b('15:40', '容量固定，滿了需重新配置更大的陣列', 2),
        ],
      ),
      Chapter(
        title: '鏈結串列實作',
        startMs: _ms('22:50'),
        orderIndex: 2,
        bullets: [
          _b('23:30', '以鏈結串列開頭作為堆疊頂端可動態增長', 0),
          _b('26:10', 'push 在開頭插入節點，pop 移除開頭節點', 1),
          _b('28:55', '不需預先配置容量，但有指標的記憶體開銷', 2),
          _b('31:12', '適合大小變動劇烈或未知的情境', 3),
        ],
      ),
      Chapter(
        title: '佇列 Queue 比較',
        startMs: _ms('35:12'),
        orderIndex: 3,
        bullets: [
          _b('35:50', '佇列是先進先出 FIFO，與堆疊相反', 0),
          _b('38:00', '操作為 enqueue 與 dequeue', 1),
          _b('41:20', '常用於排程與廣度優先搜尋 BFS', 2),
          _b('44:05', '可用環狀陣列避免搬移成本', 3),
        ],
      ),
      Chapter(
        title: '應用與總結',
        startMs: _ms('46:30'),
        orderIndex: 4,
        bullets: [
          _b('47:10', '堆疊與佇列都是基礎線性結構', 0),
          _b('49:00', '差別在資料進出的順序 LIFO 對 FIFO', 1),
          _b('51:00', '選擇結構取決於存取順序需求', 2),
          _b('52:00', '下次將介紹樹與圖等非線性結構', 3),
        ],
      ),
    ];

    return Note(
      title: '資料結構 第 3 章',
      createdAt: createdAt,
      durationMs: _ms('52:18'),
      audioPath: '',
      transcript: '',
      chapters: chapters,
    );
  }

  static Note _simpleNote({
    required String title,
    required DateTime createdAt,
    required String duration,
    required List<String> chapterTitles,
  }) {
    final chapters = <Chapter>[];
    final total = _ms(duration);
    final step = total ~/ (chapterTitles.length + 1);
    for (var i = 0; i < chapterTitles.length; i++) {
      final start = step * (i + 1);
      chapters.add(
        Chapter(
          title: chapterTitles[i],
          startMs: start,
          orderIndex: i,
          bullets: [
            Bullet(
              text: '${chapterTitles[i]}的重點摘要',
              timestampMs: start + 30000,
              orderIndex: 0,
            ),
            Bullet(
              text: '${chapterTitles[i]}的延伸說明與範例',
              timestampMs: start + 90000,
              orderIndex: 1,
            ),
          ],
        ),
      );
    }
    return Note(
      title: title,
      createdAt: createdAt,
      durationMs: total,
      audioPath: '',
      chapters: chapters,
    );
  }
}