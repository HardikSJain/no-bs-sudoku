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

  /// Seeded candidates, by cell index. Empty when none are warranted.
  ///
  /// The scaffolding that sets up a fish or a chain is almost entirely
  /// *eliminations*, which leave no mark on the board itself — so without the
  /// notes the pattern the drill is about is simply invisible. That is the
  /// whole justification for seeding them, and it only holds when the
  /// scaffolding actually eliminated something.
  ///
  /// It does not hold for the singles. Getting to a naked single needs only
  /// placements, every one of them visible on the board, so seeded notes add
  /// nothing a player could not work out — except that one cell is left
  /// showing a single pencil mark, which is the answer, printed. Four of them
  /// on a measured board. The exercise is scanning; handing over the
  /// candidate grid is handing over the result of the scan.
  ///
  /// An elimination drill is always seeded whatever the scaffolding did,
  /// because the move it asks for is crossing a candidate out.
  final Map<int, Set<int>> notes;

  /// Whether the position needed notes to be readable at all.
  ///
  /// The hint engine must be told: it takes seeded notes as authoritative,
  /// and an unscaffolded drill has none to be authoritative about.
  bool get isScaffolded => notes.isNotEmpty;

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

    final board = grid.toBoard();
    return TrainerDrill(
      technique: technique,
      board: board,
      solution: solution,
      notes: _notesFor(grid, board, step),
      step: step,
    );
  }

  /// The candidates to hand the player, or none.
  ///
  /// All or nothing, per drill. Seeding only the cells the scaffolding
  /// narrowed would be worse than seeding none: an x-wing is spotted by
  /// reading one digit across the whole grid, and a grid pencilled in only
  /// where the engine had something to say is a grid that cannot be read.
  ///
  /// Two reasons to seed, and a drill needs only one of them.
  ///
  /// The move itself may be an elimination, in which case the candidates are
  /// not scenery — they are the thing being crossed out, and a drill that
  /// asks you to remove a mark that was never drawn cannot be played at all.
  ///
  /// Otherwise it comes down to whether the fast-forward narrowed anything
  /// below what the board already shows. If it did, the position cannot be
  /// read without the notes. If it did not — the whole singles tier, where
  /// the fast-forward is placements and nothing else — then the notes restate
  /// the board, and for a naked single that restatement is the answer,
  /// printed in the cell it is the answer to.
  static Map<int, Set<int>> _notesFor(
    CandidateGrid grid,
    SudokuBoard board,
    Deduction step,
  ) {
    final plain = CandidateGrid.fromBoard(board);
    final seeded = <int, Set<int>>{};
    var narrowed = false;
    for (final idx in grid.unsolvedCells) {
      if (grid.candidateCount(idx) == 0) continue;
      final candidates = grid.candidatesOf(idx).toSet();
      seeded[idx] = candidates;
      narrowed |= plain.candidatesOf(idx).any((d) => !candidates.contains(d));
    }
    final needed = step.kind == DeductionKind.elimination || narrowed;
    return needed ? seeded : const {};
  }
}
