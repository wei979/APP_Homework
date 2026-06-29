import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/note.dart';
import '../../utils/duration_format.dart';

/// 將筆記匯出為 Markdown 並分享（查證與分享）。
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

  Future<File> writeToFile(Note note) async {
    final dir = await getTemporaryDirectory();
    final safe = note.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
    final file = File(p.join(dir.path, '$safe.md'));
    await file.writeAsString(build(note));
    return file;
  }

  Future<void> share(Note note) async {
    final file = await writeToFile(note);
    await Share.shareXFiles([XFile(file.path)], text: note.title);
  }
}