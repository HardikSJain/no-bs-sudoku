import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ResumeCard extends StatelessWidget {
  final String difficulty;
  final int elapsedSeconds;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const ResumeCard({
    super.key,
    required this.difficulty,
    required this.elapsedSeconds,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final m = elapsedSeconds ~/ 60;
    final s = elapsedSeconds % 60;
    final time = '$m:${s.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'resume',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onDismiss();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.textDisabled,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$difficulty · $time elapsed',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'tap to continue',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
