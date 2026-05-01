import 'package:flutter/material.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';

class DifficultyBreakdown extends StatelessWidget {
  final Map<String, List<PuzzleRecord>> byDifficulty;

  const DifficultyBreakdown({super.key, required this.byDifficulty});

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final diffs = ['easy', 'medium', 'hard', 'expert']
        .where((d) => byDifficulty.containsKey(d) && byDifficulty[d]!.isNotEmpty)
        .toList();

    if (diffs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('by difficulty', style: AppTypography.label.copyWith(color: col.textSecondary)),
        const SizedBox(height: 12),
        ...diffs.map((d) => _buildRow(d, byDifficulty[d]!, col)),
      ],
    );
  }

  Widget _buildRow(String difficulty, List<PuzzleRecord> records, AppThemeColors col) {
    final count = records.length;
    final bestTime = records.map((r) => r.timeSeconds).reduce((a, b) => a < b ? a : b);
    final avgQuality =
        (records.map((r) => r.qualityScore).reduce((a, b) => a + b) / count).round();
    final bestMins = bestTime ~/ 60;
    final bestSecs = bestTime % 60;

    final diffColor = AppThemeColors.difficultyColors[difficulty] ?? col.accent;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: col.outline.withValues(alpha: col.isLight ? 0.3 : 1),
            width: col.isLight ? 1 : 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          if (col.isLight)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: diffColor,
                shape: BoxShape.circle,
                border: Border.all(color: col.ink, width: 1.5),
              ),
            ),
          SizedBox(
            width: col.isLight ? 56 : 60,
            child: Text(difficulty, style: AppTypography.body.copyWith(color: col.textPrimary)),
          ),
          Expanded(
            child: Text(
              '$count solved',
              style: AppTypography.labelSmall.copyWith(color: col.textSecondary),
            ),
          ),
          Text(
            '$bestMins:${bestSecs.toString().padLeft(2, '0')}',
            style: AppTypography.number.copyWith(color: col.textPrimary, fontSize: 14),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 32,
            child: Text(
              '$avgQuality',
              style: AppTypography.number.copyWith(color: col.accent, fontSize: 14),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
