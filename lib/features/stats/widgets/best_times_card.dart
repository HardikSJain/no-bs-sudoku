import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class BestTimesCard extends StatelessWidget {
  final List<PuzzleRecord> records;
  final String difficulty;

  const BestTimesCard({
    super.key,
    required this.records,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    if (records.isEmpty) return const SizedBox.shrink();

    final sorted = [...records]..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
    final top3 = sorted.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'best times · $difficulty',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        ...top3.map(_buildRow),
      ],
    );
  }

  Widget _buildRow(PuzzleRecord r) {
    final m = r.timeSeconds ~/ 60;
    final s = r.timeSeconds % 60;
    final date = DateFormat('MMM d').format(r.completedAt);
    final quality = r.qualityScore.round();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            '$m:${s.toString().padLeft(2, '0')}',
            style: AppTypography.number.copyWith(
              color: AppColors.textPrimary,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            date,
            style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
          ),
          const Spacer(),
          Text(
            '$quality',
            style: AppTypography.number.copyWith(
              color: AppColors.accentDim,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 8),
          if (r.hintsUsed > 0)
            Text(
              '${r.hintsUsed}h',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textDisabled),
            ),
        ],
      ),
    );
  }
}
