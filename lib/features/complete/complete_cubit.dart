import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/intelligence/velocity_profile.dart';
import '../../core/logger.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../engine/deduction/candidate_grid.dart';
import '../../engine/deduction/deduction_engine.dart';
import '../../engine/deduction/solve_path_analysis.dart';
import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_solver.dart';

class CompleteState {
  final double qualityScore;
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final Difficulty difficulty;
  final bool isDaily;
  final VelocityProfile? velocity;
  final bool isPersonalBest;
  final int currentStreak;
  final List<int> solveTimes;
  /// Seconds faster than the previous personal best. Null if no prior best.
  final int? pbDiffSeconds;
  /// Seconds faster than the user's average. Negative = slower than avg.
  final int? avgDiffSeconds;

  /// The puzzle's logical skeleton, or null when the player has not asked to
  /// see it. Off by default — a technique debrief is a payoff for the
  /// audience that wants one and an interruption for everyone else.
  final SolvePathAnalysis? solvePath;

  const CompleteState({
    required this.qualityScore,
    required this.timeSeconds,
    required this.hintsUsed,
    required this.mistakes,
    required this.difficulty,
    this.isDaily = false,
    this.velocity,
    this.isPersonalBest = false,
    this.currentStreak = 0,
    this.solveTimes = const [],
    this.pbDiffSeconds,
    this.avgDiffSeconds,
    this.solvePath,
  });

  /// Two writers now land on this state — the context load and the solve-path
  /// analysis — and they finish in either order. Rebuilding it by hand at
  /// each one is how a field gets dropped, which has already happened once in
  /// this codebase.
  CompleteState copyWith({
    VelocityProfile? velocity,
    bool? isPersonalBest,
    int? currentStreak,
    int? pbDiffSeconds,
    int? avgDiffSeconds,
    SolvePathAnalysis? solvePath,
  }) {
    return CompleteState(
      qualityScore: qualityScore,
      timeSeconds: timeSeconds,
      hintsUsed: hintsUsed,
      mistakes: mistakes,
      difficulty: difficulty,
      isDaily: isDaily,
      solveTimes: solveTimes,
      velocity: velocity ?? this.velocity,
      isPersonalBest: isPersonalBest ?? this.isPersonalBest,
      currentStreak: currentStreak ?? this.currentStreak,
      pbDiffSeconds: pbDiffSeconds ?? this.pbDiffSeconds,
      avgDiffSeconds: avgDiffSeconds ?? this.avgDiffSeconds,
      solvePath: solvePath ?? this.solvePath,
    );
  }
}

class CompleteCubit extends Cubit<CompleteState> {
  final PuzzleRecordRepository _records;
  final ProfileRepository _profiles;
  final PreferencesRepository _preferences;
  final SudokuBoard? _puzzle;

  CompleteCubit({
    required double qualityScore,
    required int timeSeconds,
    required int hintsUsed,
    required int mistakes,
    required Difficulty difficulty,
    required bool isDaily,
    required List<int> solveTimes,
    required PuzzleRecordRepository records,
    required ProfileRepository profiles,
    required PreferencesRepository preferences,
    SudokuBoard? puzzle,
  })  : _records = records,
        _profiles = profiles,
        _preferences = preferences,
        _puzzle = puzzle,
        super(CompleteState(
          qualityScore: qualityScore,
          timeSeconds: timeSeconds,
          hintsUsed: hintsUsed,
          mistakes: mistakes,
          difficulty: difficulty,
          isDaily: isDaily,
          solveTimes: solveTimes,
        )) {
    _loadContext();
    unawaited(_loadSolvePath());
  }

  /// Re-derives the solve path from the clues.
  ///
  /// Cheap — the ladder finishes a puzzle in about a millisecond — and it is
  /// deliberately recomputed rather than carried through the route, so the
  /// analysis always describes the puzzle rather than whatever the player
  /// happened to do to it.
  Future<void> _loadSolvePath() async {
    final puzzle = _puzzle;
    if (puzzle == null) return;
    final prefs = await _preferences.getPreferences();
    if (isClosed || !prefs.showSolvePath) return;

    final path = const DeductionEngine().solve(CandidateGrid.fromBoard(puzzle));
    if (isClosed || !path.complete) return;
    emit(state.copyWith(solvePath: SolvePathAnalysis.of(path)));
  }

  Future<void> _loadContext() async {
    // Velocity analysis (pure, no DB)
    final velocity = analyzeVelocity(state.solveTimes);

    // Contextual comparison — best-effort, falls back to defaults
    bool isPB = false;
    int streak = 0;
    int? pbDiff;
    int? avgDiff;

    try {
      final profile = await _profiles.getProfile();
      final records =
          await _records.getRecordsForDifficulty(state.difficulty.name);
      streak = profile.currentStreak;

      if (records.length >= 2) {
        final sorted = [...records]
          ..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
        if (sorted.first.timeSeconds == state.timeSeconds) {
          final diff = sorted[1].timeSeconds - state.timeSeconds;
          if (diff > 0) {
            isPB = true;
            pbDiff = diff;
            Log.personalBest(difficulty: state.difficulty.name, timeSeconds: state.timeSeconds);
          }
        }
      }

      if (records.length >= 3) {
        final avgTime = records.map((r) => r.timeSeconds).reduce((a, b) => a + b) / records.length;
        avgDiff = (avgTime - state.timeSeconds).round();
      }
    } catch (_) {
      // Storage read failed — show screen with defaults
    }

    if (isClosed) return;

    emit(state.copyWith(
      velocity: velocity,
      isPersonalBest: isPB,
      currentStreak: streak,
      pbDiffSeconds: pbDiff,
      avgDiffSeconds: avgDiff,
    ));
  }
}
