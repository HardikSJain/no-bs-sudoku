import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class DailyPuzzleCard extends StatelessWidget {
  final bool completed;
  final int? timeSeconds;
  final String difficulty;
  final int puzzleNum;
  final VoidCallback? onTap;

  const DailyPuzzleCard({
    super.key,
    required this.completed,
    this.timeSeconds,
    required this.difficulty,
    required this.puzzleNum,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('MMM d').format(DateTime.now());

    return GestureDetector(
      onTap: completed
          ? null
          : () {
              HapticFeedback.lightImpact();
              onTap?.call();
            },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: completed ? AppColors.border : AppColors.accent,
            width: completed ? 0.5 : 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'daily puzzle',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (!completed)
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: AppColors.textDisabled,
                    size: 14,
                  ),
                if (completed)
                  const Icon(
                    Icons.check_rounded,
                    color: AppColors.accent,
                    size: 16,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '$today · $difficulty · #$puzzleNum',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            if (completed && timeSeconds != null) ...[
              Text(
                _formatTime(timeSeconds!),
                style: AppTypography.number.copyWith(
                  color: AppColors.accent,
                  fontSize: 16,
                ),
              ),
            ] else ...[
              // Not played — greyed progress placeholder
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'not played',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
