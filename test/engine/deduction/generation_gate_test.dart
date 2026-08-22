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
    for (final difficulty in Difficulty.classic) {
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
    for (final difficulty in Difficulty.classic) {
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
    for (final difficulty in Difficulty.classic) {
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
      for (final difficulty in Difficulty.classic) {
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
      for (final difficulty in Difficulty.classic) {
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
      for (final difficulty in Difficulty.classic) {
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

    test('holds the old algorithm until the cutover', () {
      // Before the cutover a non-updated player must see exactly the puzzle
      // this build produces, or "the same puzzle everywhere" is a lie for
      // however long the rollout takes.
      final before =
          SudokuGenerator.dailyAlgorithmV2Cutover.subtract(const Duration(days: 1));
      final legacy = generator.generateDaily(date: before);
      final direct = generator.generate(
        difficulty: legacy.difficulty,
        seed: before.year * 10000 + before.month * 100 + before.day,
        useLadderGate: false,
      );
      expect(legacy.puzzle, direct.puzzle);
    });

    test('switches to the ladder from the cutover date on', () {
      final on = SudokuGenerator.dailyAlgorithmV2Cutover;
      final v2 = generator.generateDaily(date: on);
      final seed = on.year * 10000 + on.month * 100 + on.day;
      expect(v2.puzzle,
          generator.generate(difficulty: v2.difficulty, seed: seed).puzzle);
    });

    test('the cutover actually changes what players get', () {
      // Not every date diverges — on easy grids both gates accept the same
      // removals — so this asks the question across a full rotation rather
      // than pinning one date and calling it proof.
      int differing = 0;
      for (int day = 0; day < 7; day++) {
        final date =
            SudokuGenerator.dailyAlgorithmV2Cutover.add(Duration(days: day));
        final seed = date.year * 10000 + date.month * 100 + date.day;
        final difficulty = SudokuGenerator.dailyDifficulty(date);
        final v2 = generator.generate(difficulty: difficulty, seed: seed);
        final v1 = generator.generate(
            difficulty: difficulty, seed: seed, useLadderGate: false);
        if (v2.puzzle != v1.puzzle) differing++;
      }
      expect(differing, greaterThan(0),
          reason: 'the two digs never disagree, so the cutover guards nothing');
    });

    test('the cutover is far enough out to be useful', () {
      // A cutover in the past means updated and non-updated players diverge
      // the moment this ships.
      expect(
        SudokuGenerator.dailyAlgorithmV2Cutover.isAfter(DateTime.utc(2026, 9, 12)),
        isTrue,
        reason: 'move the cutover forward, or delete the legacy dig if it has '
            'safely passed',
      );
    });

    test('needs no guess, once the cutover has passed', () {
      for (int day = 0; day < 14; day++) {
        final date =
            SudokuGenerator.dailyAlgorithmV2Cutover.add(Duration(days: day));
        final daily = generator.generateDaily(date: date);
        final path = engine.solve(
          CandidateGrid.fromBoard(daily.puzzle),
          maxTier: daily.difficulty.maxTier,
        );
        expect(path.complete, isTrue,
            reason: 'the daily for $date cannot be reasoned out');
        expect(solver.hasUniqueSolution(daily.puzzle), isTrue);
      }
    });

    test('is still uniquely solvable before the cutover, guess or not', () {
      // Recorded deliberately: until the cutover the daily is dug the old
      // way, so it may still need a guess. That is the price of not handing
      // updated and non-updated players different grids, and it expires on
      // its own. Uniqueness, which is what keeps a puzzle winnable, holds
      // either way.
      for (int day = 1; day <= 7; day++) {
        final daily = generator.generateDaily(date: DateTime.utc(2026, 9, day));
        expect(solver.hasUniqueSolution(daily.puzzle), isTrue);
      }
    });
  });
}
