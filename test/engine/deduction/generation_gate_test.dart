import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

/// Generation now accepts a removal on the ladder's word rather than by
/// counting solutions. Two things have to stay true for that to be safe.
void main() {
  const engine = DeductionEngine();
  final generator = SudokuGenerator();
  final solver = SudokuSolver();

  final corpus = <Difficulty, List<({SudokuBoard puzzle, SudokuBoard solution})>>{};

  setUpAll(() {
    for (final difficulty in Difficulty.values) {
      corpus[difficulty] = [
        for (int seed = 0; seed < 20; seed++)
          generator.generate(difficulty: difficulty, seed: seed),
      ];
    }
  });

  group('the uniqueness oracle still holds', () {
    // The ladder's proof of uniqueness is only as good as its twelve rules.
    // A rule that over-eliminates could prune the branch holding a second
    // solution and the gate would never notice — so this asserts the property
    // independently of the code that claims it.
    //
    // The user-visible stake: the grid reddens every cell where the board
    // disagrees with the stored solution, so a player who fills in the *other*
    // valid answer watches correct digits mark as mistakes and hits the
    // mistake limit on a puzzle they actually solved.
    for (final difficulty in Difficulty.values) {
      test('every generated ${difficulty.name} puzzle has exactly one answer',
          () {
        for (final g in corpus[difficulty]!) {
          expect(solver.hasUniqueSolution(g.puzzle), isTrue);
          expect(solver.solve(g.puzzle), g.solution);
        }
      });
    }
  });

  group('no puzzle needs a guess', () {
    for (final difficulty in Difficulty.values) {
      test('${difficulty.name} solves within its own ceiling', () {
        for (final g in corpus[difficulty]!) {
          final path = engine.solve(
            CandidateGrid.fromBoard(g.puzzle),
            maxTier: difficulty.maxTier,
          );
          expect(path.complete, isTrue,
              reason: 'stalled after ${path.stepCount} steps with '
                  '${g.puzzle.clueCount} clues');
          expect(path.board, g.solution);
        }
      });
    }

    test('the ceiling is respected, never exceeded', () {
      for (final difficulty in Difficulty.values) {
        for (final g in corpus[difficulty]!) {
          final path = engine.solve(CandidateGrid.fromBoard(g.puzzle));
          expect(path.hardestTier!.index,
              lessThanOrEqualTo(difficulty.maxTier.index),
              reason: '${difficulty.name} needed ${path.hardestTechnique!.name}');
        }
      }
    });
  });

  group('the guard rails still hold', () {
    test('clue counts stay inside each difficulty range', () {
      for (final difficulty in Difficulty.values) {
        final (min, max) = difficulty.clueRange;
        for (final g in corpus[difficulty]!) {
          expect(g.puzzle.clueCount, inInclusiveRange(min, max),
              reason: '${difficulty.name} dug to ${g.puzzle.clueCount}');
        }
      }
    });

    test('difficulties stay ordered by clue count', () {
      int median(Difficulty d) {
        final counts = [for (final g in corpus[d]!) g.puzzle.clueCount]..sort();
        return counts[counts.length ~/ 2];
      }

      expect(median(Difficulty.easy), greaterThan(median(Difficulty.medium)));
      expect(median(Difficulty.medium), greaterThan(median(Difficulty.hard)));
      expect(median(Difficulty.hard),
          greaterThanOrEqualTo(median(Difficulty.expert)));
    });

    test('180-degree rotational symmetry survives the new gate', () {
      for (final difficulty in Difficulty.values) {
        for (final g in corpus[difficulty]!) {
          // Pass 2 breaks strict symmetry by design, so this asserts the
          // shape is still mostly symmetric rather than perfectly so.
          int symmetric = 0;
          for (int i = 0; i < 81; i++) {
            final filled = g.puzzle.get(i ~/ 9, i % 9) != 0;
            final mirror = g.puzzle.get(8 - i ~/ 9, 8 - i % 9) != 0;
            if (filled == mirror) symmetric++;
          }
          expect(symmetric, greaterThan(60),
              reason: '${difficulty.name} looks scattered, not dug');
        }
      }
    });
  });

  group('the daily puzzle', () {
    test('is the same everywhere for the same date', () {
      final date = DateTime.utc(2026, 8, 22);
      final a = generator.generateDaily(date: date);
      final b = generator.generateDaily(date: date);
      expect(a.puzzle, b.puzzle);
      expect(a.solution, b.solution);
    });

    test('needs no guess either', () {
      for (int day = 1; day <= 7; day++) {
        final daily = generator.generateDaily(date: DateTime.utc(2026, 9, day));
        final path = engine.solve(
          CandidateGrid.fromBoard(daily.puzzle),
          maxTier: daily.difficulty.maxTier,
        );
        expect(path.complete, isTrue,
            reason: 'the daily for 2026-09-0$day cannot be reasoned out');
        expect(solver.hasUniqueSolution(daily.puzzle), isTrue);
      }
    });
  });
}
