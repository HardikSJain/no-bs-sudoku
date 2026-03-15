import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/theme/app_colors.dart';
import '../game_cubit.dart';
import '../game_state.dart';
import 'sudoku_cell.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.board != curr.board ||
          prev.selectedRow != curr.selectedRow ||
          prev.selectedCol != curr.selectedCol ||
          prev.notes != curr.notes,
      builder: (context, state) {
        return AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: const Color(0xFF3A3A3A),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.5),
              child: Column(
                children: List.generate(9, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(9, (col) {
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: _cellBorder(row, col),
                            ),
                            child: SudokuCell(
                              value: state.board.get(row, col),
                              notes: state.notesAt(row, col),
                              isGiven: state.isGiven(row, col),
                              isSelected: state.selectedRow == row &&
                                  state.selectedCol == col,
                              isSameNumber: _isSameNumber(state, row, col),
                              isRelated: _isRelated(state, row, col),
                              isConflict: _isConflict(state, row, col),
                              onTap: () => context
                                  .read<GameCubit>()
                                  .selectCell(row, col),
                            ),
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  Border _cellBorder(int row, int col) {
    return Border(
      right: col < 8
          ? BorderSide(
              color: (col + 1) % 3 == 0
                  ? const Color(0xFF3A3A3A)
                  : AppColors.border,
              width: (col + 1) % 3 == 0 ? 1.5 : 0.5,
            )
          : BorderSide.none,
      bottom: row < 8
          ? BorderSide(
              color: (row + 1) % 3 == 0
                  ? const Color(0xFF3A3A3A)
                  : AppColors.border,
              width: (row + 1) % 3 == 0 ? 1.5 : 0.5,
            )
          : BorderSide.none,
    );
  }

  bool _isSameNumber(GameState state, int row, int col) {
    if (!state.highlightMatching) return false;
    if (!state.hasSelection) return false;
    final selectedVal = state.selectedValue;
    if (selectedVal == null || selectedVal == 0) return false;
    final cellVal = state.board.get(row, col);
    return cellVal == selectedVal &&
        !(state.selectedRow == row && state.selectedCol == col);
  }

  bool _isRelated(GameState state, int row, int col) {
    if (!state.hasSelection) return false;
    if (state.selectedRow == row && state.selectedCol == col) return false;
    final sr = state.selectedRow!;
    final sc = state.selectedCol!;
    return row == sr ||
        col == sc ||
        (row ~/ 3 == sr ~/ 3 && col ~/ 3 == sc ~/ 3);
  }

  bool _isConflict(GameState state, int row, int col) {
    final val = state.board.get(row, col);
    if (val == 0) return false;
    return val != state.solution.get(row, col);
  }
}
