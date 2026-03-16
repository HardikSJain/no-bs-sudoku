import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../game_cubit.dart';
import '../game_state.dart';

class NumberPad extends StatelessWidget {
  const NumberPad({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listenWhen: (prev, curr) => curr.mistakeCount > prev.mistakeCount,
      listener: (_, _) => Haptics.mistake(),
      child: BlocBuilder<GameCubit, GameState>(
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
                            Haptics.correctPlacement();
                            cubit.placeNumber(number);
                          },
                    child: Container(
                      height: 52,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isComplete
                              ? AppColors.borderSubtle
                              : AppColors.border,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '$number',
                          style: AppTypography.number.copyWith(
                            color: isComplete
                                ? AppColors.textDisabled
                                : state.isNotesMode
                                    ? AppColors.textSecondary
                                    : AppColors.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
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
      ),
    );
  }
}
