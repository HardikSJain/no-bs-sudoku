import 'deduction/deduction.dart';
import 'sudoku_board.dart';

/// Result of a solve attempt.
class SolveResult {
  /// The solved board, or null if unsolvable.
  final SudokuBoard? board;

  /// Number of solutions found (capped at 2 for uniqueness checking).
  final int solutionCount;

  /// True when counting stopped at its node budget rather than finishing.
  /// The solution count is then a lower bound, not an answer.
  final bool budgetExhausted;

  SolveResult({
    this.board,
    required this.solutionCount,
    this.budgetExhausted = false,
  });

  bool get hasUniqueSolution => solutionCount == 1;
}

enum Difficulty {
  easy,
  medium,
  hard,
  expert,

  /// The two deep tiers. Added *above* expert and never a redefinition of it
  /// — nobody has a personal best in them, no stats row moves, no existing
  /// label changes meaning.
  ///
  /// Unlike the four above, these are floor-targeted: a `fish` puzzle that
  /// did not actually require a fish would be a lie, and this is the audience
  /// least willing to be lied to.
  fish,
  chains;

  /// The four ceiling-based labels, in order.
  ///
  /// Most code that walks difficulties means these: they share the
  /// never-harder-than contract, they populate the main grid on home, and
  /// they are what a recommendation is allowed to move a player between.
  /// [values] additionally contains the deep tiers, which behave differently
  /// enough that reaching for it by reflex is usually a bug.
  static const List<Difficulty> classic = [easy, medium, hard, expert];

  /// The technique-defined tiers, entered deliberately and never by
  /// recommendation.
  static const List<Difficulty> deep = [fish, chains];

  bool get isDeep => this == Difficulty.fish || this == Difficulty.chains;

  /// The techniques that qualify as this tier's crux.
  List<Technique> get cruxTechniques => switch (this) {
        Difficulty.fish => const [Technique.xWing, Technique.swordfish],
        Difficulty.chains => const [
            Technique.xyWing,
            Technique.simpleColoring,
          ],
        _ => const [],
      };

  /// Target clue count range for each difficulty.
  (int, int) get clueRange => switch (this) {
        Difficulty.easy => (36, 38),
        Difficulty.medium => (30, 33),
        Difficulty.hard => (26, 29),
        Difficulty.expert => (22, 28),
        // Dug as deep as expert. The technique, not the clue count, is what
        // makes these hard.
        Difficulty.fish || Difficulty.chains => (22, 28),
      };

  /// The hardest tier a puzzle of this difficulty may require.
  ///
  /// A ceiling, never a floor: digging with ceiling T yields a distribution
  /// over tiers up to T, and that distribution is deliberately left alone.
  /// Forcing a floor would make every existing label harder than it is today
  /// — a `medium` that genuinely requires a pair is not the `medium` someone
  /// has been playing for months.
  ///
  /// `hard` and `expert` share a ceiling and are separated by clue count
  /// alone, exactly as they are today. The depth an enthusiast wants lives in
  /// the new deep tiers, not in a redefinition of these four.
  TechniqueTier get maxTier => switch (this) {
        Difficulty.easy => TechniqueTier.singles,
        Difficulty.medium => TechniqueTier.pairs,
        Difficulty.hard => TechniqueTier.intersections,
        Difficulty.expert => TechniqueTier.intersections,
        Difficulty.fish => TechniqueTier.fish,
        Difficulty.chains => TechniqueTier.chains,
      };

  /// Par time in seconds for quality scoring.
  int get parSeconds => switch (this) {
        Difficulty.easy => 600,
        Difficulty.medium => 900,
        Difficulty.hard => 1200,
        Difficulty.expert => 1800,
        Difficulty.fish => 2400,
        Difficulty.chains => 3000,
      };

  /// Short description for UI display.
  String get description => switch (this) {
        Difficulty.easy => 'good for warming up',
        Difficulty.medium => 'the sweet spot',
        Difficulty.hard => 'bring some focus',
        Difficulty.expert => 'no hand-holding',
        Difficulty.fish => 'needs a fish',
        Difficulty.chains => 'needs a chain',
      };

  /// Parse from name string, defaulting to medium.
  static Difficulty fromName(String name) =>
      Difficulty.values.firstWhere((d) => d.name == name, orElse: () => Difficulty.medium);
}

