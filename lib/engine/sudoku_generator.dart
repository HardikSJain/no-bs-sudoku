import 'dart:math';

import 'sudoku_board.dart';
import 'sudoku_solver.dart';

class SudokuGenerator {
  final SudokuSolver _solver = SudokuSolver();

  /// Generates a puzzle with the given difficulty.
  /// Uses [seed] for deterministic generation (e.g., daily puzzles).
  ({SudokuBoard puzzle, SudokuBoard solution}) generate({
    Difficulty difficulty = Difficulty.medium,
    int? seed,
  }) {
    final random = seed != null ? Random(seed) : Random();
    final (_, maxClues) = difficulty.clueRange;

    SudokuBoard? bestPuzzle;
    SudokuBoard? bestSolution;
    int bestClues = 81;

    // Retry with fresh boards if we can't reach the target clue count.
    // Each attempt uses the same Random sequence, so results are deterministic.
    for (int attempt = 0; attempt < 10; attempt++) {
      final solution = _generateSolvedBoard(random);
      final puzzle = _digHoles(solution, difficulty, random);
      if (puzzle.clueCount <= maxClues) {
        return (puzzle: puzzle, solution: solution);
      }
      if (puzzle.clueCount < bestClues) {
        bestPuzzle = puzzle;
        bestSolution = solution;
        bestClues = puzzle.clueCount;
      }
    }

    // Return the attempt that got closest to the target range
    return (puzzle: bestPuzzle!, solution: bestSolution!);
  }

  /// Difficulty rotation by day of week.
  /// Mon/Tue: easy, Wed/Thu: medium, Fri/Sat: hard, Sun: expert.
  static Difficulty dailyDifficulty(DateTime date) {
    return switch (date.weekday) {
      DateTime.monday || DateTime.tuesday => Difficulty.easy,
      DateTime.wednesday || DateTime.thursday => Difficulty.medium,
      DateTime.friday || DateTime.saturday => Difficulty.hard,
      _ => Difficulty.expert, // Sunday
    };
  }

  /// Generates a daily puzzle for the given date.
  /// Same date always produces the same puzzle.
  /// Difficulty rotates by day of week.
  ({SudokuBoard puzzle, SudokuBoard solution, Difficulty difficulty}) generateDaily({
    required DateTime date,
  }) {
    final difficulty = dailyDifficulty(date);
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final result = generate(difficulty: difficulty, seed: seed);
    return (puzzle: result.puzzle, solution: result.solution, difficulty: difficulty);
  }

  /// Generates a fully solved board using backtracking with random ordering.
  SudokuBoard _generateSolvedBoard(Random random) {
    final board = SudokuBoard.empty();

    bool fill(int index) {
      if (index == 81) return true;

      final r = index ~/ 9;
      final c = index % 9;

      final candidates = board.candidates(r, c).toList()..shuffle(random);

      for (final val in candidates) {
        board.set(r, c, val);
        if (fill(index + 1)) return true;
        board.set(r, c, 0);
      }

      return false;
    }

    fill(0);
    return board;
  }

  /// Removes clues from a solved board to create a puzzle.
  /// Uses 180-degree rotational symmetry in pass 1, then single-cell in pass 2.
  /// Ensures unique solvability after each removal.
  SudokuBoard _digHoles(
    SudokuBoard solution,
    Difficulty difficulty,
    Random random,
  ) {
    final puzzle = solution.copy();
    final (minClues, _) = difficulty.clueRange;
    final targetClues = minClues;

    // Build list of symmetric cell pairs to try removing
    final pairs = <List<(int, int)>>[];
    final visited = <int>{};

    // Create shuffled order for cell removal
    final indices = List.generate(81, (i) => i)..shuffle(random);

    for (final idx in indices) {
      if (visited.contains(idx)) continue;

      final r = idx ~/ 9;
      final c = idx % 9;
      final symR = 8 - r;
      final symC = 8 - c;
      final symIdx = symR * 9 + symC;

      visited.add(idx);
      visited.add(symIdx);

      if (idx == symIdx) {
        pairs.add([(r, c)]);
      } else {
        pairs.add([(r, c), (symR, symC)]);
      }
    }

    // Pass 1: symmetric pair removal
    for (final pair in pairs) {
      if (puzzle.clueCount <= targetClues) break;

      // Skip pairs where cells are already empty
      final filledCells =
          pair.where((p) => puzzle.get(p.$1, p.$2) != 0).toList();
      if (filledCells.isEmpty) continue;

      final removingCount = filledCells.length;

      // Don't go below minimum clues
      if (puzzle.clueCount - removingCount < minClues) continue;

      // Save values
      final saved =
          filledCells.map((p) => (p, puzzle.get(p.$1, p.$2))).toList();

      // Remove cells
      for (final (r, c) in filledCells) {
        puzzle.set(r, c, 0);
      }

      // Check unique solvability
      if (!_solver.hasUniqueSolution(puzzle)) {
        // Restore
        for (final (pos, val) in saved) {
          puzzle.set(pos.$1, pos.$2, val);
        }
      }
    }

    // Pass 2: symmetric pair removal with individual uniqueness fallback
    if (puzzle.clueCount > targetClues) {
      final pass2Indices = List.generate(81, (i) => i)..shuffle(random);
      final visited2 = <int>{};

      for (final idx in pass2Indices) {
        if (puzzle.clueCount <= targetClues) break;
        if (visited2.contains(idx)) continue;

        final r = idx ~/ 9;
        final c = idx % 9;
        final symR = 8 - r;
        final symC = 8 - c;
        final symIdx = symR * 9 + symC;

        visited2.add(idx);
        visited2.add(symIdx);

        // Collect filled cells in the symmetric pair
        final pair = <(int, int)>[];
        if (puzzle.get(r, c) != 0) pair.add((r, c));
        if (idx != symIdx && puzzle.get(symR, symC) != 0) pair.add((symR, symC));
        if (pair.isEmpty) continue;
        if (puzzle.clueCount - pair.length < minClues) continue;

        final saved = pair.map((p) => (p, puzzle.get(p.$1, p.$2))).toList();
        for (final (pr, pc) in pair) {
          puzzle.set(pr, pc, 0);
        }
        if (!_solver.hasUniqueSolution(puzzle)) {
          for (final (pos, val) in saved) {
            puzzle.set(pos.$1, pos.$2, val);
          }
        }
      }
    }

    return puzzle;
  }
}
