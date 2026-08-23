import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

/// Floor-targeted generation: a puzzle whose crux is a named technique.
///
/// The four legacy labels get a ceiling — "never harder than". These get a
/// floor — "you will have to do this". The promise is only worth making if it
/// is actually kept, which is what these check.
void main() {
  const engine = DeductionEngine();
  final generator = SudokuGenerator();
  final solver = SudokuSolver();

  group('the promise is kept', () {
    // A representative spread rather than all twelve: the rare ones cost
    // seconds apiece and the property under test is the same for each.
    for (final technique in const [
      Technique.hiddenSingle,
      Technique.nakedPair,
      Technique.pointingPair,
      Technique.xyWing,
      Technique.simpleColoring,
    ]) {
      test('a ${technique.name} drill actually needs a ${technique.name}', () {
        final g = generator.generateTargeting(technique, seed: 1, attempts: 400);
        expect(g, isNotNull, reason: 'could not build the drill at all');

        final path = engine.solve(
          CandidateGrid.fromBoard(g!.puzzle),
          maxTier: technique.tier,
        );
        expect(path.complete, isTrue);
        expect(path.board, g.solution);
        expect(path.steps.map((s) => s.technique), contains(technique));

        // The half that makes it a crux rather than a coincidence.
        final without = engine.without(technique).solve(
              CandidateGrid.fromBoard(g.puzzle),
              maxTier: technique.tier,
            );
        expect(without.complete, isFalse,
            reason: 'the puzzle finishes without the technique it claims to '
                'be about, so the drill teaches nothing');

        expect(solver.hasUniqueSolution(g.puzzle), isTrue);
      });
    }
  });

  group('it fails honestly', () {
    test('an exhausted budget returns null rather than a wrong puzzle', () {
      // One attempt will not find a swordfish crux. Shipping a drill without
      // its own lesson would be worse than admitting defeat.
      expect(
        generator.generateTargeting(Technique.swordfish, seed: 3, attempts: 1),
        isNull,
      );
    });

    test('the undrillable techniques are marked as such', () {
      // All three measured at zero, for the same reason: a smaller pattern
      // inside them reaches the same eliminations first, so they are
      // available but never required. Marked rather than left to fail after
      // several seconds in front of somebody who pressed "practise this".
      const undrillable = {
        Technique.nakedTriple,
        Technique.jellyfish,
        Technique.remotePair,
      };
      for (final t in Technique.values) {
        expect(t.isDrillable, !undrillable.contains(t), reason: t.name);
      }
    });
  });

  group('determinism', () {
    test('the same seed gives the same drill', () {
      final a = generator.generateTargeting(Technique.hiddenSingle,
          seed: 9, attempts: 200);
      final b = generator.generateTargeting(Technique.hiddenSingle,
          seed: 9, attempts: 200);
      expect(a, isNotNull);
      expect(a!.puzzle, b!.puzzle);
      expect(a.solution, b.solution);
    });
  });
}
