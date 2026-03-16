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
  final List<int> solveTimes;
  final Set<SolveTechnique> techniques;

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

  /// Human-readable puzzle DNA description.
  String? get puzzleDna {
    if (techniques.isEmpty) return null;
    final parts = <String>[];
    if (techniques.contains(SolveTechnique.nakedSingle)) {
      parts.add('naked singles');
    }
    if (techniques.contains(SolveTechnique.hiddenSingle)) {
      parts.add('hidden singles');
    }
    if (techniques.contains(SolveTechnique.backtracking)) {
      parts.add('advanced logic');
    }
    if (parts.isEmpty) return null;
    return 'this puzzle needed ${parts.join(' + ')}.';
  }
}
