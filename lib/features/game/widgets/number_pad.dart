import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../game_cubit.dart';
import '../game_state.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.board != curr.board || prev.isNotesMode != curr.isNotesMode,
      builder: (context, state) {
        final cubit = context.read<GameCubit>();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: List.generate(9, (i) {
              final number = i + 1;
              final isComplete = cubit.countDigit(number) >= 9;
              return Expanded(
                child: GestureDetector(
                  onTap: isComplete
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          cubit.placeNumber(number);
                        },
                  child: Container(
                    height: 48,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: isComplete
                          ? Colors.transparent
                          : AppColors.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isComplete
                            ? AppColors.border.withValues(alpha: 0.3)
                            : AppColors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '$number',
                        style: AppTypography.number.copyWith(
                          color: isComplete
                              ? AppColors.textDisabled
                              : state.isNotesMode
                                  ? AppColors.notes
                                  : AppColors.textPrimary,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
