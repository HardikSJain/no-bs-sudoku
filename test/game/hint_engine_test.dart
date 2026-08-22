import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/hint_copy.dart';
import 'package:no_bs_sudoku/features/game/hint_engine.dart';

void main() {
  const hints = HintEngine();
  const engine = DeductionEngine();
  final generator = SudokuGenerator();

  late SudokuBoard puzzle;
  late SudokuBoard solution;
  late Set<int> givens;

  setUp(() {
    final g = generator.generate(difficulty: Difficulty.medium, seed: 5);
    puzzle = g.puzzle;
    solution = g.solution;
    givens = {
      for (int i = 0; i < 81; i++)
        if (puzzle.get(i ~/ 9, i % 9) != 0) i,
    };
  });

  int firstEmpty(SudokuBoard b) {
    for (int i = 0; i < 81; i++) {
      if (b.get(i ~/ 9, i % 9) == 0) return i;
    }
    throw StateError('board is full');
  }

  group('a wrong digit comes before anything else', () {
    // placeNumber writes whatever the player taps, so one mistake makes the
    // grid contradictory and every technique returns nothing. Without this
    // branch the hint button goes silent exactly when a stuck player needs
    // it, which is worse than the behaviour it replaced.
    test('a contradictory board still produces a hint', () {
      final board = puzzle.copy();
      final idx = firstEmpty(board);
      final truth = solution.get(idx ~/ 9, idx % 9);
      board.set(idx ~/ 9, idx % 9, truth == 9 ? 1 : truth + 1);

      final result = hints.find(
        board: board,
        solution: solution,
        givens: givens,
      );

      expect(result, isA<HintWrongDigit>());
      expect((result as HintWrongDigit).cells, [idx]);
    });

    test('the ladder would have had nothing to say there', () {
      // Proves the branch is load-bearing rather than belt-and-braces.
      final board = puzzle.copy();
      // Two conflicting digits in one row guarantee a broken grid.
      final a = firstEmpty(board);
      board.set(a ~/ 9, a % 9, solution.get(a ~/ 9, a % 9));
      final b = firstEmpty(board);
      board.set(b ~/ 9, b % 9, solution.get(a ~/ 9, a % 9));

      final grid = CandidateGrid.fromBoard(board);
      if (grid.isBroken) {
        expect(engine.nextStep(grid), isNull);
      }
      expect(
        hints.find(board: board, solution: solution, givens: givens),
        isA<HintWrongDigit>(),
      );
    });

    test('it counts every wrong digit, not just the first', () {
      final board = puzzle.copy();
      final wrong = <int>[];
      for (int n = 0; n < 3; n++) {
        for (int i = 0; i < 81; i++) {
          if (board.get(i ~/ 9, i % 9) != 0 || wrong.contains(i)) continue;
          final truth = solution.get(i ~/ 9, i % 9);
          board.set(i ~/ 9, i % 9, truth == 9 ? 1 : truth + 1);
          wrong.add(i);
          break;
        }
      }
      final result =
          hints.find(board: board, solution: solution, givens: givens)
              as HintWrongDigit;
      expect(result.cells, hasLength(3));
    });
  });

  group('selection awareness', () {
    test('nothing selected gives the next step anywhere', () {
      final result = hints.find(
        board: puzzle,
        solution: solution,
        givens: givens,
      );
      expect(result, isA<HintStep>());
      // With no selection there is no intent to honour or miss.
      expect((result as HintStep).honoursSelection, isTrue);
    });

    test('a solvable selected cell is the one explained', () {
      // Find a cell the ladder can actually settle right now.
      final grid = CandidateGrid.fromBoard(puzzle);
      final step = engine.nextStep(grid)!;
      final target = step.targets.first.$1;

      final result = hints.find(
        board: puzzle,
        solution: solution,
        givens: givens,
        selected: target,
      ) as HintStep;

      expect(result.honoursSelection, isTrue);
      expect(result.deduction.targets.first.$1, target);
    });

    test('an unsolvable selected cell says so and helps anyway', () {
      final grid = CandidateGrid.fromBoard(puzzle);
      // Ask the engine directly rather than guessing from candidate counts —
      // a hidden single keeps plenty of candidates, so "most options" is not
      // the same as "not yet provable".
      final worst = grid.unsolvedCells
          .firstWhere((idx) => engine.placementFor(grid, idx) == null);

      final result = hints.find(
        board: puzzle,
        solution: solution,
        givens: givens,
        selected: worst,
      ) as HintStep;

      expect(result.honoursSelection, isFalse);
      expect(HintCopy.forResult(result, HintRung.locate),
          startsWith('nothing provable there yet.'));
    });

    test('a given falls through without complaining', () {
      final given = givens.first;
      final result = hints.find(
        board: puzzle,
        solution: solution,
        givens: givens,
        selected: given,
      ) as HintStep;
      // Selecting a clue is not a request we failed to honour.
      expect(result.honoursSelection, isTrue);
    });

    test('an already-filled correct cell falls through too', () {
      final board = puzzle.copy();
      final idx = firstEmpty(board);
      board.set(idx ~/ 9, idx % 9, solution.get(idx ~/ 9, idx % 9));

      final result = hints.find(
        board: board,
        solution: solution,
        givens: givens,
        selected: idx,
      ) as HintStep;
      expect(result.honoursSelection, isTrue);
    });
  });

  group('there is always a next nudge', () {
    test('every position in a full solve yields a hint', () {
      // §5.1 promises the hint control is never dead. This walks a whole
      // puzzle and checks the promise at every single step.
      final board = puzzle.copy();
      final grid = CandidateGrid.fromBoard(board);

      for (int guard = 0; guard < 200; guard++) {
        if (board.isSolved) break;
        final result =
            hints.find(board: board, solution: solution, givens: givens);
        expect(result, isNot(isA<HintNothing>()),
            reason: 'no nudge available with '
                '${81 - board.clueCount} cells left');
        expect(HintCopy.forResult(result, HintRung.locate), isNotEmpty);

        final step = engine.nextStep(grid);
        if (step == null) break;
        DeductionEngine.apply(grid, step);
        for (int i = 0; i < 81; i++) {
          if (grid.isPlaced(i)) board.set(i ~/ 9, i % 9, grid.placed(i));
        }
      }
      expect(board.isSolved, isTrue);
    });

    test('a solved board has nothing left to say', () {
      expect(
        hints.find(board: solution, solution: solution, givens: givens),
        isA<HintNothing>(),
      );
    });
  });

  group('placements only ever come from singles', () {
    // placementFor scans just the two singles rules. That is exhaustive
    // rather than a shortcut only while this holds.
    test('across every difficulty', () {
      for (final difficulty in Difficulty.classic) {
        for (int seed = 0; seed < 5; seed++) {
          final g = generator.generate(difficulty: difficulty, seed: seed);
          final path = engine.solve(CandidateGrid.fromBoard(g.puzzle));
          for (final step in path.steps) {
            if (step.kind != DeductionKind.placement) continue;
            expect(step.technique.tier, TechniqueTier.singles,
                reason: '${step.technique.name} places a digit — '
                    'placementFor would miss it');
          }
        }
      }
    });
  });

  group('the grid is never cached', () {
    // A stale grid explains a position that is not on screen, which is
    // silent and indistinguishable from the engine being wrong.
    test('a served deduction always agrees with the board it came from', () {
      final board = puzzle.copy();
      final first =
          hints.find(board: board, solution: solution, givens: givens);

      // Change the board under it, then ask again.
      final idx = (first as HintStep).deduction.targets.first.$1;
      board.set(idx ~/ 9, idx % 9, solution.get(idx ~/ 9, idx % 9));

      final second =
          hints.find(board: board, solution: solution, givens: givens);
      expect(second, isA<HintStep>());
      final d = (second as HintStep).deduction;
      for (final (cell, _) in d.targets) {
        expect(board.get(cell ~/ 9, cell % 9), 0,
            reason: 'the hint targets a cell that is already filled');
      }
    });
  });
}
