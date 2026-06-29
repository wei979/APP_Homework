import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/note.dart';
import '../../providers/note_list_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_dimens.dart';
import '../note_detail/note_detail_screen.dart';
import '../record/record_screen.dart';
import 'widgets/note_tile.dart';

/// 步驟一：筆記列表頁（App 進入點）。
class NoteListScreen extends StatelessWidget {
  const NoteListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: const Text(
          '我的筆記',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            tooltip: '篩選',
            onPressed: () {},
            icon: const Icon(Icons.filter_list),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _newRecording(context),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        icon: const Icon(Icons.mic),
        label: const Text('新增錄音', style: TextStyle(fontWeight: FontWeight.w600)),
      ),
      body: Consumer<NoteListProvider>(
        builder: (context, p, _) {
          return Column(
            children: [
              const _SearchField(),
              if (p.loading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (p.notes.isEmpty)
                const Expanded(child: _EmptyState())
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 96),
                    itemCount: p.notes.length,
                    itemBuilder: (context, i) {
                      final note = p.notes[i];
                      return NoteTile(
                        note: note,
                        onTap: () => _openNote(context, note),
                        onLongPress: () => _showActions(context, p, note),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _newRecording(BuildContext context) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const RecordScreen()),
    );
    if (saved == true && context.mounted) {
      await context.read<NoteListProvider>().load();
    }
  }

  Future<void> _openNote(BuildContext context, Note note) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NoteDetailScreen(noteId: note.id!)),
    );
    if (context.mounted) await context.read<NoteListProvider>().load();
  }

  void _showActions(BuildContext context, NoteListProvider p, Note note) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                note.title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: AppColors.onSurface),
              ),
            ),
            ListTile(
              leading: Icon(
                  note.bookmarked ? Icons.bookmark : Icons.bookmark_border),
              title: Text(note.bookmarked ? '取消書籤' : '加入書籤'),
              onTap: () {
                Navigator.pop(sheetContext);
                p.toggleBookmark(note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('重新命名'),
              onTap: () {
                Navigator.pop(sheetContext);
                _renameDialog(context, p, note);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text('刪除筆記',
                  style: TextStyle(color: AppColors.error)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context, p, note);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _renameDialog(
      BuildContext context, NoteListProvider p, Note note) async {
    final controller = TextEditingController(text: note.title);
    final newTitle = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('重新命名'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: '課程名稱'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle != null && newTitle.isNotEmpty) {
      await p.rename(note, newTitle);
    }
  }

  Future<void> _confirmDelete(
      BuildContext context, NoteListProvider p, Note note) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('刪除筆記'),
        content: Text('確定要刪除「${note.title}」嗎？此動作無法復原。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
    if (ok == true) await p.delete(note);
  }
}

class _SearchField extends StatefulWidget {
  const _SearchField();
  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          children: [
            const SizedBox(width: 14),
            const Icon(Icons.search, color: AppColors.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                onChanged: (v) => context.read<NoteListProvider>().search(v),
                decoration: const InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  hintText: '搜尋筆記、課程或關鍵字',
                  hintStyle: TextStyle(
                      fontSize: 14, color: AppColors.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.mic_none, size: 56, color: AppColors.outline),
          SizedBox(height: 12),
          Text('還沒有任何筆記',
              style: TextStyle(color: AppColors.onSurfaceVariant)),
          SizedBox(height: 4),
          Text('點右下角「新增錄音」開始',
              style: TextStyle(fontSize: 12, color: AppColors.outline)),
        ],
      ),
    );
  }
}