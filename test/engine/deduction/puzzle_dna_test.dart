import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/deduction/puzzle_dna.dart';
import 'package:no_bs_sudoku/engine/deduction/solve_path_analysis.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

void main() {
  const engine = DeductionEngine();
  final generator = SudokuGenerator();

  PuzzleDna dnaFor(Difficulty d, {int seed = 1}) {
    final g = generator.generate(difficulty: d, seed: seed);
    return PuzzleDna.of(
        SolvePathAnalysis.of(engine.solve(CandidateGrid.fromBoard(g.puzzle))));
  }

  group('a fingerprint is comparable', () {
    test('the same grid always fingerprints the same', () {
      expect(dnaFor(Difficulty.hard, seed: 8).fingerprint,
          dnaFor(Difficulty.hard, seed: 8).fingerprint);
    });

    test('different grids generally do not', () {
      final a = dnaFor(Difficulty.expert, seed: 1).fingerprint;
      final b = dnaFor(Difficulty.expert, seed: 2).fingerprint;
      expect(a, isNot(b));
    });

    test('it carries its version, so mismatched builds are visible', () {
      final dna = dnaFor(Difficulty.medium);
      expect(dna.fingerprint, startsWith('v${PuzzleDna.version}:'));
      expect(PuzzleDna.comparable('v1:1.0', 'v1:2.0'), isTrue);
      expect(PuzzleDna.comparable('v1:1.0', 'v2:1.0'), isFalse,
          reason: 'comparing across ladders is meaningless and the prefix is '
              'what stops it being silent');
    });

    test('every technique gets a slot, used or not', () {
      // Keeps the string diffable position by position as the enum grows.
      final slots =
          dnaFor(Difficulty.easy).fingerprint.split(':').last.split('.');
      expect(slots, hasLength(Technique.values.length));
    });

    test('slots are in declaration order, not discovery or count order', () {
      final dna = dnaFor(Difficulty.expert, seed: 4);
      final slots = dna.fingerprint.split(':').last.split('.');
      for (int i = 0; i < Technique.values.length; i++) {
        expect(int.parse(slots[i]), dna.counts[Technique.values[i]] ?? 0,
            reason: '${Technique.values[i].name} is in the wrong slot');
      }
    });
  });

  group('the spectrum is for reading', () {
    test('it lists only what was used, hardest first', () {
      final dna = dnaFor(Difficulty.expert, seed: 3);
      expect(dna.spectrum, isNotEmpty);
      expect(dna.spectrum.every((e) => e.value > 0), isTrue);
      for (int i = 1; i < dna.spectrum.length; i++) {
        expect(dna.spectrum[i - 1].key.index,
            greaterThan(dna.spectrum[i].key.index));
      }
    });

    test('the counts add up to the steps', () {
      final dna = dnaFor(Difficulty.hard, seed: 6);
      expect(dna.totalSteps,
          dna.spectrum.fold<int>(0, (n, e) => n + e.value));
    });
  });

  group('degenerate input', () {
    test('an empty solve still produces a well-formed fingerprint', () {
      const dna = PuzzleDna({});
      expect(dna.totalSteps, 0);
      expect(dna.spectrum, isEmpty);
      expect(dna.fingerprint.split(':').last.split('.'),
          hasLength(Technique.values.length));
    });
  });
}
