import 'package:flutter/material.dart';

import '../../../models/bullet.dart';
import '../../../models/chapter.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../utils/duration_format.dart';

/// 可展開的章節卡：標題列 + 展開後的 TextRank 重點。
class ChapterCard extends StatefulWidget {
  final Chapter chapter;
  final bool initiallyExpanded;
  final int? highlightedTimestampMs;
  final void Function(Bullet) onBulletTap;

  const ChapterCard({
    super.key,
    required this.chapter,
    this.initiallyExpanded = false,
    this.highlightedTimestampMs,
    required this.onBulletTap,
  });

  @override
  State<ChapterCard> createState() => _ChapterCardState();
}

class _ChapterCardState extends State<ChapterCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.m),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  _TsBadge(text: DurationFormat.hms(widget.chapter.startMs)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.chapter.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more,
                        size: 22, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: _expanded ? _body() : const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }

  Widget _body() {
    if (widget.chapter.bullets.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(42, 0, 14, 12),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text('（此章節沒有重點摘要）',
              style: TextStyle(fontSize: 13, color: AppColors.outline)),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(42, 0, 14, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final bullet in widget.chapter.bullets) _bullet(bullet),
        ],
      ),
    );
  }

  Widget _bullet(Bullet bullet) {
    final highlighted = widget.highlightedTimestampMs == bullet.timestampMs;
    return InkWell(
      onTap: () => widget.onBulletTap(bullet),
      borderRadius: BorderRadius.circular(AppRadius.xs),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.symmetric(vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: highlighted ? AppColors.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                DurationFormat.hms(bullet.timestampMs),
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                bullet.text,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: highlighted
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TsBadge extends StatelessWidget {
  final String text;
  const _TsBadge({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.primary,
          ),
        ),
      );
}