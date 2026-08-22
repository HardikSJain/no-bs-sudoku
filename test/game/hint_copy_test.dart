import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/deduction/units.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/hint_copy.dart';
import 'package:no_bs_sudoku/features/game/hint_engine.dart';
import 'package:no_bs_sudoku/features/game/technique_copy.dart';

void main() {
  Deduction placement({
    Technique technique = Technique.hiddenSingle,
    UnitRef? unit = const UnitRef(UnitKind.box, 3),
  }) =>
      Deduction(
        technique: technique,
        kind: DeductionKind.placement,
        targets: const [(30, 7)],
        witnesses: const [1, 2],
        unit: unit,
      );

  Deduction elimination({
    Technique technique = Technique.nakedPair,
    List<(int, int)> targets = const [(4, 3), (5, 9)],
  }) =>
      Deduction(
        technique: technique,
        kind: DeductionKind.elimination,
        targets: targets,
        witnesses: const [0, 1],
        unit: const UnitRef(UnitKind.row, 0),
      );

  group('the rungs say progressively more', () {
    test('locate names only the unit', () {
      final line = HintCopy.forResult(
          HintStep(placement(), honoursSelection: true), HintRung.locate);
      expect(line, 'there\'s something in box 4.');
      expect(line, isNot(contains('7')), reason: 'locate must not leak the digit');
    });

    test('narrow says a cell can be settled, still without the digit', () {
      final line = HintCopy.forResult(
          HintStep(placement(), honoursSelection: true), HintRung.narrow);
      expect(line, isNot(contains('7')));
      expect(line, isNot(contains('hidden single')),
          reason: 'the technique name belongs to explain, not narrow');
    });

    test('explain names the technique', () {
      final result = HintStep(placement(), honoursSelection: true);
      expect(HintCopy.techniqueLabel(result, HintRung.explain), 'hidden single');
      expect(HintCopy.forResult(result, HintRung.explain), contains('box 4'));
    });

    test('apply gives the answer', () {
      expect(
        HintCopy.forResult(
            HintStep(placement(), honoursSelection: true), HintRung.apply),
        '7 goes in r4c4.',
      );
    });

    test('the technique name is withheld below explain', () {
      final result = HintStep(placement(), honoursSelection: true);
      expect(HintCopy.techniqueLabel(result, HintRung.locate), isNull);
      expect(HintCopy.techniqueLabel(result, HintRung.narrow), isNull);
    });
  });

  group('a missed selection is admitted', () {
    test('the line leads with it, then helps anyway', () {
      final line = HintCopy.forResult(
          HintStep(placement(), honoursSelection: false), HintRung.locate);
      expect(line, startsWith('nothing provable there yet.'));
      expect(line, contains('box 4'));
    });

    test('and is absent when the selection was honoured', () {
      expect(
        HintCopy.forResult(
            HintStep(placement(), honoursSelection: true), HintRung.locate),
        isNot(contains('nothing provable')),
      );
    });
  });

  group('wrong digits escalate toward the mistake', () {
    test('one wrong digit', () {
      const r = HintWrongDigit([40]);
      expect(HintCopy.forResult(r, HintRung.locate),
          'something you\'ve placed is wrong.');
      expect(HintCopy.forResult(r, HintRung.narrow), contains('box 5'));
      expect(HintCopy.forResult(r, HintRung.apply), 'this one: r5c5.');
    });

    test('several wrong digits are counted honestly', () {
      expect(HintCopy.forResult(const HintWrongDigit([1, 2, 3]), HintRung.locate),
          '3 of the digits you\'ve placed are wrong.');
    });
  });

  group('eliminations read as lessons', () {
    test('a naked pair explains the sharing', () {
      final line = HintCopy.forResult(
          HintStep(elimination(), honoursSelection: true), HintRung.explain);
      expect(line, contains('between them'));
      expect(line, contains('row 1'));
    });

    test('apply counts what it removed', () {
      expect(
        HintCopy.forResult(
            HintStep(elimination(), honoursSelection: true), HintRung.apply),
        'removed 2 candidates.',
      );
      expect(
        HintCopy.forResult(
            HintStep(elimination(targets: const [(4, 3)]),
                honoursSelection: true),
            HintRung.apply),
        'removed 3 from r1c5.',
      );
    });

    test('a unitless single still points at its box', () {
      // A naked single carries no unit, but it is in one place and saying
      // otherwise sends the player looking across the whole grid.
      final single = Deduction(
        technique: Technique.nakedSingle,
        kind: DeductionKind.placement,
        targets: const [(30, 7)],
        witnesses: const [0, 1],
      );
      expect(
        HintCopy.forResult(HintStep(single, honoursSelection: true),
            HintRung.locate),
        'there\'s something in box 5.',
      );
    });

    test('a fish spanning boxes has no single place to point at', () {
      final fish = Deduction(
        technique: Technique.xWing,
        kind: DeductionKind.elimination,
        // Opposite corners of the grid: box 1 and box 9.
        targets: const [(0, 3), (80, 3)],
        witnesses: const [0, 4, 36, 40],
      );
      final line = HintCopy.forResult(
          HintStep(fish, honoursSelection: true), HintRung.locate);
      expect(line, 'there\'s something to find, spread across the board.');
    });
  });

  group('every technique has copy at every rung', () {
    // A missing branch would show a player a fallback sentence at the exact
    // moment they are trying to learn the name of what they are looking at.
    test('no rung produces an empty or placeholder line', () {
      for (final technique in Technique.values) {
        final kind = technique.tier == TechniqueTier.singles
            ? DeductionKind.placement
            : DeductionKind.elimination;
        final d = Deduction(
          technique: technique,
          kind: kind,
          targets: const [(40, 5)],
          witnesses: const [0, 1],
          unit: const UnitRef(UnitKind.box, 4),
        );
        for (final rung in HintRung.values) {
          final line =
              HintCopy.forResult(HintStep(d, honoursSelection: true), rung);
          expect(line.trim(), isNotEmpty, reason: '${technique.name}/$rung');
          expect(line, isNot(contains('null')), reason: '${technique.name}/$rung');
        }
        expect(technique.singular.trim(), isNotEmpty);
        expect(technique.plural.trim(), isNotEmpty);
      }
    });
  });

  group('the voice rule holds', () {
    // CLAUDE.md: lowercase, dry, calm. no exclamation points. ever.
    test('nothing shouts, nothing capitalises', () {
      const hints = HintEngine();
      const engine = DeductionEngine();
      final generator = SudokuGenerator();
      final lines = <String>{};

      for (final difficulty in Difficulty.values) {
        final g = generator.generate(difficulty: difficulty, seed: 2);
        final givens = {
          for (int i = 0; i < 81; i++)
            if (g.puzzle.get(i ~/ 9, i % 9) != 0) i,
        };
        final board = g.puzzle.copy();
        final grid = CandidateGrid.fromBoard(board);

        for (int step = 0; step < 40; step++) {
          final result = hints.find(
              board: board, solution: g.solution, givens: givens);
          for (final rung in HintRung.values) {
            lines.add(HintCopy.forResult(result, rung));
          }
          final next = engine.nextStep(grid);
          if (next == null) break;
          DeductionEngine.apply(grid, next);
          for (int i = 0; i < 81; i++) {
            if (grid.isPlaced(i)) board.set(i ~/ 9, i % 9, grid.placed(i));
          }
        }
      }

      expect(lines, isNotEmpty);
      for (final line in lines) {
        expect(line, isNot(contains('!')), reason: line);
        expect(line, equals(line.toLowerCase()), reason: line);
      }
    });
  });
}
