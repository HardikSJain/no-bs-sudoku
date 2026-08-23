import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/daily_key.dart';
import '../../core/intelligence/quality_score.dart';
import '../../core/logger.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../engine/deduction/candidate_grid.dart';
import '../../engine/deduction/deduction.dart';
import '../../engine/deduction/deduction_engine.dart';
import '../../engine/deduction/units.dart';
import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_generator.dart';
import '../../engine/sudoku_solver.dart';
import '../../engine/deduction/trainer_drill.dart';
import 'game_history_codec.dart';
import 'hint_engine.dart';
import 'game_state.dart';

Map<int, Set<int>> _deepCopyNotes(Map<int, Set<int>> notes) =>
    {for (final e in notes.entries) e.key: Set<int>.from(e.value)};

class GameCubit extends Cubit<GameState> {
  Timer? _timer;

  // Velocity tracking
  final List<int> _cellPlacementDeltas = [];
  int _longestPause = 0;
  Duration? _lastPlacementElapsed;
  int _undoCount = 0;
  bool _notesEverUsed = false;
  final List<int> _mistakeCells = [];
  Set<Technique> _techniques = const {};

  /// GameCubit is the one consumer that legitimately needs all four
  /// repositories, so it takes the bundle rather than four parameters across
  /// five factories.
  final Repositories _repos;
  static const HintEngine _hints = HintEngine();

  /// The player's personal p90 inter-placement gap for this difficulty, or
  /// null until it has been loaded.
  int? _stuckThresholdSeconds;
  int _nudgesThisPuzzle = 0;
  bool _placedSinceLastNudge = true;

  /// Never nudge sooner than this, however fast the player usually is. A
  /// prompt after fifteen seconds of thinking is an interruption, not help.
  static const int _stuckFloorSeconds = 45;

  /// Used when there is not enough history to know what slow looks like for
  /// this player.
  static const int _stuckDefaultSeconds = 90;

  /// Three per puzzle. Past that it stops being a nudge and starts being the
  /// app playing for you.
  static const int _maxNudgesPerPuzzle = 3;

  GameCubit._({
    required Repositories repos,
    required GameState initial,
    Set<Technique> techniques = const {},
  })  : _repos = repos,
        _techniques = techniques,
        super(initial);

  factory GameCubit.newGame({
    required Repositories repos,
    Difficulty difficulty = Difficulty.medium,
    int? seed,
  }) {
    final generator = SudokuGenerator();
    final result = generator.generate(difficulty: difficulty, seed: seed);
    final puzzleId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    final techniques = _techniquesNeededBy(result.puzzle);
    return GameCubit._(
      repos: repos,
      initial: _buildState(
        result.puzzle,
        result.solution,
        puzzleId: puzzleId,
        difficulty: difficulty,
        isDaily: false,
      ),
      techniques: techniques,
    );
  }

  factory GameCubit.daily({
    required Repositories repos,
    required DateTime date,
  }) {
    final generator = SudokuGenerator();
    final result = generator.generateDaily(date: date);
    final dateStr = dailyPuzzleId(date);
    final techniques = _techniquesNeededBy(result.puzzle);
    return GameCubit._(
      repos: repos,
      initial: _buildState(
        result.puzzle,
        result.solution,
        puzzleId: dateStr,
        difficulty: result.difficulty,
        isDaily: true,
      ),
      techniques: techniques,
    );
  }

  /// Async factory that generates puzzle on a background isolate.
  static Future<GameCubit> newGameAsync({
    required Repositories repos,
    Difficulty difficulty = Difficulty.medium,
  }) async {
    final result = await Isolate.run(() {
      final generator = SudokuGenerator();
      final gen = generator.generate(difficulty: difficulty);
      final techniques = _techniquesNeededBy(gen.puzzle);
      return (puzzle: gen.puzzle, solution: gen.solution, techniques: techniques);
    });
    final puzzleId = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
    return GameCubit._(
      repos: repos,
      initial: _buildState(
        result.puzzle,
        result.solution,
        puzzleId: puzzleId,
        difficulty: difficulty,
        isDaily: false,
      ),
      techniques: result.techniques,
    );
  }

  /// A one-move drill on a named technique, generated on an isolate.
  ///
  /// Floor-targeted generation is slow enough to need one — a fish crux takes
  /// a couple of seconds and occasionally much longer. Returns null when the
  /// budget runs out; the caller says so rather than substituting a puzzle
  /// that lacks the lesson.
  static Future<GameCubit?> trainerAsync({
    required Repositories repos,
    required Technique technique,
  }) async {
    final result = await Isolate.run(() {
      final generator = SudokuGenerator();
      final generated =
          generator.generateTargeting(technique, attempts: 1200);
      if (generated == null) return null;
      final drill = const TrainerDrillBuilder()
          .build(technique, generated.puzzle, generated.solution);
      if (drill == null) return null;
      return (
        board: drill.board,
        solution: drill.solution,
        notes: drill.notes,
        step: drill.step,
      );
    });
    if (result == null) return null;

    final givens = <int>{
      for (int i = 0; i < 81; i++)
        if (result.board.get(i ~/ 9, i % 9) != 0) i,
    };
    return GameCubit._(
      repos: repos,
      initial: GameState(
        // The scaffolded position *is* the puzzle as posed, so every filled
        // cell is a clue. Nothing here was placed by the player, so nothing
        // here should be erasable or scored against them.
        puzzle: result.board,
        board: result.board.copy(),
        solution: result.solution,
        givenCells: givens,
        puzzleId: 'drill_${technique.name}_'
            '${DateTime.now().millisecondsSinceEpoch}',
        difficulty: _drillDifficulty(technique),
        notes: result.notes,
        drillTechnique: technique,
        activeDrillStep: result.step,
      ),
      techniques: {technique},
    );
  }

