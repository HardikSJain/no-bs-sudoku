import 'package:flutter_test/flutter_test.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';

void main() {
  group('SudokuBoard', () {
    late SudokuBoard board;

    setUp(() {
      board = SudokuBoard.empty();
    });

    test('empty board has all zero values', () {
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          expect(board.get(r, c), 0);
        }
      }
    });

    test('constructor rejects invalid cell values', () {
      final badCells = List<int>.filled(81, 0);
      badCells[40] = 10;
      expect(() => SudokuBoard(badCells), throwsArgumentError);
    });

    test('constructor rejects wrong length', () {
      expect(() => SudokuBoard([1, 2, 3]), throwsArgumentError);
    });

    test('get and set work correctly', () {
      board.set(0, 0, 5);
      expect(board.get(0, 0), 5);
      board.set(8, 8, 9);
      expect(board.get(8, 8), 9);
    });

    test('row returns correct values', () {
      for (int c = 0; c < 9; c++) {
        board.set(0, c, c + 1);
      }
      expect(board.row(0), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('col returns correct values', () {
      for (int r = 0; r < 9; r++) {
        board.set(r, 0, r + 1);
      }
      expect(board.col(0), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('box returns correct values', () {
      int v = 1;
      for (int r = 0; r < 3; r++) {
        for (int c = 0; c < 3; c++) {
          board.set(r, c, v++);
        }
      }
      expect(board.box(0, 0), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
      expect(board.box(1, 2), [1, 2, 3, 4, 5, 6, 7, 8, 9]);
    });

    test('candidates returns valid options', () {
      // Place some values in row 0
      board.set(0, 0, 1);
      board.set(0, 1, 2);
      board.set(0, 2, 3);
      // Place some in col 3
      board.set(1, 3, 4);
      // Place some in box (0, 3-5)
      board.set(2, 4, 5);

      final cands = board.candidates(0, 3);
      expect(cands.contains(1), isFalse); // in row
      expect(cands.contains(2), isFalse); // in row
      expect(cands.contains(3), isFalse); // in row
      expect(cands.contains(4), isFalse); // in col
      expect(cands.contains(5), isFalse); // in box
      expect(cands.containsAll({6, 7, 8, 9}), isTrue);
    });

    test('candidates returns empty set for filled cell', () {
      board.set(0, 0, 5);
      expect(board.candidates(0, 0), isEmpty);
    });

    test('isValid detects row conflicts', () {
      board.set(0, 0, 5);
      expect(board.isValid(0, 4, 5), isFalse);
      expect(board.isValid(0, 4, 3), isTrue);
    });

    test('isValid detects column conflicts', () {
      board.set(0, 0, 5);
      expect(board.isValid(4, 0, 5), isFalse);
      expect(board.isValid(4, 0, 3), isTrue);
    });

    test('isValid detects box conflicts', () {
      board.set(0, 0, 5);
      expect(board.isValid(2, 2, 5), isFalse);
      expect(board.isValid(2, 2, 3), isTrue);
    });

    test('clueCount returns number of non-zero cells', () {
      expect(board.clueCount, 0);
      board.set(0, 0, 1);
      board.set(5, 5, 7);
      expect(board.clueCount, 2);
    });

    test('copy creates independent copy', () {
      board.set(0, 0, 5);
      final copy = board.copy();
      copy.set(0, 0, 9);
      expect(board.get(0, 0), 5);
      expect(copy.get(0, 0), 9);
    });

    test('equality works', () {
      final a = SudokuBoard(List.generate(81, (i) => i % 9 + 1));
      final b = SudokuBoard(List.generate(81, (i) => i % 9 + 1));
      expect(a, equals(b));
    });

    test('isSolved returns false for empty board', () {
      expect(board.isSolved, isFalse);
    });
  });
}
