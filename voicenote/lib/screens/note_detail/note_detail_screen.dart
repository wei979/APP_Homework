import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/bullet.dart';
import '../../models/note.dart';
import '../../providers/player_provider.dart';
import '../../services/app_services.dart';
import '../../theme/app_colors.dart';
import '../../utils/duration_format.dart';
import 'widgets/audio_player_bar.dart';
import 'widgets/chapter_card.dart';

/// 步驟四～六：筆記詳情頁（章節重點 + 播放器 + 匯出選單）。
class NoteDetailScreen extends StatefulWidget {
  final int noteId;
  const NoteDetailScreen({super.key, required this.noteId});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

enum _MenuAction { exportMarkdown, exportAudio, share, rename, delete }

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Note? _note;
  bool _loading = true;
  PlayerProvider? _player;
  int? _highlightedTs;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final note =
        await context.read<AppServices>().repository.getById(widget.noteId);
    if (!mounted) return;
    setState(() {
      _note = note;
      _loading = false;
      if (note != null) {
        _player?.dispose();
        _player = PlayerProvider(
          fallbackDurationMs: note.durationMs,
          audioPath: note.audioPath,
        );
      }
    });
  }

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final note = _note;
    if (note == null || _player == null) {
      return Scaffold(
        appBar: AppBar(leading: const BackButton()),
        body: const Center(child: Text('找不到這份筆記')),
      );
    }

    return ChangeNotifierProvider<PlayerProvider>.value(
      value: _player!,
      child: Scaffold(
        appBar: AppBar(
          leading: const BackButton(),
          titleSpacing: 0,
          title: Text(note.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w500)),
          actions: [
            IconButton(
              tooltip: '書籤',
              onPressed: _toggleBookmark,
              icon: Icon(
                  note.bookmarked ? Icons.bookmark : Icons.bookmark_border),
            ),
            PopupMenuButton<_MenuAction>(
              icon: const Icon(Icons.more_vert),
              onSelected: _onMenu,
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: _MenuAction.exportMarkdown,
                  child: _MenuRow(Icons.description, '匯出為 Markdown'),
                ),
                PopupMenuItem(
                  value: _MenuAction.exportAudio,
                  child: _MenuRow(Icons.audio_file, '匯出原始錄音'),
                ),
                PopupMenuItem(
                  value: _MenuAction.share,
                  child: _MenuRow(Icons.share, '分享筆記'),
                ),
                PopupMenuDivider(),
                PopupMenuItem(
                  value: _MenuAction.rename,
                  child: _MenuRow(Icons.edit, '重新命名'),
                ),
                PopupMenuItem(
                  value: _MenuAction.delete,
                  child: _MenuRow(Icons.delete_outline, '刪除筆記',
                      color: AppColors.error),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            _MetaRow(note: note),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: note.chapters.length,
                itemBuilder: (context, i) {
                  final chapter = note.chapters[i];
                  return ChapterCard(
                    chapter: chapter,
                    initiallyExpanded: i == 0,
                    highlightedTimestampMs: _highlightedTs,
                    onBulletTap: (b) => _onBulletTap(b),
                  );
                },
              ),
            ),
            AudioPlayerBar(noteTitle: note.title, chapters: note.chapters),
          ],
        ),
      ),
    );
  }

  void _onBulletTap(Bullet bullet) {
    setState(() => _highlightedTs = bullet.timestampMs);
    _player!.jumpAndPlay(bullet.timestampMs);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.fast_rewind,
                  size: 18, color: AppColors.primaryContainer),
              const SizedBox(width: 10),
              Text('已跳轉至 ${DurationFormat.hms(bullet.timestampMs)} ・ 開始播放'),
            ],
          ),
          duration: const Duration(seconds: 2),
        ),
      );
  }

  Future<void> _toggleBookmark() async {
    final note = _note!;
    await context
        .read<AppServices>()
        .repository
        .setBookmark(note.id!, !note.bookmarked);
    if (!mounted) return;
    setState(() => _note = note.copyWith(bookmarked: !note.bookmarked));
  }

  Future<void> _onMenu(_MenuAction action) async {
    final services = context.read<AppServices>();
    final note = _note!;
    switch (action) {
      case _MenuAction.exportMarkdown:
      case _MenuAction.share:
        await services.exporter.share(note);
      case _MenuAction.exportAudio:
        if (note.audioPath.isEmpty || !File(note.audioPath).existsSync()) {
          _toast('此筆記沒有可匯出的原始錄音檔');
        } else {
          await Share.shareXFiles([XFile(note.audioPath)], text: note.title);
        }
      case _MenuAction.rename:
        await _renameDialog();
      case _MenuAction.delete:
        await _confirmDelete();
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _renameDialog() async {
    final note = _note!;
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
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('儲存'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (newTitle != null && newTitle.isNotEmpty && mounted) {
      await context.read<AppServices>().repository.rename(note.id!, newTitle);
      if (!mounted) return;
      setState(() => _note = note.copyWith(title: newTitle));
    }
  }

  Future<void> _confirmDelete() async {
    final note = _note!;
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
    if (ok == true && mounted) {
      await context.read<AppServices>().repository.delete(note.id!);
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _MetaRow extends StatelessWidget {
  final Note note;
  const _MetaRow({required this.note});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        children: [
          const Icon(Icons.schedule, size: 14, color: AppColors.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(DurationFormat.hms(note.durationMs),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
          Container(
            width: 3,
            height: 3,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            decoration: const BoxDecoration(
                color: AppColors.outline, shape: BoxShape.circle),
          ),
          Text('${note.chapterCount} 章節 ・ ${note.bulletCount} 條重點',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _MenuRow(this.icon, this.label, {this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: color ?? AppColors.onSurfaceVariant),
        const SizedBox(width: 14),
        Text(label, style: TextStyle(fontSize: 13.5, color: color)),
      ],
    );
  }
}