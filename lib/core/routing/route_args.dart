import '../../engine/deduction/deduction.dart';
import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_solver.dart';
import '../../features/game/game_state.dart';

/// Typed arguments for the /complete route.
class CompleteRouteArgs {
  final double qualityScore;
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final Difficulty difficulty;
  final bool isDaily;

  /// A typed-in grid. It has no difficulty, so no par and no quality score —
  /// the complete screen shows what it can and leaves out what would be
  /// invented.
  final bool isImported;
  final List<int> solveTimes;
  final Set<Technique> techniques;

  /// For solve replay: the puzzle clues and action history.
  final SudokuBoard? puzzle;
  final List<GameAction> history;

  const CompleteRouteArgs({
    required this.qualityScore,
    required this.timeSeconds,
    required this.hintsUsed,
    required this.mistakes,
    required this.difficulty,
    required this.isDaily,
    this.isImported = false,
    required this.solveTimes,
    this.techniques = const {},
    this.puzzle,
    this.history = const [],
  });

  // There was a `puzzleDna` line here — "this one needed nothing past hidden
  // singles." — printed under every solved puzzle, and it is gone.
  //
  // It named the hardest technique the solve needed, which sounds like
  // praise and reads as a verdict: the first thing you are told after
  // finishing is the smallest name for what you just did. It was also
  // unconditional, while the `showSolvePath` preference that looks like it
  // governs this actually gates the solve-path card. So there was no way to
  // turn it off.
  //
  // `techniques` stays — the solve-path card and technique mastery both need
  // it. Only the remark is gone.
}
