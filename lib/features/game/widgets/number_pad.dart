import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/haptics.dart';
import '../../../core/theme/app_theme_colors.dart';
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
            prev.board != curr.board ||
            prev.isNotesMode != curr.isNotesMode ||
            prev.selectedRow != curr.selectedRow ||
            prev.selectedCol != curr.selectedCol ||
            prev.selectedDigit != curr.selectedDigit ||
            prev.digitFirstInput != curr.digitFirstInput,
        builder: (context, state) {
          final cubit = context.read<GameCubit>();
          final col = context.appColors;

          // Single O(81) pass instead of 9 separate scans
          final counts = List<int>.filled(10, 0);
          for (int r = 0; r < 9; r++) {
            for (int c = 0; c < 9; c++) {
              final v = state.board.get(r, c);
              if (v > 0) counts[v]++;
            }
          }

          final selectedVal = state.selectedValue;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: List.generate(9, (i) {
                final number = i + 1;
                final remaining = 9 - counts[number];
                final isComplete = remaining <= 0;
                // Cell-first: highlight matches selected cell value
                // Digit-first: highlight the selected digit from pad
                final isFocused = !isComplete && (
                    state.digitFirstInput
                        ? number == state.selectedDigit
                        : (selectedVal != null && selectedVal != 0 && number == selectedVal));
                final padColor = col.padColor(number);

                return Expanded(
                  child: GestureDetector(
                    onTap: isComplete
                        ? null
                        : () {
                            Haptics.tap();
                            if (state.digitFirstInput) {
                              cubit.selectDigit(number);
                            } else {
                              cubit.placeNumber(number);
                            }
                          },
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: isComplete
                                ? const Color(0xFFEDE3CF)
                                : isFocused
                                    ? padColor
                                    : col.paper,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isComplete
                                  ? col.ink4
                                  : col.ink,
                              width: 2,
                            ),
                            boxShadow: isComplete || !isFocused
                                ? []
                                : [BoxShadow(
                                    color: col.ink,
                                    offset: const Offset(2, 2),
                                    blurRadius: 0,
                                  )],
                          ),
                          child: Center(
                            child: Text(
                              '$number',
                              style: AppTypography.number.copyWith(
                                color: isComplete
                                    ? col.ink4
                                    : col.ink,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                decoration: isComplete
                                    ? TextDecoration.lineThrough
                                    : null,
                                decorationColor: col.ink4,
                              ),
                            ),
                          ),
                        ),
                        if (!isComplete)
                          Positioned(
                            right: 5,
                            bottom: 3,
                            child: Text(
                              '$remaining',
                              style: AppTypography.numberSmall.copyWith(
                                color: col.ink3,
                                fontSize: 8,
                              ),
                            ),
                          ),
                      ],
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
