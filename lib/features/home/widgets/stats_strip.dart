import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
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

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            if (currentStreak > 0) ...[
              _stat('🔥 $currentStreak', ''),
              _divider(),
            ],
            _stat('$totalSolved', 'solved'),
            _divider(),
            _stat('$avgQuality', 'avg'),
          ],
        ),
      ),
    );
  }

  Widget _stat(String value, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.number.copyWith(
            color: AppColors.textPrimary,
            fontSize: 15,
          ),
        ),
        if (label.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 0.5,
      height: 16,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: AppColors.border,
    );
  }
}
