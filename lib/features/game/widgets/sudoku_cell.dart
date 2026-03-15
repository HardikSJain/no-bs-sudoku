import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class SudokuCell extends StatelessWidget {
  final int value;
  final Set<int> notes;
  final bool isGiven;
  final bool isSelected;
  final bool isSameNumber;
  final bool isRelated;
  final bool isConflict;
  final VoidCallback onTap;

  const SudokuCell({
    super.key,
    required this.value,
    required this.notes,
    required this.isGiven,
    required this.isSelected,
    required this.isSameNumber,
    required this.isRelated,
    required this.isConflict,
    required this.onTap,
  });

  Color get _backgroundColor {
    if (isSelected) return AppColors.surfaceElevated;
    if (isConflict) return AppColors.errorSubtle;
    if (isSameNumber) return AppColors.accentSubtle;
    if (isRelated) return AppColors.surface;
    return Colors.transparent;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _backgroundColor,
          border: isSelected
              ? const Border(left: BorderSide(color: AppColors.accent, width: 2))
              : null,
        ),
        child: Center(
          child: value != 0 ? _buildValue() : _buildNotes(),
        ),
      ),
    );
  }

  Widget _buildValue() {
    final color = isConflict
        ? AppColors.error
        : isGiven
            ? AppColors.given
            : AppColors.user;

    final widget = Text(
      '$value',
      style: AppTypography.number.copyWith(
        color: color,
        fontWeight: isGiven ? FontWeight.w600 : FontWeight.w400,
      ),
    );

    if (!isGiven && !isConflict) {
      return widget
          .animate(key: ValueKey('$value'))
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 120.ms,
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: 80.ms);
    }

    if (isConflict) {
      return widget
          .animate(key: ValueKey('conflict_$value'))
          .shakeX(hz: 4, amount: 2, duration: 200.ms);
    }

    return widget;
  }

  Widget _buildNotes() {
    if (notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: List.generate(9, (i) {
          final n = i + 1;
          return Center(
            child: Text(
              notes.contains(n) ? '$n' : '',
              style: AppTypography.numberSmall.copyWith(
                color: AppColors.notes,
              ),
            ),
          );
        }),
      ),
    );
  }
}
