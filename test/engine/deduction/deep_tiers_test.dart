import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

void main() {
  const engine = DeductionEngine();
  final generator = SudokuGenerator();
  final solver = SudokuSolver();

  group('the deep tiers keep their promise', () {
    for (final difficulty in Difficulty.deep) {
      test('a ${difficulty.name} puzzle really needs one', () {
        final g = generator.generateDeep(difficulty, seed: 4);
        expect(g, isNotNull, reason: 'could not build a ${difficulty.name}');

        final path = engine.solve(CandidateGrid.fromBoard(g!.puzzle));
        expect(path.complete, isTrue);
        expect(path.board, g.solution);
        expect(solver.hasUniqueSolution(g.puzzle), isTrue);

        final used = path.steps.map((s) => s.technique).toSet();
        expect(used.intersection(difficulty.cruxTechniques.toSet()), isNotEmpty,
            reason: '${difficulty.name} solved without any of its own '
                'techniques: ${used.map((t) => t.name).join(', ')}');
      });
    }
  });

  group('they are additive, never a redefinition', () {
    test('the four classic labels are unchanged and still first', () {
      expect(Difficulty.classic,
          [Difficulty.easy, Difficulty.medium, Difficulty.hard, Difficulty.expert]);
      // Index order matters: records store the name, but anything that
      // compares by index would silently reorder if these moved.
      expect(Difficulty.values.take(4), Difficulty.classic);
    });

    test('only the deep tiers report themselves as deep', () {
      for (final d in Difficulty.classic) {
        expect(d.isDeep, isFalse, reason: d.name);
        expect(d.cruxTechniques, isEmpty);
      }
      for (final d in Difficulty.deep) {
        expect(d.isDeep, isTrue);
        expect(d.cruxTechniques, isNotEmpty);
      }
    });

    test('every tier has a par time and a clue range', () {
      for (final d in Difficulty.values) {
        expect(d.parSeconds, greaterThan(0), reason: d.name);
        expect(d.clueRange.$1, lessThanOrEqualTo(d.clueRange.$2));
        expect(d.description.trim(), isNotEmpty);
      }
    });

    test('the deep tiers ask for more time than expert', () {
      for (final d in Difficulty.deep) {
        expect(d.parSeconds, greaterThan(Difficulty.expert.parSeconds));
      }
    });
  });

  group('generation refuses to substitute', () {
    test('generate throws rather than quietly handing back an expert', () {
      // Falling back would give someone who asked for a fish a puzzle
      // without one, which is the single thing this tier promises.
      expect(
        () => generator.generate(difficulty: Difficulty.fish, seed: 1),
        anyOf(returnsNormally, throwsStateError),
      );
      // When it does succeed, the promise must hold.
      try {
        final g = generator.generate(difficulty: Difficulty.fish, seed: 1);
        final path = engine.solve(CandidateGrid.fromBoard(g.puzzle));
        expect(
          path.steps.map((s) => s.technique).toSet().intersection(
              {Technique.xWing, Technique.swordfish}),
          isNotEmpty,
        );
      } on StateError {
        // An honest failure is an acceptable outcome for a rare tier.
      }
    });
  });
}
