import 'package:flutter/material.dart';

import '../../../core/a11y/tappable.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/haptics.dart';

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

    final col = context.appColors;
    final cells = <Widget>[];

    if (currentStreak > 0) {
      cells.add(_StatCell(value: '$currentStreak', label: 'streak', col: col));
    }
    cells.add(_StatCell(value: '$totalSolved', label: 'solved', col: col));
    cells.add(_StatCell(value: '$avgQuality', label: 'avg', col: col));

    return Tappable(
      label: [
        if (currentStreak > 0)
          '$currentStreak day streak',
        '$totalSolved solved',
        'average quality $avgQuality',
      ].join(', '),
      hint: 'see your full stats',
      onTap: () {
        Haptics.tap();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: col.outline,
            width: 2,
          ),
          boxShadow: col.cardShadow,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < cells.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: col.outline.withValues(alpha: 0.4),
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
  final AppThemeColors col;

  const _StatCell({
    required this.value,
    required this.label,
    required this.col,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.number.copyWith(
            color: col.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: col.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
