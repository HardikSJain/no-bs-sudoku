import 'dart:async';
import 'dart:isolate';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engine/deduction/units.dart';
import '../../engine/sudoku_board.dart';
import '../../core/logger.dart';
import '../../engine/sudoku_solver.dart';

class ImportState {
  const ImportState({
    required this.cells,
    this.selected,
    this.analysis,
    this.checking = false,
  });

  ImportState.empty()
      : cells = List<int>.filled(81, 0),
        selected = null,
        analysis = null,
        checking = false;

  final List<int> cells;
  final int? selected;

  /// Null until the grid has been checked, and cleared on every edit — a
  /// verdict about a grid the player has since changed is worse than none.
  final ImportAnalysis? analysis;

  final bool checking;

  SudokuBoard get board => SudokuBoard(cells);

  int get filled => cells.where((v) => v != 0).length;

  /// Cells whose digit repeats somewhere they can see.
  ///
  /// Recomputed on every keystroke rather than on analysis, because a
  /// duplicate is the one mistake worth showing before the player asks.
  Set<int> get conflicts {
    final bad = <int>{};
    for (int i = 0; i < 81; i++) {
      final v = cells[i];
      if (v == 0) continue;
      for (final peer in Units.peersOf[i]) {
        if (cells[peer] == v) {
          bad..add(i)..add(peer);
        }
      }
    }
    return bad;
  }

  bool get canCheck => filled > 0 && conflicts.isEmpty && !checking;

  ImportState copyWith({
    List<int>? cells,
    int? Function()? selected,
    ImportAnalysis? Function()? analysis,
    bool? checking,
  }) =>
      ImportState(
        cells: cells ?? this.cells,
        selected: selected != null ? selected() : this.selected,
        analysis: analysis != null ? analysis() : this.analysis,
        checking: checking ?? this.checking,
      );
}

class ImportCubit extends Cubit<ImportState> {
  ImportCubit() : super(ImportState.empty()) {
    Log.importOpened();
  }

  void select(int index) => emit(state.copyWith(selected: () => index));

  void place(int digit) {
    final i = state.selected;
    if (i == null) return;
    final cells = [...state.cells]..[i] = digit;
    _edited(cells, advance: i);
  }

  void erase() {
    final i = state.selected;
    if (i == null || state.cells[i] == 0) return;
    final cells = [...state.cells]..[i] = 0;
    _edited(cells);
  }

  void clearAll() => emit(ImportState.empty());

  /// Accepts the usual 81-character forms: digits with `0`, `.` or space for
  /// blanks, and any punctuation or line breaks between them ignored. Returns
  /// false when the text is not a grid, so the caller can say so rather than
  /// silently filling in nonsense.
  bool paste(String text) {
    final cells = <int>[];
    for (final rune in text.trim().split('')) {
      if (rune == '0' || rune == '.' || rune == '_' || rune == '-') {
        cells.add(0);
      } else if (RegExp(r'[1-9]').hasMatch(rune)) {
        cells.add(int.parse(rune));
      }
      // Anything else — commas, newlines, pipes, spaces — is separator.
    }
    final accepted = cells.length == 81;
    Log.importPasted(accepted: accepted);
    if (!accepted) return false;
    _edited(cells);
    return true;
  }

  /// Any edit invalidates a previous verdict.
  void _edited(List<int> cells, {int? advance}) {
    int? next = state.selected;
    if (advance != null) {
      // Move on so a grid can be typed without reaching for each cell.
      next = advance + 1 <= 80 ? advance + 1 : advance;
    }
    emit(state.copyWith(
      cells: cells,
      selected: () => next,
      analysis: () => null,
    ));
  }

  /// Checks the grid on an isolate.
  ///
  /// Counting solutions is exponential and a typed grid can be far worse than
  /// a generated one, so this never runs on the main thread and never runs
  /// unbounded.
  Future<void> check() async {
    if (!state.canCheck) return;
    emit(state.copyWith(checking: true, analysis: () => null));

    final cells = state.cells;
    final analysis = await Isolate.run(() {
      return SudokuSolver().analyseImport(SudokuBoard(cells));
    });

    if (isClosed) return;
    Log.importChecked(
      verdict: analysis.verdict.name,
      clues: cells.where((v) => v != 0).length,
    );
    emit(state.copyWith(checking: false, analysis: () => analysis));
  }
}
