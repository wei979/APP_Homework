import 'package:flutter/foundation.dart';

import '../data/note_repository.dart';
import '../models/note.dart';

/// 筆記列表狀態：載入、搜尋、重新命名、刪除、書籤。
class NoteListProvider extends ChangeNotifier {
  final NoteRepository _repo;
  NoteListProvider(this._repo) {
    load();
  }

  bool _loading = true;
  bool get loading => _loading;

  List<Note> _all = [];
  String _query = '';
  String get query => _query;

  List<Note> get notes {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _all;
    return _all.where((n) => _matches(n, q)).toList();
  }

  bool _matches(Note n, String q) {
    if (n.title.toLowerCase().contains(q)) return true;
    for (final c in n.chapters) {
      if (c.title.toLowerCase().contains(q)) return true;
      for (final b in c.bullets) {
        if (b.text.toLowerCase().contains(q)) return true;
      }
    }
    return false;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _all = await _repo.getAll();
    _loading = false;
    notifyListeners();
  }

  void search(String q) {
    _query = q;
    notifyListeners();
  }

  Future<void> rename(Note note, String title) async {
    await _repo.rename(note.id!, title);
    await load();
  }

  Future<void> delete(Note note) async {
    await _repo.delete(note.id!);
    await load();
  }

  Future<void> toggleBookmark(Note note) async {
    await _repo.setBookmark(note.id!, !note.bookmarked);
    await load();
  }
}