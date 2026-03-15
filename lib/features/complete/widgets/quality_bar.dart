import 'package:flutter/material.dart';

import '../../../core/intelligence/quality_score.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class QualityBar extends StatelessWidget {
  final double score;
  final Animation<double> fillAnimation;

  const QualityBar({
    super.key,
    required this.score,
    required this.fillAnimation,
  });

  @override
  Widget build(BuildContext context) {
    final label = QualityScore.label(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'quality score',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
            AnimatedBuilder(
              animation: fillAnimation,
              builder: (_, _) {
                final displayed = (score * fillAnimation.value).round();
                return Text(
                  '$displayed · $label',
                  style: AppTypography.label.copyWith(
                    color: AppColors.textPrimary,
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: fillAnimation,
          builder: (_, _) {
            return Container(
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: (score / 100) * fillAnimation.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
