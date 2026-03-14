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

    // Retry with fresh boards if we can't reach the target clue count.
    // Each attempt uses the same Random sequence, so results are deterministic.
    for (int attempt = 0; attempt < 10; attempt++) {
      final solution = _generateSolvedBoard(random);
      final puzzle = _digHoles(solution, difficulty, random);
      if (puzzle.clueCount <= maxClues) {
        return (puzzle: puzzle, solution: solution);
      }
    }

    // Fallback: return the last attempt even if slightly above target
    final solution = _generateSolvedBoard(random);
    final puzzle = _digHoles(solution, difficulty, random);
    return (puzzle: puzzle, solution: solution);
  }

  /// Generates a daily puzzle for the given date.
  /// Same date always produces the same puzzle.
  ({SudokuBoard puzzle, SudokuBoard solution}) generateDaily({
    required DateTime date,
    Difficulty difficulty = Difficulty.hard,
  }) {
    final seed = date.year * 10000 + date.month * 100 + date.day;
    return generate(difficulty: difficulty, seed: seed);
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

    // Pass 2: single-cell removal to reach target
    if (puzzle.clueCount > targetClues) {
      final singleIndices = List.generate(81, (i) => i)..shuffle(random);
      for (final idx in singleIndices) {
        if (puzzle.clueCount <= targetClues) break;

        final r = idx ~/ 9;
        final c = idx % 9;
        final val = puzzle.get(r, c);
        if (val == 0) continue;

        puzzle.set(r, c, 0);
        if (!_solver.hasUniqueSolution(puzzle)) {
          puzzle.set(r, c, val);
        }
      }
    }

    return puzzle;
  }
}
