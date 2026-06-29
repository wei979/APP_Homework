import '../models/note.dart';
import 'app_database.dart';
import 'note_dao.dart';
import 'seed_data.dart';

/// 倉儲：業務邏輯只依賴此抽象，不直接碰 SQLite。
class NoteRepository {
  final NoteDao _dao;
  NoteRepository(this._dao);

  /// 建立倉儲並在資料庫為空時注入示範資料。
  static Future<NoteRepository> create() async {
    final db = await AppDatabase.instance.database;
    final repo = NoteRepository(NoteDao(db));
    await repo._seedIfEmpty();
    return repo;
  }

  Future<void> _seedIfEmpty() async {
    if (await _dao.countNotes() > 0) return;
    for (final note in SeedData.notes()) {
      await _dao.insertNote(note);
    }
  }

  Future<List<Note>> getAll() => _dao.getAllNotes();
  Future<Note?> getById(int id) => _dao.getNote(id);
  Future<int> add(Note note) => _dao.insertNote(note);
  Future<void> rename(int id, String title) => _dao.rename(id, title);
  Future<void> setBookmark(int id, bool value) => _dao.setBookmark(id, value);
  Future<void> delete(int id) => _dao.deleteNote(id);
}