class SudokuSolver {
  /// Solves the board using constraint propagation + backtracking.
  /// Returns the solved board or null if no solution exists.
  SudokuBoard? solve(SudokuBoard puzzle) {
    final result = _solveWithCount(puzzle, maxSolutions: 1);
    return result.board;
  }

  /// Checks if the puzzle has exactly one solution.
  bool hasUniqueSolution(SudokuBoard puzzle) {
    return _solveWithCount(puzzle, maxSolutions: 2).hasUniqueSolution;
  }

  /// Returns true if the board has no conflicting pre-filled values.
  bool _isConsistent(SudokuBoard board) {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = board.get(r, c);
        if (v != 0 && !board.isValid(r, c, v)) return false;
      }
    }
    return true;
  }

  /// Counts solutions up to [maxSolutions] using backtracking.
  SolveResult _solveWithCount(
    SudokuBoard puzzle, {
    required int maxSolutions,
    int? nodeBudget,
  }) {
    // Quick check: reject boards with conflicting givens
    if (!_isConsistent(puzzle)) {
      return SolveResult(solutionCount: 0);
    }

    final board = puzzle.copy();
    SudokuBoard? firstSolution;
    int count = 0;
    int nodes = 0;
    bool exhausted = false;

    bool backtrack(int index) {
      // Counting solutions is exponential, and a grid somebody typed can be
      // far worse than one we generated — a nearly empty board has billions
      // of solutions and no reason to stop. The budget is what turns "hangs
      // forever" into an answer we can show.
      if (nodeBudget != null && ++nodes > nodeBudget) {
        exhausted = true;
        return true;
      }

      if (index == 81) {
        count++;
        firstSolution ??= board.copy();
        return count >= maxSolutions;
      }

      final r = index ~/ 9;
      final c = index % 9;

      if (board.get(r, c) != 0) {
        return backtrack(index + 1);
      }

      final cands = board.candidates(r, c);
      for (final val in cands) {
        board.set(r, c, val);
        if (backtrack(index + 1)) return true;
        board.set(r, c, 0);
      }

      return false;
    }

    backtrack(0);

    return SolveResult(
      board: firstSolution,
      solutionCount: count,
      budgetExhausted: exhausted,
    );
  }

  /// What a grid somebody typed in actually is.
  ///
  /// Deliberately not `hasUniqueSolution`. Section 4.1's shortcut — that a
  /// complete ladder solve proves uniqueness — holds only for puzzles this
  /// app generated. For a typed grid a stalled ladder proves nothing at all,
  /// so this does the real exponential count, bounded so it always answers.
  ImportAnalysis analyseImport(
    SudokuBoard puzzle, {
    int nodeBudget = 4000000,
  }) {
    final filled = puzzle.clueCount;
    if (filled == 0) return const ImportAnalysis(ImportVerdict.empty);
    if (!_isConsistent(puzzle)) {
      return const ImportAnalysis(ImportVerdict.contradictory);
    }

    final result =
        _solveWithCount(puzzle, maxSolutions: 2, nodeBudget: nodeBudget);

    if (result.budgetExhausted) {
      return const ImportAnalysis(ImportVerdict.budgetExhausted);
    }
    if (result.solutionCount == 0) {
      return const ImportAnalysis(ImportVerdict.unsolvable);
    }
    if (result.solutionCount > 1) {
      return const ImportAnalysis(ImportVerdict.manySolutions);
    }
    return ImportAnalysis(ImportVerdict.unique, solution: result.board);
  }
}

/// What happened when a typed grid was checked.
enum ImportVerdict {
  /// Exactly one answer. The only case that can be played.
  unique,

  /// Nothing entered yet.
  empty,

  /// A digit repeats in a row, column or box.
  contradictory,

  /// Consistent, but no arrangement completes it.
  unsolvable,

  /// More than one answer fits, so it is not a puzzle.
  manySolutions,

  /// The search ran past its budget. Says so rather than spinning.
  budgetExhausted,
}

class ImportAnalysis {
  const ImportAnalysis(this.verdict, {this.solution});

  final ImportVerdict verdict;

  /// Set only for [ImportVerdict.unique].
  final SudokuBoard? solution;

  bool get isPlayable => verdict == ImportVerdict.unique;
}
