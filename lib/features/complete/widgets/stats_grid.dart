import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class StatsGrid extends StatelessWidget {
  final String time;
  final int hints;
  final int mistakes;
  final String? comparison;

  const StatsGrid({
    super.key,
    required this.time,
    required this.hints,
    required this.mistakes,
    this.comparison,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                _cell(time, 'time', isTopLeft: true),
                _dividerV(),
                _cell('$hints', 'hints', isTopRight: true),
              ],
            ),
          ),
          _dividerH(),
          IntrinsicHeight(
            child: Row(
              children: [
                _cell(
                  '$mistakes',
                  'mistakes',
                  isBottomLeft: true,
                ),
                _dividerV(),
                comparison != null
                    ? _cell(
                        comparison!,
                        'vs avg',
                        valueColor: AppColors.accentDim,
                        isBottomRight: true,
                      )
                    : _cell('—', 'vs avg', isBottomRight: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _cell(
    String value,
    String label, {
    Color? valueColor,
    bool isTopLeft = false,
    bool isTopRight = false,
    bool isBottomLeft = false,
    bool isBottomRight = false,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: isTopLeft ? const Radius.circular(7.5) : Radius.zero,
            topRight: isTopRight ? const Radius.circular(7.5) : Radius.zero,
            bottomLeft: isBottomLeft ? const Radius.circular(7.5) : Radius.zero,
            bottomRight:
                isBottomRight ? const Radius.circular(7.5) : Radius.zero,
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: AppTypography.number.copyWith(
                color: valueColor ?? AppColors.textPrimary,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dividerV() => Container(width: 0.5, color: AppColors.border);
  Widget _dividerH() => Container(height: 0.5, color: AppColors.border);
}
