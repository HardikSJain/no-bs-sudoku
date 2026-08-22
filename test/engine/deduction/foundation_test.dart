import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/units.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';

void main() {
  group('Units geometry', () {
    test('every cell has exactly 20 peers, none of them itself', () {
      for (int i = 0; i < Units.cellCount; i++) {
        expect(Units.peersOf[i], hasLength(20), reason: 'cell $i');
        expect(Units.peersOf[i], isNot(contains(i)));
      }
    });

    test('peering is symmetric', () {
      for (int i = 0; i < Units.cellCount; i++) {
        for (final peer in Units.peersOf[i]) {
          expect(Units.peersOf[peer], contains(i));
        }
      }
    });

    test('there are 27 units of 9 cells, each cell in exactly 3', () {
      expect(Units.unitCells, hasLength(27));
      final membership = List<int>.filled(Units.cellCount, 0);
      for (final unit in Units.unitCells) {
        expect(unit, hasLength(9));
        expect(unit.toSet(), hasLength(9));
        for (final idx in unit) {
          membership[idx]++;
        }
      }
      expect(membership.every((n) => n == 3), isTrue);
    });

    test('unit ids partition into rows, columns and boxes', () {
      expect(Units.unitKindOf(0), UnitKind.row);
      expect(Units.unitKindOf(8), UnitKind.row);
      expect(Units.unitKindOf(9), UnitKind.column);
      expect(Units.unitKindOf(17), UnitKind.column);
      expect(Units.unitKindOf(18), UnitKind.box);
      expect(Units.unitKindOf(26), UnitKind.box);

      for (int id = 0; id < Units.unitCount; id++) {
        expect(UnitRef.fromId(id).id, id);
      }
    });

    test('boxes are 3x3 blocks', () {
      // Box 4 is the middle: rows 3-5, columns 3-5.
      expect(
        Units.unitCells[18 + 4],
        [30, 31, 32, 39, 40, 41, 48, 49, 50],
      );
    });

    test('a cell knows its own row, column and box', () {
      const idx = 40; // r5c5
      expect(Units.rowOf[idx], 4);
      expect(Units.colOf[idx], 4);
      expect(Units.boxOf[idx], 4);
      expect(Units.unitsOf[idx], [4, 13, 22]);
    });

    test('commonUnits finds the shared line and box', () {
      // Two cells in the same row and box.
      expect(Units.commonUnits([0, 1]), containsAll([0, 18]));
      // Two cells that see nothing of each other.
      expect(Units.commonUnits([0, 40]), isEmpty);
      expect(Units.allShareUnit([0, 1, 2]), isTrue);
      expect(Units.allShareUnit([0, 1, 40]), isFalse);
    });

    test('bit helpers round trip', () {
      expect(Units.digitsIn(Units.allDigits), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(Units.popCount(Units.allDigits), 9);
      expect(Units.digitsIn(Units.maskOf(1) | Units.maskOf(9)), [1, 9]);
      expect(Units.popCount(0), 0);
    });
  });

  group('CandidateGrid', () {
    test('an empty board leaves every digit open everywhere', () {
      final grid = CandidateGrid.fromBoard(SudokuBoard.empty());
      expect(grid.candidateMask(0), Units.allDigits);
      expect(grid.isSolved, isFalse);
      expect(grid.isBroken, isFalse);
    });

    test('placing a digit clears it from all 20 peers', () {
      final grid = CandidateGrid.fromBoard(SudokuBoard.empty());
      grid.place(0, 5);

      expect(grid.placed(0), 5);
      expect(grid.candidateMask(0), 0);
      for (final peer in Units.peersOf[0]) {
        expect(grid.hasCandidate(peer, 5), isFalse, reason: 'peer $peer');
      }
      // A cell that does not see it is untouched.
      expect(grid.hasCandidate(40, 5), isTrue);
    });

    test('eliminate reports whether it changed anything', () {
      final grid = CandidateGrid.fromBoard(SudokuBoard.empty());
      expect(grid.eliminate(0, 3), isTrue);
      expect(grid.eliminate(0, 3), isFalse,
          reason: 'a repeat elimination is not progress, and the solve loop '
              'relies on that to terminate');
    });

    test('a cell with nothing left is broken', () {
      final grid = CandidateGrid.fromBoard(SudokuBoard.empty());
      for (int d = 1; d <= 9; d++) {
        grid.eliminate(0, d);
      }
      expect(grid.isBroken, isTrue);
    });

    test('a solved board reads as solved', () {
      final grid = CandidateGrid.fromBoard(SudokuBoard.empty());
      // Any Latin-square filling will do; validity is not what isSolved asks.
      for (int i = 0; i < Units.cellCount; i++) {
        grid.place(i, 1);
      }
      expect(grid.isSolved, isTrue);
    });

    test('clone is independent of its original', () {
      final grid = CandidateGrid.fromBoard(SudokuBoard.empty());
      final copy = grid.clone();
      copy.place(0, 7);

      expect(grid.placed(0), 0);
      expect(grid.candidateMask(0), Units.allDigits);
      expect(copy.placed(0), 7);
    });

    test('a board round trips through the grid', () {
      final board = SudokuBoard.empty();
      board.set(0, 0, 4);
      board.set(8, 8, 9);
      expect(CandidateGrid.fromBoard(board).toBoard(), board);
    });

    test('fromBoard applies every given before returning', () {
      final board = SudokuBoard.empty();
      board.set(0, 0, 1);
      board.set(0, 1, 2);
      final grid = CandidateGrid.fromBoard(board);
      // r0c2 sees both givens.
      expect(grid.candidatesOf(2), [3, 4, 5, 6, 7, 8, 9]);
    });

    test('cellsWithCandidate scopes to one unit', () {
      final board = SudokuBoard.empty();
      board.set(0, 0, 5);
      final grid = CandidateGrid.fromBoard(board);
      // 5 is gone from the rest of row 0.
      expect(grid.cellsWithCandidate(0, 5), isEmpty);
      // But alive in row 1, apart from the column and box it blocks.
      expect(grid.cellsWithCandidate(1, 5), [12, 13, 14, 15, 16, 17]);
    });
  });

  group('Deduction value equality', () {
    // Hint pinning, hint invalidation, the JSON round trip and mastery dedup
    // all compare deductions. Identity comparison would make pinning fire on
    // every recompute.
    Deduction make({
      List<(int, int)>? targets,
      List<int>? witnesses,
      Technique technique = Technique.nakedPair,
    }) =>
        Deduction(
          technique: technique,
          kind: DeductionKind.elimination,
          targets: targets ?? [(4, 7), (2, 3)],
          witnesses: witnesses ?? [9, 1],
          unit: const UnitRef(UnitKind.row, 0),
        );

    test('two deductions saying the same thing are equal', () {
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });

    test('order of discovery does not matter', () {
      expect(
        make(targets: [(2, 3), (4, 7)], witnesses: [1, 9]),
        make(targets: [(4, 7), (2, 3)], witnesses: [9, 1]),
      );
    });

    test('targets and witnesses come back sorted', () {
      final d = make();
      expect(d.targets, [(2, 3), (4, 7)]);
      expect(d.witnesses, [1, 9]);
    });

    test('a different technique is a different deduction', () {
      expect(make(), isNot(make(technique: Technique.hiddenPair)));
    });

    test('a different target is a different deduction', () {
      expect(make(), isNot(make(targets: [(4, 7), (2, 4)])));
    });

    test('a different unit is a different deduction', () {
      final a = Deduction(
        technique: Technique.nakedPair,
        kind: DeductionKind.elimination,
        targets: const [(0, 1)],
        unit: const UnitRef(UnitKind.row, 0),
      );
      final b = Deduction(
        technique: Technique.nakedPair,
        kind: DeductionKind.elimination,
        targets: const [(0, 1)],
        unit: const UnitRef(UnitKind.column, 0),
      );
      expect(a, isNot(b));
    });

    test('digits and cells are deduplicated and sorted', () {
      final d = Deduction(
        technique: Technique.nakedPair,
        kind: DeductionKind.elimination,
        targets: const [(9, 4), (9, 2), (3, 4)],
      );
      expect(d.digits, [2, 4]);
      expect(d.cells, [3, 9]);
    });

    test('targets are unmodifiable', () {
      expect(() => make().targets.add((0, 1)), throwsUnsupportedError);
    });
  });

  group('UnitRef', () {
    test('is a value type', () {
      expect(const UnitRef(UnitKind.box, 3), const UnitRef(UnitKind.box, 3));
      expect(const UnitRef(UnitKind.box, 3).hashCode,
          const UnitRef(UnitKind.box, 3).hashCode);
      expect(const UnitRef(UnitKind.box, 3),
          isNot(const UnitRef(UnitKind.row, 3)));
    });

    test('exposes its own cells', () {
      expect(const UnitRef(UnitKind.row, 0).cells, Units.unitCells[0]);
      expect(const UnitRef(UnitKind.column, 2).cells, Units.unitCells[11]);
    });

    test('reads as a human would say it', () {
      expect(const UnitRef(UnitKind.row, 0).toString(), 'row 1');
      expect(const UnitRef(UnitKind.box, 8).toString(), 'box 9');
    });
  });
}
