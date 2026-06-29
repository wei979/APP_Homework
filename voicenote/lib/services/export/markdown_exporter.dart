import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/note.dart';
import '../../utils/duration_format.dart';

/// 將筆記匯出為 Markdown（查證與分享）。
///
/// 「匯出」與「分享」是兩種不同行為：
/// - [exportToFile]：把 .md 寫到 App 文件目錄並回傳路徑，**完全離線、不開分享面板**。
/// - [shareFile]：開啟系統分享面板把 .md 檔傳給其他 App。
class MarkdownExporter {
  const MarkdownExporter();

  /// 產生 Markdown 內容。
  String build(Note note) {
    final b = StringBuffer()
      ..writeln('# ${note.title}')
      ..writeln()
      ..writeln('- 錄音時長：${DurationFormat.hms(note.durationMs)}')
      ..writeln('- 章節數：${note.chapterCount}')
      ..writeln('- 重點數：${note.bulletCount}')
      ..writeln();

    for (final c in note.chapters) {
      b
        ..writeln('## [${DurationFormat.hms(c.startMs)}] ${c.title}')
        ..writeln();
      for (final bullet in c.bullets) {
        b.writeln('- \`${DurationFormat.hms(bullet.timestampMs)}\` ${bullet.text}');
      }
      b.writeln();
    }

    b
      ..writeln('---')
      ..writeln('由 VoiceNote 匯出 · 完全離線於本機產生');
    return b.toString();
  }

  String _fileName(Note note) {
    final safe = note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    return '${safe.isEmpty ? 'voicenote' : safe}.md';
  }

  Future<File> _writeTo(Note note, Directory dir) async {
    final file = File(p.join(dir.path, _fileName(note)));
    await file.writeAsString(build(note));
    return file;
  }

  /// 匯出：把 .md 存到 App 文件目錄（離線、不開分享面板），回傳完整路徑。
  Future<String> exportToFile(Note note) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = await _writeTo(note, dir);
    return file.path;
  }

  /// 分享：把 .md 檔透過系統分享面板傳出。
  Future<void> shareFile(Note note) async {
    final dir = await getTemporaryDirectory();
    final file = await _writeTo(note, dir);
    await Share.shareXFiles([XFile(file.path)], text: note.title);
  }
}
