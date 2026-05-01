import 'package:flutter/material.dart';

import '../../../core/intelligence/quality_score.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';

class QualityBar extends StatelessWidget {
  final double score;
  final Animation<double> fillAnimation;

  const QualityBar({
    super.key,
    required this.score,
    required this.fillAnimation,
  });

  static const _tiers = ['chaos', 'rough', 'decent', 'solid', 'clean'];

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final label = QualityScore.label(score).replaceAll('.', '');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: col.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'QUALITY SCORE',
                style: AppTypography.labelSmall.copyWith(
                  color: col.ink3,
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: fillAnimation,
                builder: (_, _) {
                  final displayed = (score * fillAnimation.value).round();
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '$displayed',
                        style: AppTypography.number.copyWith(
                          color: col.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        label.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: col.accent,
                          fontSize: 10,
                          letterSpacing: 0.8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: fillAnimation,
            builder: (_, _) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: col.ink4.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: col.ink, width: 1.5),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (score / 100) * fillAnimation.value,
                    child: Container(
                      decoration: BoxDecoration(
                        color: col.accent,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _tiers.map((tier) {
              final isActive = tier == label.toLowerCase();
              return Text(
                tier,
                style: AppTypography.labelSmall.copyWith(
                  color: isActive ? col.accent : col.ink4,
                  fontSize: 10,
                  letterSpacing: 0.5,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
