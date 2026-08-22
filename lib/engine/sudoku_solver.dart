import 'deduction/deduction.dart';
import 'sudoku_board.dart';

/// Result of a solve attempt.
class SolveResult {
  /// The solved board, or null if unsolvable.
  final SudokuBoard? board;

  /// Number of solutions found (capped at 2 for uniqueness checking).
  final int solutionCount;

  SolveResult({
    this.board,
    required this.solutionCount,
  });

  bool get hasUniqueSolution => solutionCount == 1;
}

enum Difficulty {
  easy,
  medium,
  hard,
  expert;

  /// Target clue count range for each difficulty.
  (int, int) get clueRange => switch (this) {
        Difficulty.easy => (36, 38),
        Difficulty.medium => (30, 33),
        Difficulty.hard => (26, 29),
        Difficulty.expert => (22, 28),
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
      };

  /// Par time in seconds for quality scoring.
  int get parSeconds => switch (this) {
        Difficulty.easy => 600,
        Difficulty.medium => 900,
        Difficulty.hard => 1200,
        Difficulty.expert => 1800,
      };

  /// Short description for UI display.
  String get description => switch (this) {
        Difficulty.easy => 'good for warming up',
        Difficulty.medium => 'the sweet spot',
        Difficulty.hard => 'bring some focus',
        Difficulty.expert => 'no hand-holding',
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
  SolveResult _solveWithCount(SudokuBoard puzzle, {required int maxSolutions}) {
    // Quick check: reject boards with conflicting givens
    if (!_isConsistent(puzzle)) {
      return SolveResult(solutionCount: 0);
    }

    final board = puzzle.copy();
    SudokuBoard? firstSolution;
    int count = 0;

    bool backtrack(int index) {
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
    );
  }
}
