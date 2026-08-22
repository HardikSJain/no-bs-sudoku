import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/deduction/units.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

/// The engine is only worth shipping if it never lies.
///
/// Every rule here is checked against ground truth from the backtracking
/// solver: a placement must match the real solution, and an elimination must
/// never rub out the digit that actually belongs in that cell. One bad rule
/// would silently make a puzzle unsolvable for the player, and would poison
/// generation grading — so this is the test that matters most.
void main() {
  const engine = DeductionEngine();
  final generator = SudokuGenerator();
  final solver = SudokuSolver();

  // Generation dominates the runtime of this file — roughly a third of a
  // second a puzzle — so the corpus is built once and shared. Regenerating
  // per test turned a 10s suite into a 70s one for no extra coverage.
  final corpus = <Difficulty, List<({SudokuBoard puzzle, SudokuBoard solution})>>{};

  setUpAll(() {
    for (final difficulty in Difficulty.values) {
      corpus[difficulty] = [
        for (int seed = 0; seed < 15; seed++)
          generator.generate(difficulty: difficulty, seed: seed),
      ];
    }
  });

  /// Runs the ladder to exhaustion, asserting every step against [solution].
  /// Returns the techniques that fired.
  Set<Technique> checkSolve(SudokuBoard puzzle, SudokuBoard solution) {
    final grid = CandidateGrid.fromBoard(puzzle);
    final used = <Technique>{};

    for (int step = 0; step < 500; step++) {
      final deduction = engine.nextStep(grid);
      if (deduction == null) break;
      used.add(deduction.technique);

      for (final (idx, digit) in deduction.targets) {
        final truth = solution.get(idx ~/ 9, idx % 9);
        switch (deduction.kind) {
          case DeductionKind.placement:
            expect(digit, truth,
                reason: '${deduction.technique.name} placed $digit at '
                    'r${idx ~/ 9 + 1}c${idx % 9 + 1}, solution says $truth');
          case DeductionKind.elimination:
            expect(digit, isNot(truth),
                reason: '${deduction.technique.name} eliminated the true '
                    'digit $digit from r${idx ~/ 9 + 1}c${idx % 9 + 1}');
        }
      }

      // A rule that returns a deduction must change something, or solve()
      // spins forever.
      final before = [
        for (int i = 0; i < Units.cellCount; i++) grid.candidateMask(i),
        for (int i = 0; i < Units.cellCount; i++) grid.placed(i),
      ];
      DeductionEngine.apply(grid, deduction);
      final after = [
        for (int i = 0; i < Units.cellCount; i++) grid.candidateMask(i),
        for (int i = 0; i < Units.cellCount; i++) grid.placed(i),
      ];
      expect(after, isNot(before),
          reason: '${deduction.technique.name} reported a step that changed '
              'nothing — the solve loop would never terminate');

      expect(grid.isBroken, isFalse,
          reason: '${deduction.technique.name} broke the grid');
    }
    return used;
  }

  group('never contradicts the real solution', () {
    for (final difficulty in Difficulty.values) {
      test('across 15 ${difficulty.name} puzzles', () {
        for (final g in corpus[difficulty]!) {
          checkSolve(g.puzzle, g.solution);
        }
      });
    }
  });

  group('agrees with the brute-force solver', () {
    test('a completed logical solve matches the unique solution', () {
      int completed = 0;
      for (final g in corpus[Difficulty.medium]!) {
        final path = engine.solve(CandidateGrid.fromBoard(g.puzzle));
        if (!path.complete) continue;
        completed++;

        final grid = CandidateGrid.fromBoard(g.puzzle);
        for (final step in path.steps) {
          DeductionEngine.apply(grid, step);
        }
        expect(grid.toBoard(), g.solution);
      }
      expect(completed, greaterThan(0),
          reason: 'the ladder solved nothing at all — it is not wired up');
    });

    test('every puzzle the generator ships is solvable by pure logic', () {
      // No guessing anywhere. If this fails the app can hand a player a grid
      // that cannot be reasoned to the end, which is the one thing a teaching
      // app must never do.
      final unsolved = <String>[];
      for (final difficulty in Difficulty.values) {
        final puzzles = corpus[difficulty]!;
        for (int seed = 0; seed < puzzles.length; seed++) {
          final g = puzzles[seed];
          final path = engine.solve(CandidateGrid.fromBoard(g.puzzle));
          if (!path.complete) {
            unsolved.add('${difficulty.name}/seed$seed '
                '(${g.puzzle.clueCount} clues, stalled after '
                '${path.stepCount} steps)');
          }
        }
      }
      expect(unsolved, isEmpty);
    });

    test('solve is a no-op on the grid it is handed', () {
      final g = corpus[Difficulty.hard]!.first;
      final grid = CandidateGrid.fromBoard(g.puzzle);
      final before = [
        for (int i = 0; i < Units.cellCount; i++) grid.candidateMask(i),
      ];
      engine.solve(grid);
      expect(
        [for (int i = 0; i < Units.cellCount; i++) grid.candidateMask(i)],
        before,
      );
    });

    test('a solved board yields no further steps', () {
      final g = corpus[Difficulty.easy]!.first;
      expect(engine.nextStep(CandidateGrid.fromBoard(g.solution)), isNull);
    });

    test('an unsolvable grid is reported broken, not guessed at', () {
      final g = corpus[Difficulty.medium]!.first;
      final puzzle = g.puzzle.copy();
      // Write a digit the solution disagrees with, somewhere empty.
      final idx = CandidateGrid.fromBoard(puzzle).unsolvedCells.first;
      final truth = g.solution.get(idx ~/ 9, idx % 9);
      puzzle.set(idx ~/ 9, idx % 9, truth == 9 ? 8 : truth + 1);

      expect(solver.solve(puzzle), isNull,
          reason: 'test setup: the board should now be unsolvable');
      final path = engine.solve(CandidateGrid.fromBoard(puzzle));
      expect(path.complete, isFalse);
    });
  });

  group('the ladder is ordered', () {
    test('nextStep never reaches past the tier it is given', () {
      for (final g in corpus[Difficulty.expert]!) {
        final grid = CandidateGrid.fromBoard(g.puzzle);
        for (final tier in TechniqueTier.values) {
          final step = engine.nextStep(grid, maxTier: tier);
          if (step == null) continue;
          expect(step.technique.tier.index, lessThanOrEqualTo(tier.index));
        }
      }
    });

    test('a step found at singles is the step found unrestricted', () {
      // Easiest-first is the whole point: if a naked single is available, no
      // harder technique may be offered instead.
      for (final g in corpus[Difficulty.hard]!) {
        final grid = CandidateGrid.fromBoard(g.puzzle);
        final easy = engine.nextStep(grid, maxTier: TechniqueTier.singles);
        if (easy == null) continue;
        expect(engine.nextStep(grid), easy);
      }
    });
  });
}
