import '../../engine/deduction/deduction.dart';
import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_solver.dart';
import '../../features/game/game_state.dart';
import '../../features/game/technique_copy.dart';

/// Typed arguments for the /complete route.
class CompleteRouteArgs {
  final double qualityScore;
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final Difficulty difficulty;
  final bool isDaily;
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
    required this.solveTimes,
    this.techniques = const {},
    this.puzzle,
    this.history = const [],
  });

  /// What the puzzle actually asked of you, in one line.
  ///
  /// Named by the hardest technique the solve needed, which is the thing that
  /// gives a puzzle its character — listing all twelve would be noise. The
  /// old version could only ever report singles or "advanced logic", the
  /// latter meaning the solver had resorted to guessing; the engine no longer
  /// guesses, so that phrase has no successor and is gone.
  String? get puzzleDna {
    if (techniques.isEmpty) return null;
    final hardest =
        techniques.reduce((a, b) => a.index >= b.index ? a : b);
    return 'this one needed nothing past ${hardest.plural}.';
  }
}
