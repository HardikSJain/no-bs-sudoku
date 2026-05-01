import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
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

    final col = context.appColors;
    final cells = <Widget>[];

    if (currentStreak > 0) {
      cells.add(_StatCell(value: '$currentStreak', label: 'streak', col: col));
    }
    cells.add(_StatCell(value: '$totalSolved', label: 'solved', col: col));
    cells.add(_StatCell(value: '$avgQuality', label: 'avg', col: col));

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
          color: col.surface,
          borderRadius: BorderRadius.circular(col.isLight ? 8 : 10),
          border: Border.all(
            color: col.outline,
            width: col.isLight ? 2 : 0.5,
          ),
          boxShadow: col.isLight ? col.cardShadow : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < cells.length; i++) ...[
              if (i > 0)
                Container(
                  width: col.isLight ? 1 : 0.5,
                  height: 24,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: col.outline.withValues(alpha: col.isLight ? 0.4 : 1),
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
