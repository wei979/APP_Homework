import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// 資料層：開啟 / 建立 SQLite 資料庫（對應企劃書的 Room Database）。
///
/// 四張資料表：notes / chapters / bullets，時間戳直接內嵌於 chapters
/// 與 bullets，外鍵串接並以 ON DELETE CASCADE 維持一致性。
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;

  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, 'voicenote.db');
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        duration_ms INTEGER NOT NULL,
        audio_path TEXT NOT NULL,
        transcript TEXT,
        bookmarked INTEGER NOT NULL DEFAULT 0
      )
    ''');
    await db.execute('''
      CREATE TABLE chapters (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        note_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        start_ms INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        FOREIGN KEY (note_id) REFERENCES notes (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('''
      CREATE TABLE bullets (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        chapter_id INTEGER NOT NULL,
        text TEXT NOT NULL,
        timestamp_ms INTEGER NOT NULL,
        order_index INTEGER NOT NULL,
        score REAL NOT NULL DEFAULT 0,
        FOREIGN KEY (chapter_id) REFERENCES chapters (id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_chapters_note ON chapters (note_id)');
    await db.execute('CREATE INDEX idx_bullets_chapter ON bullets (chapter_id)');
  }
}