import 'dart:async';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/intelligence/quality_score.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/storage_service.dart';
import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_generator.dart';
import '../../engine/sudoku_solver.dart';
import 'game_state.dart';

Map<int, Set<int>> _deepCopyNotes(Map<int, Set<int>> notes) =>
    {for (final e in notes.entries) e.key: Set<int>.from(e.value)};

class GameCubit extends Cubit<GameState> {
  Timer? _timer;

  // Velocity tracking
  final List<int> _cellPlacementDeltas = [];
  int _longestPause = 0;
  DateTime? _lastPlacementTime;
  int _undoCount = 0;
  bool _notesEverUsed = false;
  final List<int> _mistakeCells = [];

  GameCubit._({required GameState initial}) : super(initial);

  factory GameCubit.newGame({
    Difficulty difficulty = Difficulty.medium,
    int? seed,
  }) {
    final generator = SudokuGenerator();
    final result = generator.generate(difficulty: difficulty, seed: seed);
    final puzzleId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    return GameCubit._(
      initial: _buildState(
        result.puzzle,
        result.solution,
        puzzleId: puzzleId,
        difficulty: difficulty.name,
        isDaily: false,
      ),
    );
  }

  factory GameCubit.daily({required DateTime date}) {
    final generator = SudokuGenerator();
    final result = generator.generateDaily(date: date);
    final dateStr =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return GameCubit._(
      initial: _buildState(
        result.puzzle,
        result.solution,
        puzzleId: dateStr,
        difficulty: 'hard',
        isDaily: true,
      ),
    );
  }

