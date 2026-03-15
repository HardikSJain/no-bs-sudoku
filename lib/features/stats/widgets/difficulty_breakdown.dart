import 'package:flutter/material.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class DifficultyBreakdown extends StatelessWidget {
  final Map<String, List<PuzzleRecord>> byDifficulty;

  const DifficultyBreakdown({super.key, required this.byDifficulty});

  @override
  Widget build(BuildContext context) {
    final diffs = ['easy', 'medium', 'hard', 'expert']
        .where((d) => byDifficulty.containsKey(d) && byDifficulty[d]!.isNotEmpty)
        .toList();

    if (diffs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'by difficulty',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...diffs.map((d) => _buildRow(d, byDifficulty[d]!)),
      ],
    );
  }

  Widget _buildRow(String difficulty, List<PuzzleRecord> records) {
    final count = records.length;
    final bestTime = records.map((r) => r.timeSeconds).reduce((a, b) => a < b ? a : b);
    final avgQuality =
        (records.map((r) => r.qualityScore).reduce((a, b) => a + b) / count).round();
    final bestMins = bestTime ~/ 60;
    final bestSecs = bestTime % 60;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text(
              difficulty,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Expanded(
            child: Text(
              '$count solved',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            '$bestMins:${bestSecs.toString().padLeft(2, '0')}',
            style: AppTypography.number.copyWith(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 32,
            child: Text(
              '$avgQuality',
              style: AppTypography.number.copyWith(
                color: AppColors.accentDim,
                fontSize: 14,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
