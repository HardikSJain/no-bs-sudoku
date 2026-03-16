import 'sudoku_board.dart';

/// Result of a solve attempt.
class SolveResult {
  /// The solved board, or null if unsolvable.
  final SudokuBoard? board;

  /// Number of solutions found (capped at 2 for uniqueness checking).
  final int solutionCount;

  /// Techniques used during solving (for difficulty rating).
  final Set<SolveTechnique> techniquesUsed;

  SolveResult({
    this.board,
    required this.solutionCount,
    this.techniquesUsed = const {},
  });

  bool get hasUniqueSolution => solutionCount == 1;
}

enum SolveTechnique {
  nakedSingle,
  hiddenSingle,
  backtracking,
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

  /// Solves using logic techniques first, then backtracking.
  /// Tracks which techniques were needed for difficulty rating.
  SolveResult solveWithTechniques(SudokuBoard puzzle) {
    final board = puzzle.copy();
    final techniques = <SolveTechnique>{};

    // Try logic-only solving first
    bool progress = true;
    while (progress) {
      progress = false;

      // Naked singles: a cell with only one candidate
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (board.get(r, c) != 0) continue;
          final cands = board.candidates(r, c);
          if (cands.isEmpty) {
            return SolveResult(solutionCount: 0, techniquesUsed: techniques);
          }
          if (cands.length == 1) {
            board.set(r, c, cands.first);
            techniques.add(SolveTechnique.nakedSingle);
            progress = true;
          }
        }
      }

      // Hidden singles: a value that can only go in one place in a unit
      progress = _applyHiddenSingles(board, techniques) || progress;
    }

    if (board.isSolved) {
      return SolveResult(
        board: board,
        solutionCount: 1,
        techniquesUsed: techniques,
      );
    }

    // Need backtracking
    techniques.add(SolveTechnique.backtracking);
    final result = _solveWithCount(board, maxSolutions: 2);
    return SolveResult(
      board: result.board,
      solutionCount: result.solutionCount,
      techniquesUsed: techniques,
    );
  }

  /// Rates difficulty based on techniques required to solve.
  /// Throws if the puzzle is unsolvable.
  Difficulty rateDifficulty(SudokuBoard puzzle) {
    final result = solveWithTechniques(puzzle);
    if (result.solutionCount == 0) {
      throw ArgumentError('Cannot rate difficulty of an unsolvable puzzle');
    }
    final techniques = result.techniquesUsed;
    final clues = puzzle.clueCount;

    if (techniques.contains(SolveTechnique.backtracking)) {
      return clues <= 25 ? Difficulty.expert : Difficulty.hard;
    }
    if (techniques.contains(SolveTechnique.hiddenSingle)) {
      return clues <= 29 ? Difficulty.hard : Difficulty.medium;
    }
    return Difficulty.easy;
  }

  /// Applies hidden singles across all units.
  bool _applyHiddenSingles(SudokuBoard board, Set<SolveTechnique> techniques) {
    bool progress = false;

    // Check rows
    for (int r = 0; r < 9; r++) {
      progress = _hiddenSingleInUnit(
            board,
            techniques,
            List.generate(9, (c) => (r, c)),
          ) ||
          progress;
    }

    // Check columns
    for (int c = 0; c < 9; c++) {
      progress = _hiddenSingleInUnit(
            board,
            techniques,
            List.generate(9, (r) => (r, c)),
          ) ||
          progress;
    }

    // Check boxes
    for (int br = 0; br < 9; br += 3) {
      for (int bc = 0; bc < 9; bc += 3) {
        progress = _hiddenSingleInUnit(
              board,
              techniques,
              [
                for (int r = br; r < br + 3; r++)
                  for (int c = bc; c < bc + 3; c++) (r, c),
              ],
            ) ||
            progress;
      }
    }

    return progress;
  }

  /// Finds hidden singles within a single unit (row/col/box).
  bool _hiddenSingleInUnit(
    SudokuBoard board,
    Set<SolveTechnique> techniques,
    List<(int, int)> unitCells,
  ) {
    bool progress = false;

    for (int val = 1; val <= 9; val++) {
      // Skip if value already placed in this unit
      if (unitCells.any((cell) => board.get(cell.$1, cell.$2) == val)) continue;

      // Find cells where this value can go
      final possibleCells = unitCells
          .where((cell) =>
              board.get(cell.$1, cell.$2) == 0 &&
              board.candidates(cell.$1, cell.$2).contains(val))
          .toList();

      if (possibleCells.isEmpty) continue;
      if (possibleCells.length == 1) {
        final (r, c) = possibleCells.first;
        board.set(r, c, val);
        techniques.add(SolveTechnique.hiddenSingle);
        progress = true;
      }
    }

    return progress;
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
