import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
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

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: completed
            ? null
            : () {
                HapticFeedback.lightImpact();
                onTap?.call();
              },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.accent,
              width: 1.5,
            ),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (!completed)
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: AppColors.textDisabled,
                      size: 12,
                    ),
                  if (completed)
                    Text(
                      '\u2713',
                      style: AppTypography.label.copyWith(
                        color: AppColors.accent,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$today \u00b7 $difficulty \u00b7 #$puzzleNum',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              LinearProgressIndicator(
                value: completed ? 1.0 : 0.0,
                minHeight: 2,
                backgroundColor: AppColors.border,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                borderRadius: BorderRadius.circular(1),
              ),
              const SizedBox(height: AppSpacing.sm),
              if (completed && timeSeconds != null)
                Text(
                  'completed \u00b7 ${_formatTime(timeSeconds!)}',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accentDim,
                    fontSize: 11,
                  ),
                )
              else
                Text(
                  'not played',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
            ],
          ),
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
