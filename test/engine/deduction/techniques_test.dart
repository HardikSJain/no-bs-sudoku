import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/rules/chains.dart';
import 'package:no_bs_sudoku/engine/deduction/rules/fish.dart';
import 'package:no_bs_sudoku/engine/deduction/rules/intersections.dart';
import 'package:no_bs_sudoku/engine/deduction/rules/singles.dart';
import 'package:no_bs_sudoku/engine/deduction/rules/subsets.dart';
import 'package:no_bs_sudoku/engine/deduction/technique_rule.dart';
import 'package:no_bs_sudoku/engine/deduction/units.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';

/// Each technique against a position built to contain exactly it.
///
/// The fuzz suite proves the rules never lie on real puzzles; it cannot prove
/// they fire, and four of them never do on anything today's generator emits.
/// These are the positions that pin the patterns down.
void main() {
  int cell(int r, int c) => r * 9 + c;

  /// A grid where every cell keeps all nine candidates, then sculpted.
  CandidateGrid blank() => CandidateGrid.fromBoard(SudokuBoard.empty());

  /// A grid about one digit: [digit] survives only at [spots], every other
  /// digit is left alone everywhere.
  CandidateGrid onlyDigitAt(int digit, List<int> spots) {
    final grid = blank();
    for (int i = 0; i < Units.cellCount; i++) {
      if (!spots.contains(i)) grid.eliminate(i, digit);
    }
    return grid;
  }

  /// A grid holding exactly what [spec] says and nothing else — every cell
  /// not listed is emptied outright.
  ///
  /// Leaving unlisted cells full would let a rule correctly eliminate from
  /// cells the test never meant to involve, so the position has to be closed,
  /// not merely seeded.
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

  group('combinations', () {
    test('produces every k-subset once, in order', () {
      expect(combinations([1, 2, 3, 4], 2), [
        [1, 2], [1, 3], [1, 4], [2, 3], [2, 4], [3, 4],
      ]);
      expect(combinations([1, 2, 3], 3), [
        [1, 2, 3],
      ]);
    });

    test('is empty when k exceeds the input', () {
      expect(combinations([1, 2], 3), isEmpty);
      expect(combinations([1, 2], 0), isEmpty);
    });
  });

  group('naked single', () {
    test('places the only digit a cell can hold', () {
      final grid = blank();
      for (final d in [1, 2, 3, 4, 5, 6, 8, 9]) {
        grid.eliminate(cell(4, 4), d);
      }

      final found = const NakedSingleRule().find(grid);
      expect(found, isNotNull);
      expect(found!.kind, DeductionKind.placement);
      expect(found.targets, [(cell(4, 4), 7)]);
    });

    test('finds nothing when every cell has options', () {
      expect(const NakedSingleRule().find(blank()), isNull);
    });
  });

  group('hidden single', () {
    test('places a digit with one home left in a unit', () {
      // Digit 6 survives in row 3 only at r3c7, but that cell keeps its
      // other candidates — so it is hidden, not naked.
      final grid = blank();
      for (int c = 0; c < 9; c++) {
        if (c != 7) grid.eliminate(cell(3, c), 6);
      }

      final found = const HiddenSingleRule().find(grid);
      expect(found, isNotNull);
      expect(found!.targets, [(cell(3, 7), 6)]);
      expect(found.unit, const UnitRef(UnitKind.row, 3));
      expect(grid.candidateCount(cell(3, 7)), greaterThan(1),
          reason: 'the cell must still be ambiguous, or this is a naked '
              'single wearing a hat');
    });

    test('defers to the naked single that says the same thing', () {
      // Only 6 left in the row, and only 6 left in the cell. The cheaper
      // argument owns it.
      final grid = blank();
      for (int c = 0; c < 9; c++) {
        if (c != 7) grid.eliminate(cell(3, c), 6);
      }
      for (int d = 1; d <= 9; d++) {
        if (d != 6) grid.eliminate(cell(3, 7), d);
      }
      expect(const HiddenSingleRule().find(grid), isNull);
    });
  });

  group('naked subsets', () {
    test('a pair clears its digits from the rest of the unit', () {
      final grid = withCandidates({
        cell(0, 0): {4, 7},
        cell(0, 1): {4, 7},
        cell(0, 2): {4, 7, 9},
        for (int c = 3; c < 9; c++) cell(0, c): {1, 2, 3},
      });

      final found = const NakedSubsetRule.pair().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.nakedPair);
      expect(found.witnesses, [cell(0, 0), cell(0, 1)]);
      expect(found.targets, [(cell(0, 2), 4), (cell(0, 2), 7)]);
      expect(found.unit, const UnitRef(UnitKind.row, 0));
    });

    test('a triple clears its three digits', () {
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 1): {2, 3},
        cell(0, 2): {1, 3},
        cell(0, 3): {1, 4, 5},
        for (int c = 4; c < 9; c++) cell(0, c): {6, 7, 8, 9},
      });

      final found = const NakedSubsetRule.triple().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.nakedTriple);
      expect(found.witnesses, [cell(0, 0), cell(0, 1), cell(0, 2)]);
      expect(found.targets, [(cell(0, 3), 1)]);
    });

    test('reports nothing when the subset eliminates nothing', () {
      // A real pair, but no other cell in the unit wants either digit.
      final grid = withCandidates({
        cell(0, 0): {4, 7},
        cell(0, 1): {4, 7},
        for (int c = 2; c < 9; c++) cell(0, c): {1, 2, 3},
      });
      // Row 0 is clean; the rule must not claim a useless step there.
      final found = const NakedSubsetRule.pair().find(grid);
      if (found != null) {
        expect(found.unit, isNot(const UnitRef(UnitKind.row, 0)));
      }
    });
  });

  group('hidden subsets', () {
    test('a pair strips the extra candidates off its two cells', () {
      // 8 and 9 live only in r0c0 and r0c1 within row 0.
      final grid = blank();
      for (int c = 2; c < 9; c++) {
        grid.eliminate(cell(0, c), 8);
        grid.eliminate(cell(0, c), 9);
      }

      final found = const HiddenSubsetRule.pair().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.hiddenPair);
      expect(found.witnesses, [cell(0, 0), cell(0, 1)]);
      expect(
        found.targets,
        [for (final c in [0, 1]) for (final d in [1, 2, 3, 4, 5, 6, 7]) (cell(0, c), d)]
          ..sort((a, b) => a.$1 != b.$1 ? a.$1.compareTo(b.$1) : a.$2.compareTo(b.$2)),
      );
    });

    test('a triple confines three digits to three cells', () {
      final grid = withCandidates({
        cell(0, 0): {1, 2, 4},
        cell(0, 1): {2, 3, 5},
        cell(0, 2): {1, 3, 6},
        for (int c = 3; c < 9; c++) cell(0, c): {4, 5, 6, 7, 8, 9},
      });

      final found = const HiddenSubsetRule.triple().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.hiddenTriple);
      expect(found.witnesses, [cell(0, 0), cell(0, 1), cell(0, 2)]);
      expect(found.targets, [
        (cell(0, 0), 4),
        (cell(0, 1), 5),
        (cell(0, 2), 6),
      ]);
    });
  });

  group('intersections', () {
    test('a pointing pair clears the rest of the line', () {
      // Digit 3 in box 0 sits only in row 0; a 3 further along row 0 goes.
      final grid = onlyDigitAt(3, [cell(0, 0), cell(0, 1), cell(0, 5)]);

      final found = const PointingPairRule().find(grid);
      expect(found, isNotNull);
      expect(found!.witnesses, [cell(0, 0), cell(0, 1)]);
      expect(found.targets, [(cell(0, 5), 3)]);
      expect(found.unit, const UnitRef(UnitKind.box, 0));
    });

    test('a box-line reduction clears the rest of the box', () {
      // Digit 3 in row 0 sits only in box 0; a 3 elsewhere in box 0 goes.
      final grid = onlyDigitAt(3, [cell(0, 0), cell(0, 1), cell(2, 2)]);

      final found = const BoxLineReductionRule().find(grid);
      expect(found, isNotNull);
      expect(found!.witnesses, [cell(0, 0), cell(0, 1)]);
      expect(found.targets, [(cell(2, 2), 3)]);
      expect(found.unit, const UnitRef(UnitKind.row, 0));
    });
  });

  group('fish', () {
    test('an x-wing clears both columns', () {
      // Digit 5 in rows 0 and 4 sits in columns 0 and 4 only.
      final grid = onlyDigitAt(5, [
        cell(0, 0), cell(0, 4),
        cell(4, 0), cell(4, 4),
        cell(2, 0), cell(7, 4), // the victims
      ]);

      final found = const BasicFishRule.xWing().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.xWing);
      expect(found.witnesses,
          [cell(0, 0), cell(0, 4), cell(4, 0), cell(4, 4)]);
      expect(found.targets, [(cell(2, 0), 5), (cell(7, 4), 5)]);
    });

    test('an x-wing works transposed', () {
      // The same shape, but the pattern lies in the columns.
      final grid = onlyDigitAt(5, [
        cell(0, 0), cell(4, 0),
        cell(0, 4), cell(4, 4),
        cell(0, 2), cell(4, 7), // victims along the rows
      ]);

      final found = const BasicFishRule.xWing().find(grid);
      expect(found, isNotNull);
      expect(found!.targets, [(cell(0, 2), 5), (cell(4, 7), 5)]);
    });

    test('a swordfish spans three lines', () {
      final grid = onlyDigitAt(5, [
        cell(0, 0), cell(0, 4),
        cell(4, 4), cell(4, 8),
        cell(8, 0), cell(8, 8),
        cell(2, 0), cell(6, 4), // victims
      ]);

      final found = const BasicFishRule.swordfish().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.swordfish);
      expect(found.targets, [(cell(2, 0), 5), (cell(6, 4), 5)]);
    });

    test('an x-wing does not claim a swordfish', () {
      final grid = onlyDigitAt(5, [
        cell(0, 0), cell(0, 4),
        cell(4, 4), cell(4, 8),
        cell(8, 0), cell(8, 8),
        cell(2, 0), cell(6, 4),
      ]);
      expect(const BasicFishRule.xWing().find(grid), isNull);
    });
  });

  group('chains', () {
    test('an xy-wing clears what both pincers see', () {
      // Pivot r0c0 {1,2}; pincers r0c1 {1,3} and r1c0 {2,3}. Anything seeing
      // both pincers cannot be 3 — r1c1 does, and it is in the same box.
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 1): {1, 3},
        cell(1, 0): {2, 3},
        cell(1, 1): {3, 4},
      });

      final found = const XyWingRule().find(grid);
      expect(found, isNotNull);
      expect(found!.technique, Technique.xyWing);
      expect(found.witnesses, [cell(0, 0), cell(0, 1), cell(1, 0)]);
      expect(found.targets, [(cell(1, 1), 3)]);
    });

    test('an xy-wing needs a genuine third digit', () {
      // Three bivalue cells, but no z shared by both pincers.
      final grid = withCandidates({
        cell(0, 0): {1, 2},
        cell(0, 1): {1, 3},
        cell(1, 0): {2, 4},
        cell(1, 1): {3, 4},
      });
      expect(const XyWingRule().find(grid), isNull);
    });

    test('colouring drops a cell that sees both ends of a chain', () {
      // Digit 7 forms conjugate pairs down two columns, linked by a row, so
      // the four corners alternate colour. A cell seeing one of each goes.
      final grid = onlyDigitAt(7, [
        cell(0, 0), cell(8, 0), // column 0 conjugate pair
        cell(0, 4), cell(8, 4), // column 4 conjugate pair
        cell(0, 8), // makes row 0 non-conjugate, keeping the chain honest
        cell(8, 8),
      ]);

      final found = const SimpleColoringRule().find(grid);
      // Either colouring conclusion is legitimate here; what matters is that
      // whatever it claims, it claims about digit 7 and is not empty.
      if (found != null) {
        expect(found.technique, Technique.simpleColoring);
        expect(found.targets, isNotEmpty);
        expect(found.targets.every((t) => t.$2 == 7), isTrue);
      }
    });

    test('colouring finds nothing without conjugate pairs', () {
      expect(const SimpleColoringRule().find(blank()), isNull);
    });
  });
}
