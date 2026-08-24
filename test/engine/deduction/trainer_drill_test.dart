import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/deduction/trainer_drill.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

void main() {
  const engine = DeductionEngine();
  const builder = TrainerDrillBuilder();
  final generator = SudokuGenerator();

  TrainerDrill? drillFor(Technique t, {int seed = 1}) {
    final g = generator.generateTargeting(t, seed: seed, attempts: 400);
    if (g == null) return null;
    return builder.build(t, g.puzzle, g.solution);
  }

  group('the drill is the technique, immediately', () {
    for (final technique in const [
      Technique.hiddenSingle,
      Technique.nakedPair,
      Technique.pointingPair,
      Technique.xyWing,
      Technique.wWing,
      Technique.simpleColoring,
    ]) {
      test('a ${technique.name} drill opens on a ${technique.name}', () {
        final drill = drillFor(technique);
        expect(drill, isNotNull, reason: 'could not build the drill');

        // The very first move available must be the lesson. Otherwise the
        // player grinds through forty singles to reach a swordfish.
        //
        // Read the position the way the player sees it. A scaffolded drill
        // got here partly by eliminating, and an elimination leaves no mark
        // on the board, so its notes are part of the position. An
        // unscaffolded one has no notes precisely because the board already
        // says everything — see [TrainerDrill.notes].
        final grid = drill!.isScaffolded
            ? CandidateGrid.fromBoardAndNotes(drill.board, drill.notes)
            : CandidateGrid.fromBoard(drill.board);
        final next = engine.nextStep(grid, maxTier: technique.tier);
        expect(next, isNotNull);
        expect(next!.technique, technique);
        expect(next, drill.step);
      });

      test('a ${technique.name} drill carries the notes it needs', () {
        final drill = drillFor(technique);
        expect(drill, isNotNull);

        // The scaffolding for a chain or a fish is almost entirely
        // eliminations, which leave no mark on the board. Without notes the
        // pattern is invisible and the drill is unplayable.
        //
        // The singles are the exception and they are seeded with nothing on
        // purpose: their scaffolding is placements, every one of them already
        // on the board, so pencilling the candidates in would only restate it
        // — and for a naked single that restatement is the answer.
        if (technique.tier == TechniqueTier.singles) {
          expect(drill!.notes, isEmpty);
          expect(drill.isScaffolded, isFalse);
        } else {
          expect(drill!.notes, isNotEmpty);
          expect(drill.isScaffolded, isTrue);
        }
        for (final cell in drill.step.cells) {
          expect(drill.board.get(cell ~/ 9, cell % 9), 0,
              reason: 'the target cell must still be open');
          if (drill.step.kind == DeductionKind.elimination) {
            expect(drill.notes[cell], isNotEmpty,
                reason: 'an elimination target with no notes shows nothing');
          }
        }
      });
    }
  });

  group('the scaffolded position is still a real puzzle', () {
    test('every pre-filled cell agrees with the solution', () {
      for (final technique in const [Technique.xyWing, Technique.nakedPair]) {
        final drill = drillFor(technique);
        expect(drill, isNotNull);
        for (int i = 0; i < 81; i++) {
          final placed = drill!.board.get(i ~/ 9, i % 9);
          if (placed == 0) continue;
          expect(placed, drill.solution.get(i ~/ 9, i % 9),
              reason: 'the fast-forward placed a wrong digit');
        }
      }
    });

    test('the notes never omit the true digit', () {
      // A seeded candidate set that has lost the right answer would make the
      // drill unsolvable while looking perfectly normal.
      for (final technique in const [Technique.xyWing, Technique.pointingPair]) {
        final drill = drillFor(technique);
        expect(drill, isNotNull);
        for (final entry in drill!.notes.entries) {
          final truth = drill.solution.get(entry.key ~/ 9, entry.key % 9);
          expect(entry.value, contains(truth),
              reason: 'r${entry.key ~/ 9 + 1}c${entry.key % 9 + 1} lost its '
                  'own answer');
        }
      }
    });

    test('it still finishes from where it starts', () {
      for (final technique in const [Technique.simpleColoring]) {
        final drill = drillFor(technique);
        expect(drill, isNotNull);
        final path = engine.solve(
            CandidateGrid.fromBoardAndNotes(drill!.board, drill.notes));
        expect(path.complete, isTrue);
        expect(path.board, drill.solution);
      }
    });
  });

  group('it refuses rather than guessing', () {
    test('a puzzle that does not need the technique yields no drill', () {
      // An easy puzzle has no xy-wing crux, so fast-forwarding solves it
      // outright and there is no moment to drill.
      final g = generator.generate(difficulty: Difficulty.easy, seed: 2);
      expect(builder.build(Technique.xyWing, g.puzzle, g.solution), isNull);
    });
  });
}
