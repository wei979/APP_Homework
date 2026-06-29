import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../models/mind_node.dart';
import '../../models/note.dart';
import '../../utils/duration_format.dart';
import 'gemini_client.dart';

/// 語意邏輯分析：把筆記整理成階層式重點樹狀圖（雲端 LLM：Gemini）。
///
/// ⚠️ 此功能需連網、會將逐字稿上傳至 Google Gemini，與「完全離線」的辨識分開。
class MindMapService {
  const MindMapService();

  /// 固定深度（≤4 層）非遞迴 schema（Gemini responseSchema 格式：型別大寫）。
  static final Map<String, dynamic> _schema = () {
    Map<String, dynamic> node(Map<String, dynamic>? childItems) => {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'startMs': {'type': 'INTEGER'},
            if (childItems != null)
              'children': {'type': 'ARRAY', 'items': childItems},
          },
          'required': ['title'],
          'propertyOrdering': [
            'title',
            'startMs',
            if (childItems != null) 'children',
          ],
        };
    final leaf = node(null);
    final l3 = node(leaf);
    final l2 = node(l3);
    return {
      'type': 'OBJECT',
      'properties': {
        'title': {'type': 'STRING'},
        'children': {'type': 'ARRAY', 'items': l2},
      },
      'required': ['title', 'children'],
      'propertyOrdering': ['title', 'children'],
    };
  }();

  static const String _system =
      '你是專業的課程筆記整理助手。將輸入的章節重點與逐字稿做語意邏輯分析，'
      '整理成階層式的「重點樹狀圖」：根節點為課程主題，往下是主題 → 子主題 → 重點，'
      '最多 4 層。使用繁體中文、精煉的短語當節點標題。'
      '每個節點盡量附上對應的錄音時間點 startMs（毫秒、整數），數值取自輸入提供的 startMs。'
      '只輸出符合 schema 的 JSON。';

  Future<File> _cacheFile(int noteId) async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'mindmap_$noteId.json'));
  }

  Future<MindNode?> loadCached(int noteId) async {
    final f = await _cacheFile(noteId);
    if (!await f.exists()) return null;
    try {
      final j = jsonDecode(await f.readAsString()) as Map<String, dynamic>;
      return MindNode.fromJson(j);
    } catch (_) {
      return null;
    }
  }

  Future<MindNode> generate(Note note, {required String apiKey}) async {
    final client = GeminiClient(apiKey);
    final text = await client.structuredJson(
      system: _system,
      userContent: _serialize(note),
      responseSchema: _schema,
    );
    final json = jsonDecode(text) as Map<String, dynamic>;
    final tree = MindNode.fromJson(json);
    if (note.id != null) {
      try {
        await (await _cacheFile(note.id!))
            .writeAsString(jsonEncode(tree.toJson()));
      } catch (_) {}
    }
    return tree;
  }

  String _serialize(Note note) {
    final b = StringBuffer()
      ..writeln('課程名稱：${note.title}')
      ..writeln();
    for (final c in note.chapters) {
      b.writeln('## 章節（startMs=${c.startMs}）：${c.title}');
      for (final bullet in c.bullets) {
        b.writeln('- (startMs=${bullet.timestampMs}) ${bullet.text}');
      }
    }
    final transcript = note.transcript.trim();
    if (transcript.isNotEmpty) {
      b
        ..writeln()
        ..writeln('逐字稿：')
        ..writeln(transcript);
    }
    b
      ..writeln()
      ..writeln('（時長 ${DurationFormat.hms(note.durationMs)}）請整理成重點樹狀圖。');
    return b.toString();
  }
}