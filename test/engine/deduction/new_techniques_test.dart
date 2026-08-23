import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/deduction/rules/chains.dart';
import 'package:no_bs_sudoku/engine/deduction/rules/fish.dart';
import 'package:no_bs_sudoku/engine/deduction/units.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/technique_copy.dart';
import 'package:no_bs_sudoku/features/learn/technique_guide.dart';

void main() {
  int cell(int r, int c) => r * 9 + c;
  CandidateGrid blank() => CandidateGrid.fromBoard(SudokuBoard.empty());

  CandidateGrid onlyDigitAt(int digit, List<int> spots) {
    final grid = blank();
    for (int i = 0; i < Units.cellCount; i++) {
      if (!spots.contains(i)) grid.eliminate(i, digit);
    }
    return grid;
  }

  CandidateGrid withCandidates(Map<int, Set<int>> spec) {
    final grid = blank();
    for (int i = 0; i < Units.cellCount; i++) {
      final keep = spec[i] ?? const <int>{};
      for (int d = 1; d <= 9; d++) {
        if (!keep.contains(d)) grid.eliminate(i, d);
      }
    }
    return grid;
  }

  group('jellyfish', () {
    test('four rows using four columns clears those columns', () {
      final grid = onlyDigitAt(5, [
        cell(0, 0), cell(0, 3),
        cell(2, 3), cell(2, 6),
        cell(4, 6), cell(4, 8),
        cell(6, 8), cell(6, 0),
        cell(8, 0), cell(8, 6), // victims
      ]);

      final found = const BasicFishRule.jellyfish().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.jellyfish);
      expect(found.targets, [(cell(8, 0), 5), (cell(8, 6), 5)]);
    });

    test('a swordfish is not reported as a jellyfish', () {
      final grid = onlyDigitAt(5, [
        cell(0, 0), cell(0, 4),
        cell(4, 4), cell(4, 8),
        cell(8, 0), cell(8, 8),
        cell(2, 0),
      ]);
      expect(const BasicFishRule.jellyfish().find(grid), isNull);
    });
  });

  group('xyz-wing', () {
    test('only cells seeing all three are cleared', () {
      // Pivot r1c1 {1,2,3}; pincers r1c2 {1,3} and r2c1 {2,3}. The pivot can
      // itself be 3, so unlike an xy-wing the eliminations must see it too.
      final grid = withCandidates({
        cell(0, 0): {1, 2, 3},
        cell(0, 1): {1, 3},
        cell(1, 0): {2, 3},
        cell(1, 1): {3, 4},
      });

      final found = const XyzWingRule().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.xyzWing);
      expect(found.witnesses, [cell(0, 0), cell(0, 1), cell(1, 0)]);
      expect(found.targets, [(cell(1, 1), 3)]);
    });

    test('the pincers must cover all three of the pivot digits', () {
      // Both pincers drawn from the pivot but leaving digit 2 uncovered, so
      // the pivot is not forced into anything.
      final grid = withCandidates({
        cell(0, 0): {1, 2, 3},
        cell(0, 1): {1, 3},
        cell(1, 0): {1, 3},
        cell(1, 1): {3, 4},
      });
      expect(const XyzWingRule().find(grid), isNull);
    });

    test('a plain xy-wing pivot is not an xyz-wing', () {
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 1): {1, 3},
        cell(1, 0): {2, 3},
        cell(1, 1): {3, 4},
      });
      expect(const XyzWingRule().find(grid), isNull);
    });
  });

  group('w-wing', () {
    /// Two {1,2} cells that cannot see each other, with digit 1 having
    /// exactly two homes in row 6 — one seen by each of them.
    CandidateGrid wWingGrid({
      Map<int, Set<int>> extra = const {},
      Map<int, Set<int>> override = const {},
    }) =>
        withCandidates({
          cell(0, 0): {1, 2},
          cell(3, 4): {1, 2},
          cell(5, 0): {1, 3},
          cell(5, 4): {1, 4},
          cell(0, 4): {2, 7}, // sees both ends
          ...extra,
          ...override,
        });

    test('one of the pair must be the other digit, so both ends bite', () {
      final found = const WWingRule().find(wWingGrid());

      expect(found, isNotNull);
      expect(found!.technique, Technique.wWing);
      expect(found.witnesses, [cell(0, 0), cell(3, 4), cell(5, 0), cell(5, 4)]);
      expect(found.targets, [(cell(0, 4), 2)]);
    });

    test('it points nowhere in particular, because it is nowhere in '
        'particular', () {
      // The link lives in a unit; the ends and the eliminations do not.
      // Naming that unit would send a player to look at a row holding
      // nothing they can act on.
      expect(const WWingRule().find(wWingGrid())!.unit, isNull);
    });

    test('two matching cells that see each other are a naked pair', () {
      // Cheaper by four tiers, found long before this rule runs, and
      // explaining it with this name would dress a simple thing up.
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 1): {1, 2},
        cell(5, 0): {1, 3},
        cell(5, 1): {1, 4},
        cell(0, 4): {2, 7},
      });
      expect(const WWingRule().find(grid), isNull);
    });

    test('without a strong link there is no argument', () {
      // A third home for 1 in row 6 breaks the link: the digit can dodge
      // both ends, and neither is forced.
      final grid = wWingGrid(extra: {cell(5, 8): {1, 5}});
      expect(const WWingRule().find(grid), isNull);
    });

    test('a link running through one of the ends proves nothing', () {
      // The end already carries the digit as a candidate, so "it is here or
      // there" tells you nothing you did not have.
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(3, 4): {1, 2},
        cell(0, 4): {1, 2},
      });
      expect(const WWingRule().find(grid), isNull);
    });

    test('and it never fires without something to remove', () {
      // Same shape, but nothing seeing both ends holds the digit.
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(3, 4): {1, 2},
        cell(5, 0): {1, 3},
        cell(5, 4): {1, 4},
        cell(0, 4): {7, 8},
      });
      expect(const WWingRule().find(grid), isNull);
    });
  });

  group('remote pairs', () {
    /// Four {1,2} cells linked end to end: r1c1 - r1c3 - r3c3 - r3c9.
    ///
    /// r1c1 and r1c3 share row 1, r1c3 and r3c3 share column 3, r3c3 and
    /// r3c9 share row 3. The ends are r1c1 and r3c9, and r1c9 and r3c1 both
    /// see them.
    CandidateGrid chain({Map<int, Set<int>> extra = const {}}) =>
        withCandidates({
          cell(0, 0): {1, 2},
          cell(0, 2): {1, 2},
          cell(2, 2): {1, 2},
          cell(2, 8): {1, 2},
          cell(0, 8): {1, 2, 5},
          ...extra,
        });

    test('an even chain leaves one digit at each end, so both go', () {
      final found = const RemotePairRule().find(chain());

      expect(found, isNotNull);
      expect(found!.technique, Technique.remotePair);
      // The only rule in the ladder that takes two digits off one cell.
      expect(found.targets, [(cell(0, 8), 1), (cell(0, 8), 2)]);
      expect(found.witnesses.length, 4);
    });

    test('a chain of three says nothing about its ends', () {
      // Odd length puts the same digit at both ends, which is true and
      // useless: you do not know which digit it is.
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 2): {1, 2},
        cell(2, 2): {1, 2},
        cell(2, 0): {1, 2, 5},
      });
      expect(const RemotePairRule().find(grid), isNull);
    });

    test('and a chain of two is a naked pair', () {
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 2): {1, 2},
        cell(0, 8): {1, 2, 5},
      });
      expect(const RemotePairRule().find(grid), isNull);
    });

    test('cells with a different pair are not part of the chain', () {
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 2): {1, 2},
        cell(2, 2): {2, 3},
        cell(2, 8): {1, 2},
        cell(0, 8): {1, 2, 5},
      });
      expect(const RemotePairRule().find(grid), isNull);
    });

    test('a link that does not see the next cell breaks it', () {
      // r3c5 sees neither r1c3 nor r3c9's box, so the walk cannot get there.
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 2): {1, 2},
        cell(5, 5): {1, 2},
        cell(8, 8): {1, 2},
        cell(0, 8): {1, 2, 5},
      });
      expect(const RemotePairRule().find(grid), isNull);
    });

    test('and it never fires without something to remove', () {
      final grid = chain(extra: {
        cell(0, 8): {5, 6},
      });
      expect(const RemotePairRule().find(grid), isNull);
    });
  });

  group('the new rules never lie', () {
    // The same ground-truth check the original twelve get. A rule that
    // over-eliminates would hand a player an unsolvable grid.
    test('across generated puzzles of every difficulty', () {
      const engine = DeductionEngine();
      final generator = SudokuGenerator();

      for (final difficulty in Difficulty.classic) {
        for (int seed = 0; seed < 6; seed++) {
          final g = generator.generate(difficulty: difficulty, seed: seed);
          final grid = CandidateGrid.fromBoard(g.puzzle);

          for (int step = 0; step < 300; step++) {
            final d = engine.nextStep(grid);
            if (d == null) break;
            for (final (idx, digit) in d.targets) {
              final truth = g.solution.get(idx ~/ 9, idx % 9);
              if (d.kind == DeductionKind.placement) {
                expect(digit, truth, reason: d.technique.name);
              } else {
                expect(digit, isNot(truth), reason: d.technique.name);
              }
            }
            DeductionEngine.apply(grid, d);
          }
        }
      }
    });
  });

  group('adding a technique does not shift anything else', () {
    test('rank orders by tier, not by declaration', () {
      // jellyfish is appended last but belongs in fish, below every chain.
      expect(Technique.jellyfish.rank, lessThan(Technique.xyWing.rank));
      expect(Technique.xyzWing.rank, greaterThan(Technique.swordfish.rank));

      // And the whole set is still ordered easiest-first by rank.
      final byRank = [...Technique.values]
        ..sort((a, b) => a.rank.compareTo(b.rank));
      for (int i = 1; i < byRank.length; i++) {
        expect(byRank[i - 1].tier.index,
            lessThanOrEqualTo(byRank[i].tier.index));
      }
    });

    test('the fingerprint keeps one slot per technique', () {
      // Appended, so every previously shared fingerprint still means what it
      // meant — the new slots are on the end.
      expect(Technique.values.length, 16);
      expect(Technique.values[11], Technique.simpleColoring,
          reason: 'an existing slot moved, which invalidates every shared '
              'fingerprint');
    });
  });

  group('every technique is still fully described', () {
    test('the diagrams describe a shape that is actually true', () {
      // The remote pair diagram shipped with an elimination that only saw
      // one end of the chain, which teaches the rule wrong to exactly the
      // person trying to learn it.
      //
      // Only the rules whose argument is literally "anything seeing both
      // ends" — a fish clears whole columns and has no ends. Which witnesses
      // are the ends differs by rule, because each one lists them in the
      // order its explanation reads: an xy-wing names the pivot first, a
      // w-wing names the pair before the link, a remote pair is a chain.
      final ends = <Technique, List<int>>{
        Technique.xyWing: [1, 2],
        Technique.wWing: [0, 1],
        Technique.remotePair: [0, -1],
      };

      for (final entry in ends.entries) {
        final g = TechniqueGuide.of(entry.key);
        for (final at in entry.value) {
          final end = at < 0 ? g.witnesses.last : g.witnesses[at];
          for (final target in g.targets) {
            expect(Units.peersOf[end], contains(target),
                reason: '${entry.key.name}: '
                    'r${target ~/ 9 + 1}c${target % 9 + 1} does not see '
                    'r${end ~/ 9 + 1}c${end % 9 + 1}');
          }
        }
      }
    });

    test('a chain diagram is a chain: each cell sees the next', () {
      for (final t in const [Technique.remotePair]) {
        final w = TechniqueGuide.of(t).witnesses;
        for (var i = 1; i < w.length; i++) {
          expect(Units.peersOf[w[i - 1]], contains(w[i]),
              reason: '${t.name}: link $i is not a link');
        }
      }
    });

    test('name, guide and diagram', () {
      for (final t in Technique.values) {
        expect(t.singular.trim(), isNotEmpty, reason: t.name);
        expect(t.plural.trim(), isNotEmpty, reason: t.name);
        final g = TechniqueGuide.of(t);
        expect(g.oneLine.trim(), isNotEmpty, reason: t.name);
        expect(g.lookFor.trim(), isNotEmpty, reason: t.name);
        expect(g.witnesses.isNotEmpty || g.context.isNotEmpty, isTrue,
            reason: '${t.name} has no diagram');
      }
    });
  });
}
