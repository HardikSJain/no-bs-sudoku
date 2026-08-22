import '../../engine/deduction/candidate_grid.dart';
import '../../engine/deduction/deduction.dart';
import '../../engine/deduction/deduction_engine.dart';
import '../../engine/sudoku_board.dart';

/// How far a hint has been pushed. Escalates one step per tap.
///
/// Written H1-H4 to keep them distinct from the delivery waves R0-R5.
enum HintRung {
  /// Names the unit and nothing else: "there's something in box 4."
  locate,

  /// Highlights the cell. No digit, no technique name.
  narrow,

  /// Names the technique and highlights the cells that prove it.
  explain,

  /// Does it — places the digit, or writes the eliminations in.
  apply;

  HintRung get next =>
      this == HintRung.apply ? this : HintRung.values[index + 1];

  bool get isLast => this == HintRung.apply;

  /// What reaching this rung costs against quality. A gentle nudge should not
  /// cost what a full reveal costs.
  int get cost => switch (this) {
        HintRung.locate => 1,
        HintRung.narrow => 2,
        HintRung.explain => 3,
        HintRung.apply => 6,
      };
}

/// What the hint system found to say.
sealed class HintResult {
  const HintResult();
}

/// Something already on the board is wrong.
///
/// This has to come before the ladder, not after. `placeNumber` writes a
/// digit whether or not it is right, so the moment a player makes a mistake
/// the grid is contradictory and every technique has nothing to return. Left
/// unhandled, the hint button would go silent exactly when a stuck player
/// needs it most — strictly worse than the old behaviour, which at least
/// revealed the answer.
class HintWrongDigit extends HintResult {
  const HintWrongDigit(this.cells);

  /// Every filled cell that disagrees with the solution, ascending. Only the
  /// first is pointed at; the rest are why the count can be honest.
  final List<int> cells;
}

/// A real next step.
class HintStep extends HintResult {
  const HintStep(this.deduction, {required this.honoursSelection});

  final Deduction deduction;

  /// False when the player had a cell selected but nothing could be proven
  /// there yet, so this step is somewhere else. Beginners do not know that
  /// not every empty cell is solvable at any given moment, and saying so is
  /// the teaching moment.
  final bool honoursSelection;
}

/// Nothing to say: the board is finished, or no rule applies.
class HintNothing extends HintResult {
  const HintNothing();
}

/// Decides what to tell a player who asks for help.
///
/// Board-scoped but selection-aware. Holds no state: the grid is rebuilt from
/// the board on every request and never cached, because a cached grid drifts
/// from what the player is looking at and would explain a position that is
/// not on screen — silent, and indistinguishable from the engine being wrong.
class HintEngine {
  const HintEngine([this._engine = const DeductionEngine()]);

  final DeductionEngine _engine;

  /// [selected] is the player's chosen cell index, or null.
  ///
  /// [scaffoldNotes] is set only for a technique drill, where the position
  /// was reached partly by eliminating and those eliminations live nowhere
  /// but the notes. Ordinary play must not pass the player's own notes here:
  /// they are frequently wrong or half-finished, and a hint has to describe
  /// the real position rather than the player's picture of it.
  HintResult find({
    required SudokuBoard board,
    required SudokuBoard solution,
    required Set<int> givens,
    int? selected,
    Map<int, Set<int>>? scaffoldNotes,
  }) {
    final wrong = _wrongCells(board, solution);
    if (wrong.isNotEmpty) return HintWrongDigit(wrong);

    final grid = scaffoldNotes == null
        ? CandidateGrid.fromBoard(board)
        : CandidateGrid.fromBoardAndNotes(board, scaffoldNotes);

    // A selection only counts if it is a cell the player could still fill.
    // A given, or one already correct, falls through to the board-wide step
    // rather than reporting a problem the player does not have.
    final usable = selected != null &&
        !givens.contains(selected) &&
        board.get(selected ~/ 9, selected % 9) == 0;

    if (usable) {
      final here = _engine.placementFor(grid, selected);
      if (here != null) return HintStep(here, honoursSelection: true);
    }

    final anywhere = _engine.nextStep(grid);
    if (anywhere == null) return const HintNothing();

    // Only claim we ignored the selection when the player actually made one
    // that we could have honoured and could not.
    return HintStep(anywhere, honoursSelection: !usable);
  }

  /// Filled cells that disagree with the solution, ascending.
  static List<int> _wrongCells(SudokuBoard board, SudokuBoard solution) {
    final wrong = <int>[];
    for (int i = 0; i < 81; i++) {
      final placed = board.get(i ~/ 9, i % 9);
      if (placed != 0 && placed != solution.get(i ~/ 9, i % 9)) wrong.add(i);
    }
    return wrong;
  }
}
