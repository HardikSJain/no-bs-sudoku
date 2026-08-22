import 'package:flutter_test/flutter_test.dart';
import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

// A known valid puzzle (easy — solvable with naked + hidden singles)
final _easyPuzzle = SudokuBoard([
  5, 3, 0, 0, 7, 0, 0, 0, 0,
  6, 0, 0, 1, 9, 5, 0, 0, 0,
  0, 9, 8, 0, 0, 0, 0, 6, 0,
  8, 0, 0, 0, 6, 0, 0, 0, 3,
  4, 0, 0, 8, 0, 3, 0, 0, 1,
  7, 0, 0, 0, 2, 0, 0, 0, 6,
  0, 6, 0, 0, 0, 0, 2, 8, 0,
  0, 0, 0, 4, 1, 9, 0, 0, 5,
  0, 0, 0, 0, 8, 0, 0, 7, 9,
]);

final _easySolution = SudokuBoard([
  5, 3, 4, 6, 7, 8, 9, 1, 2,
  6, 7, 2, 1, 9, 5, 3, 4, 8,
  1, 9, 8, 3, 4, 2, 5, 6, 7,
  8, 5, 9, 7, 6, 1, 4, 2, 3,
  4, 2, 6, 8, 5, 3, 7, 9, 1,
  7, 1, 3, 9, 2, 4, 8, 5, 6,
  9, 6, 1, 5, 3, 7, 2, 8, 4,
  2, 8, 7, 4, 1, 9, 6, 3, 5,
  3, 4, 5, 2, 8, 6, 1, 7, 9,
]);

void main() {
  late SudokuSolver solver;

  setUp(() {
    solver = SudokuSolver();
  });

  group('SudokuSolver.solve', () {
    test('solves a known easy puzzle correctly', () {
      final result = solver.solve(_easyPuzzle);
      expect(result, isNotNull);
      expect(result!, equals(_easySolution));
    });

    test('returns null for an invalid puzzle', () {
      // Two 5s in the first row — unsolvable
      final invalid = SudokuBoard.empty();
      invalid.set(0, 0, 5);
      invalid.set(0, 1, 5);
      final result = solver.solve(invalid);
      expect(result, isNull);
    });

    test('solves an empty board', () {
      final result = solver.solve(SudokuBoard.empty());
      expect(result, isNotNull);
      expect(result!.isSolved, isTrue);
    });
  });

  group('SudokuSolver.hasUniqueSolution', () {
    test('known puzzle has unique solution', () {
      expect(solver.hasUniqueSolution(_easyPuzzle), isTrue);
    });

    test('empty board does not have unique solution', () {
      expect(solver.hasUniqueSolution(SudokuBoard.empty()), isFalse);
    });

    test('almost-empty board is not unique', () {
      // Only one clue — many solutions possible
      final board = SudokuBoard.empty();
      board.set(0, 0, 1);
      expect(solver.hasUniqueSolution(board), isFalse);
    });
  });

  group('the deduction engine on the same puzzle', () {
    // solveWithTechniques and rateDifficulty lived here and are gone — the
    // ladder supersedes both. The property they pinned is not: this puzzle is
    // a singles-only solve, and it should stay one.
    test('an easy puzzle needs nothing past singles', () {
      final path = const DeductionEngine()
          .solve(CandidateGrid.fromBoard(_easyPuzzle));
      expect(path.complete, isTrue);
      expect(path.board, _easySolution);
      expect(path.hardestTier, TechniqueTier.singles);
    });

    test('and the singles ceiling alone finishes it', () {
      final path = const DeductionEngine().solve(
        CandidateGrid.fromBoard(_easyPuzzle),
        maxTier: TechniqueTier.singles,
      );
      expect(path.complete, isTrue);
    });
  });
}