  static GameState _buildState(
    SudokuBoard puzzle,
    SudokuBoard solution, {
    required String puzzleId,
    required String difficulty,
    required bool isDaily,
  }) {
    final givenCells = <int>{};
    for (int i = 0; i < 81; i++) {
      if (puzzle.get(i ~/ 9, i % 9) != 0) givenCells.add(i);
    }
    return GameState(
      puzzle: puzzle,
      board: puzzle.copy(),
      solution: solution,
      givenCells: givenCells,
      puzzleId: puzzleId,
      difficulty: difficulty,
      isDaily: isDaily,
    );
  }

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.status == GameStatus.playing) {
        emit(state.copyWith(
            elapsed: state.elapsed + const Duration(seconds: 1)));
      }
    });
    // Count as a started game (fire-and-forget)
    unawaited(StorageService.instance.incrementStarted());
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

    // Track velocity
    _recordPlacementTiming();

    // Track mistakes
    if (!isCorrect) {
      _mistakeCells.add(row * 9 + col);
    }

    final action =
        PlaceNumber(row, col, value, previous, prevNotes, cleared);

    final isSolved = board.isSolved;

    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: [...state.history, action],
      mistakeCount: isCorrect ? null : state.mistakeCount + 1,
      status: isSolved ? GameStatus.complete : null,
    ));

    if (isSolved) {
      _timer?.cancel();
      _onPuzzleComplete();
    }
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
    if (!state.isNotesMode) _notesEverUsed = true;
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

    // Track velocity for hints too
    _recordPlacementTiming();

    final action =
        UseHint(row, col, correctValue, previous, prevNotes, cleared);

    final isSolved = board.isSolved;

    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: [...state.history, action],
      hintsRemaining: state.hintsRemaining - 1,
      status: isSolved ? GameStatus.complete : null,
    ));

    if (isSolved) {
      _timer?.cancel();
      _onPuzzleComplete();
    }
  }

  void undo() {
    if (state.status != GameStatus.playing) return;
    if (state.history.isEmpty) return;

    _undoCount++;

    final action = state.history.last;
    final newHistory = state.history.sublist(0, state.history.length - 1);
    final board = state.board.copy();
    final newNotes = _deepCopyNotes(state.notes);

    switch (action) {
      case PlaceNumber(
          :final row,
          :final col,
          :final previousValue,
          :final previousNotes,
          :final clearedNotes
        ):
        board.set(row, col, previousValue);
        if (previousNotes.isNotEmpty) {
          newNotes[row * 9 + col] = Set<int>.from(previousNotes);
        }
        _restoreClearedNotes(newNotes, clearedNotes);
      case PlaceNote(
          :final row,
          :final col,
          :final noteValue,
          :final wasAdded
        ):
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
      case EraseCell(
          :final row,
          :final col,
          :final previousValue,
          :final previousNotes
        ):
        board.set(row, col, previousValue);
        if (previousNotes.isNotEmpty) {
          newNotes[row * 9 + col] = previousNotes;
        }
      case UseHint(
          :final row,
          :final col,
          :final previousValue,
          :final previousNotes,
          :final clearedNotes
        ):
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

  // ── Velocity tracking ──────────────────────────────────────────────

  void _recordPlacementTiming() {
    final now = DateTime.now();
    if (_lastPlacementTime != null) {
      final delta = now.difference(_lastPlacementTime!).inSeconds;
      _cellPlacementDeltas.add(delta);
      if (delta > 10 && delta > _longestPause) {
        _longestPause = delta;
      }
    }
    _lastPlacementTime = now;
  }

  void _onPuzzleComplete() {
    final score = QualityScore.compute(
      timeSeconds: state.elapsed.inSeconds,
      hints: 3 - state.hintsRemaining,
      mistakes: state.mistakeCount,
      undos: _undoCount,
      difficulty: state.difficulty,
    );

    final hintsUsed = 3 - state.hintsRemaining;
    final solveTimesStr = _cellPlacementDeltas.join(',');
    final mistakeCellsStr = _mistakeCells.join(',');

    final record = PuzzleRecordsCompanion.insert(
      puzzleId: state.puzzleId,
      difficulty: state.difficulty,
      isDaily: Value(state.isDaily),
      timeSeconds: state.elapsed.inSeconds,
      hintsUsed: Value(hintsUsed),
      mistakes: Value(state.mistakeCount),
      completedAt: DateTime.now(),
      solveTimes: Value(solveTimesStr),
      undosUsed: Value(_undoCount),
      usedNotes: Value(_notesEverUsed),
      longestPauseSeconds: Value(_longestPause),
      mistakeCells: Value(mistakeCellsStr),
      qualityScore: Value(score),
    );

    // Save to storage — await so reads on complete screen are consistent
    final storage = StorageService.instance;
    _saveComplete = Future(() async {
      await storage.saveRecord(record);
      await storage.updateStreak();
    });

    _completedQualityScore = score;
    _completedHintsUsed = hintsUsed;
  }

  /// Completes when record + streak writes have settled.
  /// Await this before navigating to the complete screen.
  Future<void> get saveComplete => _saveComplete ?? Future.value();
  Future<void>? _saveComplete;

  double _completedQualityScore = 0;
  int _completedHintsUsed = 0;

  double get qualityScore => _completedQualityScore;
  int get hintsUsed => _completedHintsUsed;
  int get undosUsed => _undoCount;
  List<int> get solveTimes => List.unmodifiable(_cellPlacementDeltas);

  // ── Helpers ────────────────────────────────────────────────────────

  void _restoreClearedNotes(
      Map<int, Set<int>> notes, Map<int, Set<int>> cleared) {
    for (final entry in cleared.entries) {
      notes.putIfAbsent(entry.key, () => {}).addAll(entry.value);
    }
  }

  Map<int, Set<int>> _clearRelatedNotes(
      Map<int, Set<int>> notes, int row, int col, int value) {
    final cleared = <int, Set<int>>{};

    void clearKey(int key) {
      final set = notes[key];
      if (set != null && set.contains(value)) {
        cleared.putIfAbsent(key, () => {}).add(value);
        set.remove(value);
        if (set.isEmpty) notes.remove(key);
      }
    }

    for (int c = 0; c < 9; c++) {
      clearKey(row * 9 + c);
    }
    for (int r = 0; r < 9; r++) {
      clearKey(r * 9 + col);
    }
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
