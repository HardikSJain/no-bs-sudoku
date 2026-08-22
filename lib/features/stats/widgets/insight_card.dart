import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';

class InsightCard extends StatelessWidget {
  final String text;
  const InsightCard({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: col.background2,
        border: Border(
          left: BorderSide(color: col.accent, width: 2),
        ),
        borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
      ),
      child: Text(
        text,
        style: AppTypography.body.copyWith(color: col.textSecondary),
      ),
    );
  }
}