  /// A drill is not a graded solve, but the state needs a difficulty for par
  /// times and colours. The tier's nearest label is the honest choice.
  static Difficulty _drillDifficulty(Technique technique) =>
      switch (technique.tier) {
        TechniqueTier.singles => Difficulty.easy,
        TechniqueTier.pairs => Difficulty.medium,
        TechniqueTier.intersections => Difficulty.hard,
        TechniqueTier.fish => Difficulty.fish,
        TechniqueTier.chains => Difficulty.chains,
      };

  /// A puzzle the player typed or pasted in.
  ///
  /// The caller has already checked the grid has exactly one answer, which is
  /// why the solution is passed in rather than solved for again.
  factory GameCubit.imported({
    required Repositories repos,
    required SudokuBoard puzzle,
    required SudokuBoard solution,
  }) {
    final givens = <int>{
      for (int i = 0; i < 81; i++)
        if (puzzle.get(i ~/ 9, i % 9) != 0) i,
    };
    return GameCubit._(
      repos: repos,
      initial: GameState(
        puzzle: puzzle,
        board: puzzle.copy(),
        solution: solution,
        givenCells: givens,
        puzzleId: 'import_${DateTime.now().millisecondsSinceEpoch}',
        // An imported grid has no difficulty. medium is a placeholder for the
        // colour and the par time the UI asks for; nothing is scored against
        // it, because isImported skips the record entirely.
        difficulty: Difficulty.medium,
        isImported: true,
      ),
      techniques: _techniquesNeededBy(puzzle),
    );
  }

  /// Async factory that generates daily puzzle on a background isolate.
  static Future<GameCubit> dailyAsync({
    required Repositories repos,
    required DateTime date,
  }) async {
    final result = await Isolate.run(() {
      final generator = SudokuGenerator();
      final gen = generator.generateDaily(date: date);
      final techniques = _techniquesNeededBy(gen.puzzle);
      return (puzzle: gen.puzzle, solution: gen.solution, difficulty: gen.difficulty, techniques: techniques);
    });
    final dateStr = dailyPuzzleId(date);
    return GameCubit._(
      repos: repos,
      initial: _buildState(
        result.puzzle,
        result.solution,
        puzzleId: dateStr,
        difficulty: result.difficulty,
        isDaily: true,
      ),
      techniques: result.techniques,
    );
  }

