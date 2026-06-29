import 'package:flutter_test/flutter_test.dart';
import 'package:voicenote/models/bullet.dart';
import 'package:voicenote/models/chapter.dart';
import 'package:voicenote/models/note.dart';
import 'package:voicenote/services/export/markdown_exporter.dart';

void main() {
  test('Markdown 含標題、章節、帶時間戳的重點與統計', () {
    final note = Note(
      title: '資料結構 第 3 章',
      createdAt: DateTime(2026, 4, 26, 10, 15),
      durationMs: 3138000, // 52:18
      audioPath: '',
      chapters: [
        Chapter(
          title: '堆疊 Stack 簡介',
          startMs: 0,
          orderIndex: 0,
          bullets: const [
            Bullet(
              text: '後進先出 LIFO 是堆疊最核心的特性',
              timestampMs: 42000, // 00:42
              orderIndex: 0,
            ),
          ],
        ),
      ],
    );

    final md = const MarkdownExporter().build(note);

    expect(md, contains('# 資料結構 第 3 章'));
    expect(md, contains('錄音時長：52:18'));
    expect(md, contains('章節數：1'));
    expect(md, contains('重點數：1'));
    expect(md, contains('## [00:00] 堆疊 Stack 簡介'));
    expect(md, contains('00:42'));
    expect(md, contains('後進先出 LIFO 是堆疊最核心的特性'));
  });
}