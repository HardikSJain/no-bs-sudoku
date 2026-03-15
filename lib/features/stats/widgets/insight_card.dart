import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class InsightCard extends StatelessWidget {
  final String text;

  const InsightCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          left: BorderSide(color: AppColors.accent, width: 2),
        ),
      ),
      child: Text(
        text,
        style: AppTypography.body.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
