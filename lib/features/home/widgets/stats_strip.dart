import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class StatsStrip extends StatelessWidget {
  final int currentStreak;
  final int totalSolved;
  final int avgQuality;
  final VoidCallback onTap;

  const StatsStrip({
    super.key,
    required this.currentStreak,
    required this.totalSolved,
    required this.avgQuality,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (totalSolved < 1) return const SizedBox.shrink();

    final cells = <Widget>[];

    if (currentStreak > 0) {
      cells.add(_StatCell(value: '$currentStreak', label: 'streak'));
    }
    cells.add(_StatCell(value: '$totalSolved', label: 'solved'));
    cells.add(_StatCell(value: '$avgQuality', label: 'avg'));

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderSubtle, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < cells.length; i++) ...[
              if (i > 0)
                Container(
                  width: 0.5,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: AppColors.borderSubtle,
                ),
              cells[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  final String value;
  final String label;

  const _StatCell({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.number.copyWith(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
