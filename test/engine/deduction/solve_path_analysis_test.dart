import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/deduction/solve_path_analysis.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

void main() {
  const engine = DeductionEngine();
  final generator = SudokuGenerator();

  SolvePathAnalysis analyse(Difficulty d, {int seed = 1}) {
    final g = generator.generate(difficulty: d, seed: seed);
    return SolvePathAnalysis.of(
        engine.solve(CandidateGrid.fromBoard(g.puzzle)));
  }

  group('it describes the solve it was given', () {
    test('the counts add up to the steps taken', () {
      for (final d in Difficulty.classic) {
        final a = analyse(d);
        expect(a.complete, isTrue);
        expect(a.uses.fold<int>(0, (n, u) => n + u.count), a.totalSteps);
        expect(a.tierByStep, hasLength(a.totalSteps));
      }
    });

    test('techniques are listed hardest first', () {
      final a = analyse(Difficulty.expert, seed: 3);
      for (int i = 1; i < a.uses.length; i++) {
        expect(a.uses[i - 1].technique.index,
            greaterThanOrEqualTo(a.uses[i].technique.index));
      }
    });

    test('the hardest technique is one that was actually used', () {
      for (final d in Difficulty.classic) {
        final a = analyse(d);
        expect(a.uses.map((u) => u.technique), contains(a.hardest));
      }
    });

    test('first-step indices point at real steps', () {
      final a = analyse(Difficulty.hard, seed: 5);
      for (final use in a.uses) {
        expect(use.firstStep, inInclusiveRange(0, a.totalSteps - 1));
        expect(a.tierByStep[use.firstStep], use.technique.tier);
      }
    });

    test('hardestAt places the turn inside the solve', () {
      final a = analyse(Difficulty.expert, seed: 2);
      expect(a.hardestAt, inInclusiveRange(0.0, 1.0));
    });

    test('routine steps never exceed the total', () {
      final a = analyse(Difficulty.easy);
      expect(a.routineSteps, lessThanOrEqualTo(a.totalSteps));
      // An easy puzzle is singles all the way down, by construction.
      expect(a.routineSteps, a.totalSteps);
    });
  });

  group('degenerate paths', () {
    test('an empty path reports nothing rather than dividing by zero', () {
      final empty = SolvePath(
        steps: const [],
        complete: false,
        hardestTechnique: null,
        board: SudokuBoard.empty(),
      );
      final a = SolvePathAnalysis.of(empty);
      expect(a.totalSteps, 0);
      expect(a.uses, isEmpty);
      expect(a.hardestAt, isNull);
      expect(a.routineSteps, 0);
    });
  });
}
