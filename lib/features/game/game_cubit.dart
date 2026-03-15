import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_generator.dart';
import '../../engine/sudoku_solver.dart';
import 'game_state.dart';

Map<int, Set<int>> _deepCopyNotes(Map<int, Set<int>> notes) =>
    {for (final e in notes.entries) e.key: Set<int>.from(e.value)};

class GameCubit extends Cubit<GameState> {
  Timer? _timer;

  GameCubit._({required GameState initial}) : super(initial);

  factory GameCubit.newGame({Difficulty difficulty = Difficulty.medium, int? seed}) {
    final generator = SudokuGenerator();
    final result = generator.generate(difficulty: difficulty, seed: seed);
    return GameCubit._(initial: _buildState(result.puzzle, result.solution));
  }

  factory GameCubit.daily({required DateTime date}) {
    final generator = SudokuGenerator();
    final result = generator.generateDaily(date: date);
    return GameCubit._(initial: _buildState(result.puzzle, result.solution));
  }

  static GameState _buildState(SudokuBoard puzzle, SudokuBoard solution) {
    final givenCells = <int>{};
    for (int i = 0; i < 81; i++) {
      if (puzzle.get(i ~/ 9, i % 9) != 0) givenCells.add(i);
    }
    return GameState(
      puzzle: puzzle,
      board: puzzle.copy(),
      solution: solution,
      givenCells: givenCells,
    );
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == GameStatus.playing) {
        emit(state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1)));
      }
    });
  }

  void selectCell(int row, int col) {
    if (state.status != GameStatus.playing) return;
    emit(state.copyWith(
      selectedRow: () => row,
      selectedCol: () => col,
    ));
  }

  void placeNumber(int value) {
    if (state.status != GameStatus.playing) return;
    if (!state.hasSelection) return;

    final row = state.selectedRow!;
    final col = state.selectedCol!;
    if (state.isGiven(row, col)) return;

    if (state.isNotesMode) {
      _toggleNote(row, col, value);
      return;
    }

    final previous = state.board.get(row, col);
    if (previous == value) return;

    final prevNotes = state.notesAt(row, col);
    final board = state.board.copy();
    board.set(row, col, value);

    final isCorrect = state.solution.get(row, col) == value;
    final newNotes = _deepCopyNotes(state.notes);

    // Clear notes on this cell
    newNotes.remove(row * 9 + col);

    // Auto-remove this value from notes in same row/col/box
    Map<int, Set<int>> cleared = const {};
    if (isCorrect) {
      cleared = _clearRelatedNotes(newNotes, row, col, value);
    }

    final action = PlaceNumber(row, col, value, previous, prevNotes, cleared);

    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: [...state.history, action],
      mistakeCount: isCorrect ? null : state.mistakeCount + 1,
      status: board.isSolved ? GameStatus.complete : null,
    ));

    if (board.isSolved) _timer?.cancel();
  }

  void _toggleNote(int row, int col, int value) {
    final key = row * 9 + col;
    if (state.board.get(row, col) != 0) return;

    final current = Set<int>.from(state.notesAt(row, col));
    final wasPresent = current.contains(value);

    if (wasPresent) {
      current.remove(value);
    } else {
      current.add(value);
    }

    final newNotes = _deepCopyNotes(state.notes);
    if (current.isEmpty) {
      newNotes.remove(key);
    } else {
      newNotes[key] = current;
    }

    final action = PlaceNote(row, col, value, !wasPresent);

    emit(state.copyWith(
      notes: newNotes,
      history: [...state.history, action],
    ));
  }

  void erase() {
    if (state.status != GameStatus.playing) return;
    if (!state.hasSelection) return;

    final row = state.selectedRow!;
    final col = state.selectedCol!;
    if (state.isGiven(row, col)) return;

    final previous = state.board.get(row, col);
    final prevNotes = state.notesAt(row, col);
    if (previous == 0 && prevNotes.isEmpty) return;

    final board = state.board.copy();
    board.set(row, col, 0);

    final newNotes = _deepCopyNotes(state.notes);
    newNotes.remove(row * 9 + col);

    final action = EraseCell(row, col, previous, prevNotes);

    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: [...state.history, action],
    ));
  }

  void toggleNotesMode() {
    emit(state.copyWith(isNotesMode: !state.isNotesMode));
  }

  void useHint() {
    if (state.status != GameStatus.playing) return;
    if (!state.hasSelection) return;
    if (state.hintsRemaining <= 0) return;

    final row = state.selectedRow!;
    final col = state.selectedCol!;
    if (state.isGiven(row, col)) return;

    final correctValue = state.solution.get(row, col);
    final previous = state.board.get(row, col);
    if (previous == correctValue) return;

    final prevNotes = state.notesAt(row, col);
    final board = state.board.copy();
    board.set(row, col, correctValue);

    final newNotes = _deepCopyNotes(state.notes);
    newNotes.remove(row * 9 + col);
    final cleared = _clearRelatedNotes(newNotes, row, col, correctValue);

    final action = UseHint(row, col, correctValue, previous, prevNotes, cleared);

    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: [...state.history, action],
      hintsRemaining: state.hintsRemaining - 1,
      status: board.isSolved ? GameStatus.complete : null,
    ));

    if (board.isSolved) _timer?.cancel();
  }

  void undo() {
    if (state.status != GameStatus.playing) return;
    if (state.history.isEmpty) return;

    final action = state.history.last;
    final newHistory = state.history.sublist(0, state.history.length - 1);
    final board = state.board.copy();
    final newNotes = _deepCopyNotes(state.notes);

    switch (action) {
      case PlaceNumber(:final row, :final col, :final previousValue, :final previousNotes, :final clearedNotes):
        board.set(row, col, previousValue);
        if (previousNotes.isNotEmpty) {
          newNotes[row * 9 + col] = Set<int>.from(previousNotes);
        }
        _restoreClearedNotes(newNotes, clearedNotes);
      case PlaceNote(:final row, :final col, :final noteValue, :final wasAdded):
        final key = row * 9 + col;
        final current = Set<int>.from(newNotes[key] ?? {});
        if (wasAdded) {
          current.remove(noteValue);
        } else {
          current.add(noteValue);
        }
        if (current.isEmpty) {
          newNotes.remove(key);
        } else {
          newNotes[key] = current;
        }
      case EraseCell(:final row, :final col, :final previousValue, :final previousNotes):
        board.set(row, col, previousValue);
        if (previousNotes.isNotEmpty) {
          newNotes[row * 9 + col] = previousNotes;
        }
      case UseHint(:final row, :final col, :final previousValue, :final previousNotes, :final clearedNotes):
        board.set(row, col, previousValue);
        if (previousNotes.isNotEmpty) {
          newNotes[row * 9 + col] = Set<int>.from(previousNotes);
        }
        _restoreClearedNotes(newNotes, clearedNotes);
    }

    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: newHistory,
      hintsRemaining: action is UseHint ? state.hintsRemaining + 1 : null,
    ));
  }

  /// Returns how many of a digit are placed on the board (0-9).
  int countDigit(int value) {
    int count = 0;
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        if (state.board.get(r, c) == value) count++;
      }
    }
    return count;
  }

  /// Restores notes that were previously cleared by _clearRelatedNotes.
  void _restoreClearedNotes(Map<int, Set<int>> notes, Map<int, Set<int>> cleared) {
    for (final entry in cleared.entries) {
      notes.putIfAbsent(entry.key, () => {}).addAll(entry.value);
    }
  }

  /// Removes [value] from notes in related cells. Returns a map of
  /// what was cleared so undo can restore it.
  Map<int, Set<int>> _clearRelatedNotes(Map<int, Set<int>> notes, int row, int col, int value) {
    final cleared = <int, Set<int>>{};

    void clearKey(int key) {
      final set = notes[key];
      if (set != null && set.contains(value)) {
        cleared.putIfAbsent(key, () => {}).add(value);
        set.remove(value);
        if (set.isEmpty) notes.remove(key);
      }
    }

    // Same row
    for (int c = 0; c < 9; c++) {
      clearKey(row * 9 + c);
    }
    // Same column
    for (int r = 0; r < 9; r++) {
      clearKey(r * 9 + col);
    }
    // Same box
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        clearKey(r * 9 + c);
      }
    }

    return cleared;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
