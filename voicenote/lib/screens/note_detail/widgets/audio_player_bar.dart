import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/chapter.dart';
import '../../../providers/player_provider.dart';
import '../../../theme/app_colors.dart';
import '../../../utils/duration_format.dart';

/// 筆記詳情頁底部的錄音播放器。
class AudioPlayerBar extends StatelessWidget {
  final String noteTitle;
  final List<Chapter> chapters;
  const AudioPlayerBar({
    super.key,
    required this.noteTitle,
    required this.chapters,
  });

  int _currentChapter(int pos) {
    var idx = 0;
    for (var i = 0; i < chapters.length; i++) {
      if (chapters[i].startMs <= pos) idx = i;
    }
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PlayerProvider>();
    final dur = p.durationMs;
    final pos = p.positionMs.clamp(0, dur);
    final frac = dur == 0 ? 0.0 : (pos / dur).clamp(0.0, 1.0);
    final chapIdx = chapters.isEmpty ? 0 : _currentChapter(pos);
    final chapterLabel = chapters.isEmpty ? '' : ' ・ 章節 ${chapIdx + 1}';

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border(top: BorderSide(color: AppColors.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$noteTitle$chapterLabel',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  const TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ),
          SliderTheme(
            data: const SliderThemeData(
              trackHeight: 4,
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.surfaceContainerHighest,
              thumbColor: AppColors.primary,
              overlayShape: RoundSliderOverlayShape(overlayRadius: 14),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
            ),
            child: Slider(
              value: frac,
              onChanged: (v) => p.seekTo((v * dur).round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(DurationFormat.hms(pos),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
              Text(DurationFormat.hms(dur),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.onSurfaceVariant)),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ctl(Icons.replay_10, () => p.skip(-10000)),
              const SizedBox(width: 16),
              _ctl(Icons.skip_previous, () {
                if (chapters.isEmpty) return;
                final i = _currentChapter(pos);
                p.jumpAndPlay(chapters[(i - 1).clamp(0, chapters.length - 1)].startMs);
              }),
              const SizedBox(width: 16),
              _PlayButton(isPlaying: p.isPlaying, onTap: p.togglePlay),
              const SizedBox(width: 16),
              _ctl(Icons.skip_next, () {
                if (chapters.isEmpty) return;
                final i = _currentChapter(pos);
                p.jumpAndPlay(
                    chapters[(i + 1).clamp(0, chapters.length - 1)].startMs);
              }),
              const SizedBox(width: 16),
              _ctl(Icons.forward_10, () => p.skip(10000)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ctl(IconData icon, VoidCallback onTap) => IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: AppColors.onSurfaceVariant, size: 22),
      );
}

class _PlayButton extends StatelessWidget {
  final bool isPlaying;
  final VoidCallback onTap;
  const _PlayButton({required this.isPlaying, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(isPlaying ? Icons.pause : Icons.play_arrow,
            color: AppColors.onPrimary, size: 24),
      ),
    );
  }
}