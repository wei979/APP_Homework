import 'package:flutter/material.dart';

import '../../../models/note.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/app_dimens.dart';
import '../../../utils/date_format.dart';
import '../../../utils/duration_format.dart';

/// 筆記列表的單列：頭像 + 標題 + （日期・時長・章節數）。
class NoteTile extends StatelessWidget {
  final Note note;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const NoteTile({
    super.key,
    required this.note,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(AppRadius.m),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.graphic_eq,
                  size: 22, color: AppColors.onPrimaryContainer),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          note.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                      if (note.bookmarked)
                        const Icon(Icons.bookmark,
                            size: 16, color: AppColors.primary),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        RelativeDate.label(note.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const _Dot(),
                      Text(
                        DurationFormat.hms(note.durationMs),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.onSurfaceVariant),
                      ),
                      const _Dot(),
                      _ChapterChip(count: note.chapterCount),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();
  @override
  Widget build(BuildContext context) => Container(
        width: 3,
        height: 3,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: const BoxDecoration(
          color: AppColors.outline,
          shape: BoxShape.circle,
        ),
      );
}

class _ChapterChip extends StatelessWidget {
  final int count;
  const _ChapterChip({required this.count});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.secondaryContainer,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          '$count 章節',
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.onSecondaryContainer,
          ),
        ),
      );
}