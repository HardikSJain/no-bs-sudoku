import '../sudoku_board.dart';
import 'candidate_grid.dart';
import 'deduction.dart';
import 'deduction_engine.dart';

/// A one-move drill: a position where the named technique is the move.
class TrainerDrill {
  const TrainerDrill({
    required this.technique,
    required this.board,
    required this.solution,
    required this.notes,
    required this.step,
  });

  final Technique technique;

  /// The position as the player sees it. Every filled cell here is presented
  /// as a clue — the scaffolding is part of the puzzle, not something they
  /// did, so it cannot be erased or scored against them.
  final SudokuBoard board;

  final SudokuBoard solution;

  /// Seeded candidates, by cell index.
  ///
  /// Not optional. The scaffolding that sets up a fish or a chain is almost
  /// entirely *eliminations*, which leave no mark on the board itself — so
  /// without the notes the pattern the drill is about is simply invisible.
  final Map<int, Set<int>> notes;

  /// The move being drilled.
  final Deduction step;
}

/// Builds one-move drills from a floor-targeted puzzle.
class TrainerDrillBuilder {
  const TrainerDrillBuilder([this._engine = const DeductionEngine()]);

  final DeductionEngine _engine;

  /// Takes a puzzle whose crux is [technique] and fast-forwards it to the
  /// moment that technique is needed.
  ///
  /// Digging at a technique's tier leaves the puzzle full of lower-tier work,
  /// so a swordfish drill would otherwise mean solving forty singles first.
  /// The fix has to be stated precisely, because "pre-solve until it applies"
  /// is ambiguous — at a lower-tier stall the applicable technique may be a
  /// same-tier sibling, since `fish` holds both x-wing and swordfish.
  ///
  /// The rule is: apply the fixpoint of the whole ladder *minus* the target
  /// technique, then stop. That works because the puzzle was built so it
  /// cannot be finished without the technique, so the reduced ladder must
  /// stall; sound rules make the fixpoint order-independent, so the stall is
  /// a single well-defined position; and the full ladder does finish the
  /// puzzle, so the technique must apply there.
  ///
  /// Returns null if the position does not behave as the crux test promised.
  TrainerDrill? build(
    Technique technique,
    SudokuBoard puzzle,
    SudokuBoard solution,
  ) {
    final grid = CandidateGrid.fromBoard(puzzle);
    final reduced = _engine.without(technique);

    // Fast-forward to the stall.
    for (int guard = 0; guard < 400; guard++) {
      final step = reduced.nextStep(grid, maxTier: technique.tier);
      if (step == null) break;
      DeductionEngine.apply(grid, step);
    }
    if (grid.isSolved || grid.isBroken) return null;

    // At the stall the target technique should be exactly what applies.
    final step = _engine.nextStep(grid, maxTier: technique.tier);
    if (step == null || step.technique != technique) return null;

    return TrainerDrill(
      technique: technique,
      board: grid.toBoard(),
      solution: solution,
      notes: {
        for (final idx in grid.unsolvedCells)
          if (grid.candidateCount(idx) > 0) idx: grid.candidatesOf(idx).toSet(),
      },
      step: step,
    );
  }
}