  static GameState _buildState(
    SudokuBoard puzzle,
    SudokuBoard solution, {
    required String puzzleId,
    required Difficulty difficulty,
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

  int? _bestTimeSeconds;
  bool _pbPaceShown = false;

  void startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
    unawaited(_repos.profiles.incrementStarted());
    _loadPreferences();
    _loadBestTime();
    unawaited(_loadStuckThreshold());

    // Analytics + Crashlytics context
    Log.puzzleStarted(difficulty: state.difficulty.name, isDaily: state.isDaily);
    Log.setGameContext(
      puzzleId: state.puzzleId,
      difficulty: state.difficulty.name,
      isDaily: state.isDaily,
    );
  }

  Future<void> _loadBestTime() async {
    try {
      final best = await _repos.records.getBestRecord(state.difficulty.name);
      _bestTimeSeconds = best?.timeSeconds;
    } catch (_) {}
  }

  void _checkPbPace() {
    if (_pbPaceShown || _bestTimeSeconds == null) return;
    // Check at halfway point of PB time
    final halfway = _bestTimeSeconds! ~/ 2;
    if (state.elapsed.inSeconds != halfway) return;
    // Count how many cells are filled (excluding givens)
    int filled = 0;
    for (int i = 0; i < 81; i++) {
      if (state.board.get(i ~/ 9, i % 9) != 0 && !state.givenCells.contains(i)) {
        filled++;
      }
    }
    final totalToFill = 81 - state.givenCells.length;
    // If more than 40% filled at half the PB time, they're on pace
    if (totalToFill > 0 && filled / totalToFill > 0.4) {
      _pbPaceShown = true;
      emit(state.copyWith(isOnPbPace: true));
    }
  }

  void pauseTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void resumeTimer() {
    if (_timer != null || state.status != GameStatus.playing) return;
    // Coming back to the app counts as being present, so the clock restarts
    // from now rather than immediately reading as idle.
    _noteInteraction();
    // The same tick as everywhere else. This used to be a partial copy that
    // advanced the clock but skipped the pb check and the stuck nudge, so
    // both quietly stopped working after the first time the app was
    // backgrounded.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _loadPreferences() async {
    final prefs = await _repos.preferences.getPreferences();
    if (isClosed) return;
    emit(state.copyWith(
      highlightMatching: prefs.highlightMatching,
      showTimer: prefs.showTimer,
      autoRemoveNotes: prefs.autoRemoveNotes,
      mistakeLimit: prefs.mistakeLimit,
      digitFirstInput: prefs.digitFirstInput,
      hintsExplain: prefs.hintsExplain,
      flagMistakesInstantly: prefs.flagMistakesInstantly,
      nudgeWhenStuck: prefs.nudgeWhenStuck,
    ));
    // If the player already exceeded the limit (e.g. limit was lowered in
    // settings while away), end the game immediately rather than waiting for
    // the next wrong move to trigger an invisible freeze.
    if (prefs.mistakeLimit > 0 && state.mistakeCount >= prefs.mistakeLimit) {
      _timer?.cancel();
      Log.puzzleAbandoned(difficulty: state.difficulty.name, isDaily: state.isDaily);
      Log.clearGameContext();
      unawaited(_repos.savedGames.deleteSavedGame());
      emit(state.copyWith(status: GameStatus.abandoned));
    }
  }

  void selectCell(int row, int col) {
    _noteInteraction();
    if (state.status != GameStatus.playing) return;
    // Digit-first: if enabled and a digit is selected, place it immediately
    if (state.digitFirstInput && state.selectedDigit != null && !state.isGiven(row, col) && !state.isNotesMode) {
      emit(state.copyWith(
        selectedRow: () => row,
        selectedCol: () => col,
        completionFlashCells: {},
      ));
      placeNumber(state.selectedDigit!);
      return;
    }
    emit(state.copyWith(
      selectedRow: () => row,
      selectedCol: () => col,
      completionFlashCells: {},
    ));
  }

  /// Selects a digit from the number pad (enables digit-first input).
  /// If a cell is already selected, places the digit immediately.
  void selectDigit(int digit) {
    _noteInteraction();
    if (state.status != GameStatus.playing) return;
    emit(state.copyWith(
      selectedDigit: () => digit,
      completionFlashCells: {},
    ));
    // Place immediately if cell is selected
    if (state.hasSelection && !state.isGiven(state.selectedRow!, state.selectedCol!)) {
      placeNumber(digit);
    }
  }

  /// Auto-fills all valid pencil marks for every empty cell.
  void autoFillNotes() {
    _noteInteraction();
    if (state.status != GameStatus.playing) return;
    final prev = _deepCopyNotes(state.notes);
    final newNotes = _deepCopyNotes(state.notes);
    final grid = CandidateGrid.fromBoard(state.board);
    for (int i = 0; i < 81; i++) {
      final r = i ~/ 9;
      final c = i % 9;
      if (state.board.get(r, c) != 0) continue;
      final candidates = grid.candidatesOf(i).toSet();
      if (candidates.isNotEmpty) newNotes[i] = candidates;
    }
    emit(state.copyWith(
      notes: newNotes,
      history: [...state.history, AutoFillNotes(prev)],
      isNotesMode: false,
      completionFlashCells: {},
    ));
    _autoSave();
  }

  /// Returns cell indices for any row/col/box that just completed on [board].
  Set<int> _detectCompletedGroups(SudokuBoard board, int placedRow, int placedCol) {
    final cells = <int>{};
    // Check row
    bool rowDone = true;
    for (int c = 0; c < 9; c++) {
      if (board.get(placedRow, c) != solution.get(placedRow, c) || board.get(placedRow, c) == 0) {
        rowDone = false; break;
      }
    }
    if (rowDone) {
      for (int c = 0; c < 9; c++) { cells.add(placedRow * 9 + c); }
    }
    // Check col
    bool colDone = true;
    for (int r = 0; r < 9; r++) {
      if (board.get(r, placedCol) != solution.get(r, placedCol) || board.get(r, placedCol) == 0) {
        colDone = false; break;
      }
    }
    if (colDone) {
      for (int r = 0; r < 9; r++) { cells.add(r * 9 + placedCol); }
    }
    // Check box
    bool boxDone = true;
    final br = (placedRow ~/ 3) * 3;
    final bc = (placedCol ~/ 3) * 3;
    for (int r = br; r < br + 3 && boxDone; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (board.get(r, c) != solution.get(r, c) || board.get(r, c) == 0) {
          boxDone = false; break;
        }
      }
    }
    if (boxDone) {
      for (int r = br; r < br + 3; r++) {
        for (int c = bc; c < bc + 3; c++) { cells.add(r * 9 + c); }
      }
    }
    return cells;
  }

  SudokuBoard get solution => state.solution;

