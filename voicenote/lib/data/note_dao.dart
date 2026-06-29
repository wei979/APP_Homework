import 'package:sqflite/sqflite.dart';

import '../models/bullet.dart';
import '../models/chapter.dart';
import '../models/note.dart';

/// 資料存取物件：封裝 notes / chapters / bullets 的讀寫。
class NoteDao {
  final Database db;
  NoteDao(this.db);

  Future<int> countNotes() async {
    final v = Sqflite.firstIntValue(
      await db.rawQuery('SELECT COUNT(*) FROM notes'),
    );
    return v ?? 0;
  }

  /// 以單一交易寫入整份筆記（note + 章節 + 重點）。
  Future<int> insertNote(Note note) async {
    return db.transaction((txn) async {
      final noteId = await txn.insert('notes', note.toMap());
      for (final c in note.chapters) {
        final chapterId =
            await txn.insert('chapters', c.copyWith(noteId: noteId).toMap());
        for (final bullet in c.bullets) {
          await txn.insert('bullets', bullet.copyWith(chapterId: chapterId).toMap());
        }
      }
      return noteId;
    });
  }

  Future<List<Note>> getAllNotes() async {
    final rows = await db.query('notes', orderBy: 'created_at DESC');
    return [for (final r in rows) await _hydrate(r)];
  }

  Future<Note?> getNote(int id) async {
    final rows =
        await db.query('notes', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) return null;
    return _hydrate(rows.first);
  }

  Future<Note> _hydrate(Map<String, Object?> noteRow) async {
    final noteId = noteRow['id'] as int;
    final chapterRows = await db.query(
      'chapters',
      where: 'note_id = ?',
      whereArgs: [noteId],
      orderBy: 'order_index ASC',
    );
    final chapters = <Chapter>[];
    for (final cr in chapterRows) {
      final bulletRows = await db.query(
        'bullets',
        where: 'chapter_id = ?',
        whereArgs: [cr['id']],
        orderBy: 'order_index ASC',
      );
      chapters.add(
        Chapter.fromMap(cr, bullets: bulletRows.map(Bullet.fromMap).toList()),
      );
    }
    return Note.fromMap(noteRow, chapters: chapters);
  }

  Future<void> rename(int id, String title) => db.update(
        'notes',
        {'title': title},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> setBookmark(int id, bool value) => db.update(
        'notes',
        {'bookmarked': value ? 1 : 0},
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<void> deleteNote(int id) =>
      db.delete('notes', where: 'id = ?', whereArgs: [id]);
}