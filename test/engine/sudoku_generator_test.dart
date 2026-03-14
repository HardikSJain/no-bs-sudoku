import 'package:flutter_test/flutter_test.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

void main() {
  late SudokuGenerator generator;
  late SudokuSolver solver;

  setUp(() {
    generator = SudokuGenerator();
    solver = SudokuSolver();
  });

  group('SudokuGenerator.generate', () {
    for (final difficulty in Difficulty.values) {
      test('generates valid ${difficulty.name} puzzle', () {
        final result = generator.generate(difficulty: difficulty, seed: 42);

        // Solution is valid
        expect(result.solution.isSolved, isTrue);

        // Puzzle has the right clue count range
        final (min, max) = difficulty.clueRange;
        expect(
          result.puzzle.clueCount,
          inInclusiveRange(min, max),
          reason:
              '${difficulty.name}: clueCount=${result.puzzle.clueCount}, expected $min-$max',
        );

        // Puzzle has unique solution
        expect(solver.hasUniqueSolution(result.puzzle), isTrue);

        // Solution matches what solver finds
        final solved = solver.solve(result.puzzle);
        expect(solved, equals(result.solution));
      });
    }

    test('seeded generation is deterministic', () {
      final a = generator.generate(difficulty: Difficulty.medium, seed: 123);
      final b = generator.generate(difficulty: Difficulty.medium, seed: 123);
      expect(a.puzzle, equals(b.puzzle));
      expect(a.solution, equals(b.solution));
    });

    test('different seeds produce different puzzles', () {
      final a = generator.generate(difficulty: Difficulty.medium, seed: 1);
      final b = generator.generate(difficulty: Difficulty.medium, seed: 2);
      expect(a.puzzle, isNot(equals(b.puzzle)));
    });

    test('puzzle clues are a subset of solution', () {
      final result = generator.generate(difficulty: Difficulty.hard, seed: 99);
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          final pv = result.puzzle.get(r, c);
          if (pv != 0) {
            expect(pv, equals(result.solution.get(r, c)));
          }
        }
      }
    });

    for (final difficulty in Difficulty.values) {
      test('uses 180-degree rotational symmetry for ${difficulty.name}', () {
        final result = generator.generate(difficulty: difficulty, seed: 55);
        final puzzle = result.puzzle;

        for (int r = 0; r < 9; r++) {
          for (int c = 0; c < 9; c++) {
            final v = puzzle.get(r, c);
            final symV = puzzle.get(8 - r, 8 - c);
            expect(
              (v != 0) == (symV != 0),
              isTrue,
              reason:
                  '${difficulty.name}: symmetry broken at ($r,$c)=${v != 0 ? "filled" : "empty"} '
                  'vs (${8 - r},${8 - c})=${symV != 0 ? "filled" : "empty"}',
            );
          }
        }
      });
    }
  });

  group('SudokuGenerator.generateDaily', () {
    test('same date produces same puzzle', () {
      final date = DateTime(2025, 3, 14);
      final a = generator.generateDaily(date: date);
      final b = generator.generateDaily(date: date);
      expect(a.puzzle, equals(b.puzzle));
    });

    test('different dates produce different puzzles', () {
      final a = generator.generateDaily(date: DateTime(2025, 3, 14));
      final b = generator.generateDaily(date: DateTime(2025, 3, 15));
      expect(a.puzzle, isNot(equals(b.puzzle)));
    });

    test('daily puzzle is valid and unique', () {
      final result = generator.generateDaily(date: DateTime(2025, 1, 1));
      expect(result.solution.isSolved, isTrue);
      expect(solver.hasUniqueSolution(result.puzzle), isTrue);
    });
  });

  group('Bulk generation stress test', () {
    test('10 generated puzzles all have unique solutions', () {
      for (int i = 0; i < 10; i++) {
        final result = generator.generate(
          difficulty: Difficulty.values[i % 4],
          seed: i * 7 + 13,
        );
        expect(result.solution.isSolved, isTrue,
            reason: 'Puzzle $i solution is not valid');
        expect(solver.hasUniqueSolution(result.puzzle), isTrue,
            reason: 'Puzzle $i does not have unique solution');
      }
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