  void placeNumber(int value) {
    _noteInteraction();
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

    // Auto-remove this value from notes in same row/col/box (if preference enabled)
    Map<int, Set<int>> cleared = const {};
    if (isCorrect && state.autoRemoveNotes) {
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
    final newMistakes = isCorrect ? state.mistakeCount : state.mistakeCount + 1;

    // Check mistake limit
    final hitLimit = state.mistakeLimit > 0 && newMistakes >= state.mistakeLimit;

    // Detect group completions for flash animation
    final flashCells = isCorrect && !isSolved
        ? _detectCompletedGroups(board, row, col)
        : const <int>{};

    // Clear selectedDigit if this digit is now fully placed (all 9)
    int? newSelectedDigit = state.selectedDigit;
    if (isCorrect && state.selectedDigit == value) {
      int count = 0;
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (board.get(r, c) == value) count++;
        }
      }
      if (count >= 9) newSelectedDigit = null;
    }

    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: [...state.history, action],
      mistakeCount: isCorrect ? null : newMistakes,
      status: isSolved
          ? GameStatus.complete
          : hitLimit
              ? GameStatus.abandoned
              : null,
      completionFlashCells: flashCells,
      selectedDigit: () => newSelectedDigit,
    ));

    if (isSolved) {
      _timer?.cancel();
      _onPuzzleComplete();
    } else if (hitLimit) {
      _timer?.cancel();
      Log.puzzleAbandoned(difficulty: state.difficulty.name, isDaily: state.isDaily);
      Log.clearGameContext();
      unawaited(_repos.savedGames.deleteSavedGame());
    } else {
      _autoSave();
      _checkDrillComplete();
    }
  }

  void _toggleNote(int row, int col, int value) {
    _noteInteraction();
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
    _autoSave();
    _checkDrillComplete();
  }

  /// Returns true when something was actually erased, so the caller can skip
  /// the haptic instead of buzzing to confirm a no-op.
  bool erase() {
    _noteInteraction();
    if (state.status != GameStatus.playing) return false;
    if (!state.hasSelection) return false;

    final row = state.selectedRow!;
    final col = state.selectedCol!;
    if (state.isGiven(row, col)) return false;

    final previous = state.board.get(row, col);
    final prevNotes = state.notesAt(row, col);
    if (previous == 0 && prevNotes.isEmpty) return false;

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
    _autoSave();
    return true;
  }

  void toggleNotesMode() {
    _noteInteraction();
    if (!state.isNotesMode) _notesEverUsed = true;
    Log.notesToggled(enabled: !state.isNotesMode);
    emit(state.copyWith(isNotesMode: !state.isNotesMode));
    _autoSave();
  }

  /// Advances the hint one rung and returns what is now on show.
  ///
  /// The control is never dead: there is always a next nudge, including when
  /// the board is contradictory, which is the state a stuck player is most
  /// often actually in.
  HintResult useHint() {
    _noteInteraction();
    if (state.status != GameStatus.playing) return const HintNothing();

    final result = _hints.find(
      board: state.board,
      solution: state.solution,
      givens: state.givenCells,
      selected: state.selectedIndex,
      scaffoldNotes: state.isDrill ? state.notes : null,
    );
    if (result is HintNothing) return result;

    final found = result is HintStep ? result.deduction : null;
    final wrong = result is HintWrongDigit ? result.cells : const <int>[];

    // Same step as last time? Then this tap escalates it. A fresh step
    // restarts at the bottom rung — the alternative is the explanation
    // jumping across the board mid-sentence.
    final continuing = state.hasHint &&
        found == state.activeHint &&
        _sameCells(wrong, state.wrongCells);

    if (!continuing) {
      // With explanations off the button behaves as it always did: one tap,
      // one answer.
      final rung = state.hintsExplain ? HintRung.locate : HintRung.apply;
      emit(state.copyWith(
        activeHint: () => found,
        wrongCells: wrong,
        hintRung: rung,
        hintsUsed: state.hintsUsed + 1,
        hintDepthTotal: state.hintDepthTotal + rung.cost,
        hintWasUnprompted: false,
      ));
      Log.hintUsed(difficulty: state.difficulty.name, rung: rung.name);
      if (found != null) {
        _trackMasteryWrite(_repos.mastery.recordAssisted(found.technique));
      }
      if (rung == HintRung.apply) _applyHint(found, HintRung.locate);
      return result;
    }

    if (state.hintRung.isLast) return result;

    final previous = state.hintRung;
    final next = previous.next;
    // An unprompted nudge was free, so the first tap on it starts paying from
    // scratch rather than paying only the difference.
    final charge = state.hintWasUnprompted
        ? next.cost
        : next.cost - previous.cost;
    emit(state.copyWith(
      hintRung: next,
      // Escalating within one hint replaces its cost rather than adding to
      // it, so four taps on one step cost 6 and not 12.
      hintDepthTotal: state.hintDepthTotal + charge,
      hintsUsed: state.hintWasUnprompted ? state.hintsUsed + 1 : null,
      hintWasUnprompted: false,
    ));
    Log.hintUsed(difficulty: state.difficulty.name, rung: next.name);
    if (next == HintRung.apply) _applyHint(found, previous);
    return result;
  }

  static bool _sameCells(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Carries out the step. Placements write the digit; eliminations seed the
  /// notes they act on first, because rubbing candidates off a cell showing
  /// no notes teaches nothing.
  void _applyHint(Deduction? deduction, HintRung previousRung) {
    if (deduction == null) return;
    switch (deduction.kind) {
      case DeductionKind.placement:
        _applyHintPlacement(deduction, previousRung);
      case DeductionKind.elimination:
        _applyHintElimination(deduction, previousRung);
    }
  }

  /// The depth to roll back to if this apply is undone.
  int _depthBefore(HintRung previousRung) =>
      state.hintDepthTotal - HintRung.apply.cost + previousRung.cost;

  void _applyHintPlacement(Deduction deduction, HintRung previousRung) {
    final (idx, digit) = deduction.targets.first;
    final row = idx ~/ 9;
    final col = idx % 9;
    final rollback = _depthBefore(previousRung);

    final prevNotes = state.notesAt(row, col);
    final previous = state.board.get(row, col);
    final board = state.board.copy();
    board.set(row, col, digit);

    final newNotes = _deepCopyNotes(state.notes);
    newNotes.remove(idx);
    final cleared = _clearRelatedNotes(newNotes, row, col, digit);

    _recordPlacementTiming();

    final isSolved = board.isSolved;
    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: [
        ...state.history,
        UseHint(row, col, digit, previous, prevNotes, cleared,
            previousRungIndex: previousRung.index, previousDepth: rollback),
      ],
      status: isSolved ? GameStatus.complete : null,
      activeHint: () => null,
      wrongCells: const [],
    ));

    if (isSolved) {
      _timer?.cancel();
      _onPuzzleComplete();
    } else {
      _autoSave();
    }
  }

  void _applyHintElimination(Deduction deduction, HintRung previousRung) {
    final rollback = _depthBefore(previousRung);
    final prev = _deepCopyNotes(state.notes);
    final newNotes = _deepCopyNotes(state.notes);
    final grid = CandidateGrid.fromBoard(state.board);

    // Seed candidates for every cell this step touches that has no notes yet,
    // so the removal is something the player can actually watch happen.
    for (final idx in {
      ...deduction.cells,
      ...deduction.witnesses,
      ...?deduction.unit?.cells,
    }) {
      if (state.board.get(idx ~/ 9, idx % 9) != 0) continue;
      if ((newNotes[idx] ?? const {}).isNotEmpty) continue;
      final candidates = grid.candidatesOf(idx).toSet();
      if (candidates.isNotEmpty) newNotes[idx] = candidates;
    }

    for (final (idx, digit) in deduction.targets) {
      newNotes[idx]?.remove(digit);
      if (newNotes[idx]?.isEmpty ?? false) newNotes.remove(idx);
    }

    emit(state.copyWith(
      notes: newNotes,
      history: [
        ...state.history,
        ApplyElimination(prev,
            previousRungIndex: previousRung.index, previousDepth: rollback),
      ],
      activeHint: () => null,
      wrongCells: const [],
    ));
    _autoSave();
  }

  /// Live toggle for the coaching switches, so a change in settings takes
  /// effect on the puzzle already in progress rather than the next one.
  void setHintsExplain(bool value) =>
      emit(state.copyWith(hintsExplain: value));

  void setFlagMistakesInstantly(bool value) =>
      emit(state.copyWith(flagMistakesInstantly: value));

  void setNudgeWhenStuck(bool value) =>
      emit(state.copyWith(nudgeWhenStuck: value));

  /// Preview where a digit could go. Held while the pad key is pressed.
  void previewDigit(int? digit) {
    if (state.previewDigit == digit) return;
    emit(state.copyWith(previewDigit: () => digit));
  }

  /// Drops the current explanation. Called when the player moves on.
  void dismissHint() {
    if (!state.hasHint) return;
    emit(state.copyWith(activeHint: () => null, wrongCells: const []));
  }


  void undo() {
    _noteInteraction();
    if (state.status != GameStatus.playing) return;
    if (state.history.isEmpty) return;
    Log.undoUsed(difficulty: state.difficulty.name);

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
      case ApplyElimination(:final previousNotes):
        newNotes.clear();
        newNotes.addAll(previousNotes);
      case AutoFillNotes(:final previousNotes):
        newNotes.clear();
        newNotes.addAll(previousNotes);
    }

    // Undoing an applied hint puts the explanation back where it was rather
    // than dropping the player at the start of it. The deduction itself is
    // recomputed: the board is restored exactly, so the next look finds the
    // identical step.
    final (rolledRung, rolledDepth) = switch (action) {
      UseHint(:final previousRungIndex, :final previousDepth) => (
          HintRung.values[previousRungIndex],
          previousDepth
        ),
      ApplyElimination(:final previousRungIndex, :final previousDepth) => (
          HintRung.values[previousRungIndex],
          previousDepth
        ),
      _ => (state.hintRung, state.hintDepthTotal),
    };

    // Undoing a wrong placement must give the mistake back. Without this the
    // counter only ever climbs, so quality score and the mistake-limit rule
    // both punish a mistake the player already took back.
    int? restoredMistakes;
    if (action is PlaceNumber &&
        action.value != state.solution.get(action.row, action.col)) {
      restoredMistakes = state.mistakeCount > 0 ? state.mistakeCount - 1 : 0;
      final idx = action.row * 9 + action.col;
      final at = _mistakeCells.lastIndexOf(idx);
      if (at != -1) _mistakeCells.removeAt(at);
    }

    emit(state.copyWith(
      board: board,
      notes: newNotes,
      history: newHistory,
      hintRung: rolledRung,
      hintDepthTotal: rolledDepth,
      hintsUsed: action is UseHint || action is ApplyElimination
          ? state.hintsUsed - 1
          : null,
      mistakeCount: restoredMistakes,
      completionFlashCells: {},
    ));
    _autoSave();
  }

  // ── Velocity tracking ──────────────────────────────────────────────

  void _recordPlacementTiming() {
    // Measured from in-game elapsed, never wall clock. The timer pauses when
    // the app is backgrounded, so wall clock would record an overnight pause
    // as a 28800-second "thinking time" and poison both solveTimes and
    // longestPauseSeconds for every resumed puzzle.
    final now = state.elapsed;
    if (_lastPlacementElapsed != null) {
      final delta = (now - _lastPlacementElapsed!).inSeconds;
      _cellPlacementDeltas.add(delta);
      if (delta > 10 && delta > _longestPause) {
        _longestPause = delta;
      }
    }
    _lastPlacementElapsed = now;
    _placedSinceLastNudge = true;
  }

  /// Elapsed at the last thing the player actually did.
  Duration _lastInteraction = Duration.zero;

  /// How long the clock keeps running with nobody touching anything.
  ///
  /// Backgrounding already pauses it, but a phone left face-up on a desk is
  /// not backgrounded — and a puzzle left open for an afternoon was recording
  /// the afternoon. That made every time meaningless, and it fed straight
  /// into personal bests, the quality score's time term, and the
  /// inter-placement deltas the stuck nudge builds its threshold from.
  ///
  /// Ten minutes, not two: a genuinely hard grid can involve several minutes
  /// of staring without a tap, and stopping the clock on someone who is
  /// thinking would be the worse error.
  static const Duration _idleTimeout = Duration(minutes: 10);

  void _tick() {
    if (state.status != GameStatus.playing) return;
    if (state.elapsed - _lastInteraction >= _idleTimeout) return;
    emit(state.copyWith(elapsed: state.elapsed + const Duration(seconds: 1)));
    _checkPbPace();
    _checkStuck();
  }

  /// Marks the player as present. Anything they deliberately do counts.
  void _noteInteraction() => _lastInteraction = state.elapsed;

  /// True when the clock has stopped itself. Surfaced so the UI can say so
  /// rather than looking frozen.
  bool get isIdle =>
      state.elapsed - _lastInteraction >= _idleTimeout &&
      state.status == GameStatus.playing;

  /// Advances the clock by one second without waiting for one.
  @visibleForTesting
  void tickForTesting() => _tick();

  /// Completes once the stuck threshold has been read from storage. Until
  /// then no nudge can fire, so a test that does not wait races it.
  @visibleForTesting
  Future<void> get readyForTesting => _thresholdReady.future;

  final Completer<void> _thresholdReady = Completer<void>();

  /// Loads the personal threshold for this difficulty.
  Future<void> _loadStuckThreshold() async {
    final difficulty = state.difficulty.name;
    void done() {
      if (!_thresholdReady.isCompleted) _thresholdReady.complete();
    }

    final trusted = await _repos.records.trustedRecordCount(difficulty);
    if (isClosed) return done();
    if (trusted < 3) {
      _stuckThresholdSeconds = _stuckDefaultSeconds;
      done();
      return;
    }
    final deltas = await _repos.records.trustedSolveTimeDeltas(difficulty);
    if (isClosed) return done();
    if (deltas.length < 10) {
      _stuckThresholdSeconds = _stuckDefaultSeconds;
      done();
      return;
    }
    deltas.sort();
    final p90 = deltas[(deltas.length * 0.9).floor().clamp(0, deltas.length - 1)];
    _stuckThresholdSeconds = p90;
    done();
  }

  /// Offers the first rung, unasked, when the player has clearly stalled.
  ///
  /// Every condition has to hold: the switch is on, the pause beats both the
  /// player's own p90 and a hard floor, there is actually something to say,
  /// we have not already nudged three times, and something has been placed
  /// since the last nudge. That last one is what stops it firing again every
  /// minute at somebody who is content to sit and think.
  void _checkStuck() {
    if (!state.nudgeWhenStuck) return;
    if (state.hasHint) return;
    if (_nudgesThisPuzzle >= _maxNudgesPerPuzzle) return;
    if (!_placedSinceLastNudge) return;

    final threshold = _stuckThresholdSeconds;
    if (threshold == null) return;

    final since = state.elapsed - (_lastPlacementElapsed ?? Duration.zero);
    if (since.inSeconds < _stuckFloorSeconds) return;
    if (since.inSeconds < threshold) return;

    final result = _hints.find(
      board: state.board,
      solution: state.solution,
      givens: state.givenCells,
      selected: state.selectedIndex,
      scaffoldNotes: state.isDrill ? state.notes : null,
    );
    if (result is HintNothing) return;

    _nudgesThisPuzzle++;
    _placedSinceLastNudge = false;
    emit(state.copyWith(
      activeHint: () => result is HintStep ? result.deduction : null,
      wrongCells: result is HintWrongDigit ? result.cells : const [],
      hintRung: HintRung.locate,
      // Free. The player did not ask.
      hintWasUnprompted: true,
    ));
    Log.stuckNudge(difficulty: state.difficulty.name);
  }

  /// The empty cell with the fewest legal candidates — the easiest next move.
  /// A drill ends the moment its one move is made.
  ///
  /// Checked after any change to the board or notes, because the move is a
  /// placement for some techniques and an elimination for the rest.
  void _checkDrillComplete() {
    final drill = state.activeDrillStep;
    if (drill == null) return;
    if (state.status != GameStatus.playing) return;

    final done = switch (drill.kind) {
      DeductionKind.placement => drill.targets.every(
          (t) => state.board.get(t.$1 ~/ 9, t.$1 % 9) == t.$2),
      DeductionKind.elimination => drill.targets
          .every((t) => !(state.notes[t.$1] ?? const {}).contains(t.$2)),
    };
    if (!done) return;

    _timer?.cancel();
    emit(state.copyWith(status: GameStatus.complete));

    final technique = state.drillTechnique!;
    Log.drillCompleted(
      technique: technique.name,
      seconds: state.elapsed.inSeconds,
    );
    // The measurement. A drill is the only place pattern recognition is
    // cleanly observable — one known technique, one move, one outcome — so
    // this is what the mastery level is built from. Taking any hint makes it
    // an assisted attempt: the app pointed at the answer, which says nothing
    // about whether the player could find it.
    _trackMasteryWrite(_repos.mastery.recordDrill(
      technique,
      unaided: state.hintsUsed == 0,
      seconds: state.elapsed.inSeconds,
      at: DateTime.now(),
    ));
    _saveComplete = _masteryWrites;
  }

  void _onPuzzleComplete() {
    // Neither a drill nor an import is a graded solve.
    //
    // A drill is scaffolded and one move long, so it would drag every average
    // down and hand out personal bests measured in seconds. An import has no
    // difficulty at all, so no par time and no quality score — recording it
    // would put a made-up grade into exactly the data the timing and quality
    // work existed to repair.
    if (!state.isScored) return;

    final score = QualityScore.compute(
      timeSeconds: state.elapsed.inSeconds,
      hintDepthTotal: state.hintDepthTotal,
      mistakes: state.mistakeCount,
      undos: _undoCount,
      difficulty: state.difficulty,
    );

    final hintsUsed = state.hintsUsed;

    Log.puzzleCompleted(
      difficulty: state.difficulty.name,
      isDaily: state.isDaily,
      timeSeconds: state.elapsed.inSeconds,
      qualityScore: score,
      hints: hintsUsed,
      mistakes: state.mistakeCount,
    );
    Log.clearGameContext();

    final solveTimesStr = _cellPlacementDeltas.join(',');
    final mistakeCellsStr = _mistakeCells.join(',');

    // Weak but honest: the puzzle needed these, which is not the same as the
    // player having spotted them. It is what stops the library reading "not
    // met yet" for someone fifty pointing pairs deep.
    _trackMasteryWrite(_repos.mastery.recordEncountered(_techniques));

    final record = PuzzleRecordsCompanion.insert(
      puzzleId: state.puzzleId,
      difficulty: state.difficulty.name,
      isDaily: Value(state.isDaily),
      timeSeconds: state.elapsed.inSeconds,
      hintsUsed: Value(hintsUsed),
      mistakes: Value(state.mistakeCount),
      completedAt: DateTime.now(),
      solveTimes: Value(solveTimesStr),
      undosUsed: Value(_undoCount),
      // These deltas came from state.elapsed, so they are safe to pool.
      timingVersion: const Value(2),
      formulaVersion: Value(QualityScore.formulaVersion),
      usedNotes: Value(_notesEverUsed),
      longestPauseSeconds: Value(_longestPause),
      mistakeCells: Value(mistakeCellsStr),
      qualityScore: Value(score),
    );

    // Save to storage — await so reads on complete screen are consistent
    final repos = _repos;
    _saveComplete = Future(() async {
      try {
        await repos.records.saveRecord(record);
        await repos.profiles.updateStreak();
        await repos.savedGames.deleteSavedGame();
        NotificationService.onPuzzleCompleted(
          records: _repos.records,
          profiles: _repos.profiles,
        );
      } catch (_) {
        // DB write failed — score is still computed in memory,
        // complete screen will show it even if record isn't persisted.
        _saveFailed = true;
        Log.error('_onPuzzleComplete save failed', tag: 'game');
      }
    });

    _completedQualityScore = score;
    _completedHintsUsed = hintsUsed;
  }

  /// Completes when record + streak writes have settled.
  /// Await this before navigating to the complete screen.
  Future<void> get saveComplete => _saveComplete ?? Future.value();
  Future<void>? _saveComplete;

  bool _saveFailed = false;
  double _completedQualityScore = 0;
  int _completedHintsUsed = 0;

  bool get saveFailed => _saveFailed;
  Set<Technique> get techniques => _techniques;
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

    // The cells a placement can affect are exactly this cell's peers, which
    // units.dart already has precomputed. Three hand-rolled loops here was a
    // fourth copy of the box arithmetic.
    for (final peer in Units.peersOf[row * 9 + col]) {
      clearKey(peer);
    }

    return cleared;
  }

  // ── Game save/restore ───────────────────────────────────────────

  /// Save current game state to drift. Call after meaningful actions.
  Future<void> saveCurrentGame() async {
    if (state.status != GameStatus.playing) return;

    try {
      final notesJson = <String, List<int>>{};
      for (final entry in state.notes.entries) {
        notesJson[entry.key.toString()] = entry.value.toList();
      }

      await _repos.savedGames.saveGame(SavedGamesCompanion.insert(
        puzzleId: state.puzzleId,
        difficulty: state.difficulty.name,
        isDaily: state.isDaily,
        givenCells: state.puzzle.toFlatString(),
        solutionCells: state.solution.toFlatString(),
        boardCells: state.board.toFlatString(),
        notes: jsonEncode(notesJson),
        elapsedSeconds: state.elapsed.inSeconds,
        // Dead column, NOT NULL with no default. See app_database.dart.
        hintsRemaining: 0,
        hintsUsed: Value(state.hintsUsed),
        hintDepthTotal: Value(state.hintDepthTotal),
        mistakeCount: state.mistakeCount,
        isNotesMode: state.isNotesMode,
        savedAt: DateTime.now(),
        history: Value(GameHistoryCodec.encode(state.history)),
        placementDeltas: Value(_cellPlacementDeltas.join(',')),
        mistakeCells: Value(_mistakeCells.join(',')),
        undoCount: Value(_undoCount),
        usedNotes: Value(_notesEverUsed),
        longestPauseSeconds: Value(_longestPause),
        techniques: Value(_techniques.map((t) => t.name).join(',')),
      ));
    } catch (e) {
      Log.error('saveCurrentGame failed', tag: 'game', error: e);
    }
  }

  Timer? _autoSaveDebounce;

  /// Autosave fires on every placement, note toggle, erase and mode toggle,
  /// and each one rewrites the entire payload — now including the history
  /// blob. Coalesce bursts instead of rewriting per keystroke.
  void _autoSave() {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = Timer(const Duration(milliseconds: 250), () {
      unawaited(saveCurrentGame());
    });
  }

  /// Writes immediately, cancelling any pending debounce.
  ///
  /// Must be called when the app is backgrounded — otherwise the trailing
  /// debounce never fires and the last action before leaving is lost, which
  /// is the exact failure this whole change exists to fix.
  Future<void> flushSave() async {
    _autoSaveDebounce?.cancel();
    _autoSaveDebounce = null;
    await saveCurrentGame();
  }

  /// Restore game from a saved state.
  static GameCubit fromSaved(SavedGame saved, Repositories repos) {
    try {
      final puzzle = SudokuBoard.fromFlatString(saved.givenCells);
      final solution = SudokuBoard.fromFlatString(saved.solutionCells);
      final board = SudokuBoard.fromFlatString(saved.boardCells);

      final givenCells = <int>{};
      for (int i = 0; i < 81; i++) {
        if (puzzle.get(i ~/ 9, i % 9) != 0) givenCells.add(i);
      }

      // Deserialize notes
      final notesMap = <int, Set<int>>{};
      final notesJson = jsonDecode(saved.notes) as Map<String, dynamic>;
      for (final entry in notesJson.entries) {
        final key = int.parse(entry.key);
        final values = (entry.value as List).cast<int>().toSet();
        if (values.isNotEmpty) notesMap[key] = values;
      }

      final difficulty = Difficulty.fromName(saved.difficulty);
      Log.puzzleResumed(
        difficulty: difficulty.name,
        isDaily: saved.isDaily,
        elapsedSeconds: saved.elapsedSeconds,
      );
      final cubit = GameCubit._(
        repos: repos,
        initial: GameState(
          puzzle: puzzle,
          board: board,
          solution: solution,
          givenCells: givenCells,
          puzzleId: saved.puzzleId,
          difficulty: difficulty,
          isDaily: saved.isDaily,
          notes: notesMap,
          elapsed: Duration(seconds: saved.elapsedSeconds),
          hintsUsed: saved.hintsUsed,
          hintDepthTotal: saved.hintDepthTotal,
          mistakeCount: saved.mistakeCount,
          isNotesMode: saved.isNotesMode,
        ),
      );
      // ── recoverable fields ──────────────────────────────────────────
      // Everything below degrades independently. A corrupt history blob costs
      // the undo stack, never the puzzle — the board and notes above are the
      // irreplaceable part. The old code wrapped all of it in one catch that
      // responded to any failure by deleting the save and handing back a fresh
      // medium game, so one bad field threw away a 40-minute expert puzzle.
      cubit._history0(GameHistoryCodec.decode(saved.history));
      cubit._cellPlacementDeltas.addAll(_csvInts(saved.placementDeltas));
      cubit._mistakeCells.addAll(_csvInts(saved.mistakeCells));
      cubit._undoCount = saved.undoCount;
      cubit._notesEverUsed = saved.usedNotes;
      cubit._longestPause = saved.longestPauseSeconds;
      cubit._techniques = _csvTechniques(saved.techniques);

      return cubit;
    } catch (e) {
      // Only the required fields above can land here: board, solution, notes.
      // Without those there is no game to restore.
      Log.error('fromSaved: unrecoverable save', tag: 'game', error: e);
      unawaited(repos.savedGames.deleteSavedGame());
      return GameCubit.newGame(repos: repos);
    }
  }

  /// Seeds the restored undo stack without emitting a state change.
  void _history0(List<GameAction> history) {
    if (history.isEmpty) return;
    emit(state.copyWith(history: history));
  }

  static List<int> _csvInts(String raw) {
    if (raw.isEmpty) return const [];
    return raw
        .split(',')
        .map(int.tryParse)
        .whereType<int>()
        .toList(growable: false);
  }

  /// The techniques a solve of [puzzle] actually needs.
  ///
  /// Replaces the solver's old three-value answer, which could only ever say
  /// naked single, hidden single, or "backtracking" — the last meaning it had
  /// given up and guessed. The engine never guesses, so the answer is now the
  /// real one.
  static Set<Technique> _techniquesNeededBy(SudokuBoard puzzle) {
    const engine = DeductionEngine();
    final path = engine.solve(CandidateGrid.fromBoard(puzzle));
    return {for (final step in path.steps) step.technique};
  }

  static Set<Technique> _csvTechniques(String raw) {
    if (raw.isEmpty) return const {};
    final byName = {for (final t in Technique.values) t.name: t};
    // Names written by an older build no longer map to anything; dropping
    // them costs the complete screen one line, which beats failing a restore.
    return raw.split(',').map((n) => byName[n]).whereType<Technique>().toSet();
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    _autoSaveDebounce?.cancel();
    // Mastery writes are fired without awaiting so a hint tap stays instant.
    // Letting them outlive the cubit means they can land after the database
    // has gone, which is a crash in tests and a lost write in the app.
    await _masteryWrites;
    return super.close();
  }

  /// Serialised so two increments to the same technique cannot read the same
  /// stale row and both write the same value.
  Future<void> _masteryWrites = Future.value();

  void _trackMasteryWrite(Future<void> work) {
    _masteryWrites = _masteryWrites.then((_) => work).catchError((Object e) {
      // Mastery is a nice-to-have; losing one increment must never take a
      // puzzle down with it.
      Log.warn('mastery write failed: $e', tag: 'mastery');
    });
  }

  /// Completes once every pending mastery write has landed.
  @visibleForTesting
  Future<void> get masteryWritten => _masteryWrites;
}
