import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/a11y/tappable.dart';
import '../../../core/haptics.dart';
import '../../../engine/deduction/units.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../game_cubit.dart';
import '../game_state.dart';
import 'sudoku_cell.dart';

class SudokuGrid extends StatelessWidget {
  const SudokuGrid({super.key});

  @override
  Widget build(BuildContext context) {
    final themeColors = context.appColors;
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.board != curr.board ||
          prev.selectedRow != curr.selectedRow ||
          prev.selectedCol != curr.selectedCol ||
          prev.notes != curr.notes ||
          prev.completionFlashCells != curr.completionFlashCells ||
          // A hint tap repaints the board: targets and witnesses light up.
          // One BlocBuilder over 81 cells is cheaper here than 81 selectors,
          // which would each re-evaluate on every timer tick.
          prev.activeHint != curr.activeHint ||
          prev.hintRung != curr.hintRung ||
          prev.wrongCells != curr.wrongCells ||
          prev.flagMistakesInstantly != curr.flagMistakesInstantly ||
          prev.previewDigit != curr.previewDigit,
      builder: (context, state) {
        // The board is the one surface that cannot scale with the system
        // text setting: it is a nine-by-nine grid that must stay square and
        // fit the width, so the cells cannot grow and a 2x digit inside a
        // 39dp cell is not larger, it is clipped. Everything else in the app
        // scales normally.
        final scaled = MediaQuery.of(context).copyWith(
          textScaler: TextScale.clampFor(context, TextScale.boardMax),
        );
        // Computed once per build, not once per cell.
        final preview = state.previewCells;
        final hintUnit = state.hintUnitCells;
        final borderOuter = themeColors.ink;
        final borderStrong = themeColors.ink2;
        final borderLight = themeColors.ink4;

        return MediaQuery(
          data: scaled,
          child: Semantics(
            container: true,
            label: 'sudoku board, 9 by 9',
            child: AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              color: themeColors.paper,
              border: Border.all(color: borderOuter, width: 2),
              borderRadius: BorderRadius.circular(12),
              boxShadow: themeColors.stickerShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10.5),
              child: Column(
                children: List.generate(9, (rowIdx) {
                  return Expanded(
                    child: Row(
                      children: List.generate(9, (colIdx) {
                        return Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              border: _cellBorder(
                                rowIdx, colIdx, borderStrong, borderLight,
                              ),
                            ),
                            child: SudokuCell(
                              row: rowIdx,
                              col: colIdx,
                              value: state.board.get(rowIdx, colIdx),
                              notes: state.notesAt(rowIdx, colIdx),
                              isGiven: state.isGiven(rowIdx, colIdx),
                              isSelected: state.selectedRow == rowIdx &&
                                  state.selectedCol == colIdx,
                              isSameNumber: _isSameNumber(state, rowIdx, colIdx),
                              isRelated: _isRelated(state, rowIdx, colIdx),
                              isConflict: _isConflict(state, rowIdx, colIdx),
                              isPreviewSpot:
                                  preview.contains(rowIdx * 9 + colIdx),
                              isHintUnit:
                                  hintUnit.contains(rowIdx * 9 + colIdx),
                              isHintTarget: state.hintTargets
                                  .contains(rowIdx * 9 + colIdx),
                              isHintWitness: state.hintWitnesses
                                  .contains(rowIdx * 9 + colIdx),
                              isEvenBox: (rowIdx ~/ 3 + colIdx ~/ 3) % 2 == 0,
                              isGroupJustComplete: state.completionFlashCells
                                  .contains(rowIdx * 9 + colIdx),
                              // Selecting a cell is the thing this app is
                              // asked to do more than anything else, and it
                              // was the one tap in the game with no feel to
                              // it — the pad, the toolbar and the keyboard
                              // all answered, the board did not.
                              onTap: () {
                                Haptics.select();
                                context
                                    .read<GameCubit>()
                                    .selectCell(rowIdx, colIdx);
                              },
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
            ),
          ),
        );
      },
    );
  }

  Border _cellBorder(
    int row, int col, Color strong, Color light,
  ) {
    return Border(
      right: col < 8
          ? BorderSide(
              color: (col + 1) % 3 == 0 ? strong : light,
              width: (col + 1) % 3 == 0 ? 1.5 : 0.5,
            )
          : BorderSide.none,
      bottom: row < 8
          ? BorderSide(
              color: (row + 1) % 3 == 0 ? strong : light,
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
    if (state.flagMistakesInstantly) return val != state.solution.get(row, col);

    // No-oracle mode: a digit reddens only when it breaks an actual rule, not
    // merely because it disagrees with the answer we happen to be holding.
    // Being told instantly is a real crutch for some players and a spoiler
    // for others, which is why it is a switch rather than a decision.
    // A rule violation is the same digit anywhere this cell can see, which
    // is precisely its peer set.
    for (final peer in Units.peersOf[row * 9 + col]) {
      if (state.board.get(peer ~/ 9, peer % 9) == val) return true;
    }
    return false;
  }
}
