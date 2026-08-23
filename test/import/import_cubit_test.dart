import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/import/import_cubit.dart';

void main() {
  late ImportCubit cubit;
  final generator = SudokuGenerator();

  setUp(() => cubit = ImportCubit());
  tearDown(() => cubit.close());

  String asString(int seed, {Difficulty d = Difficulty.easy}) {
    final g = generator.generate(difficulty: d, seed: seed);
    return [for (int i = 0; i < 81; i++) g.puzzle.get(i ~/ 9, i % 9)].join();
  }

  group('typing a grid', () {
    test('placing a digit moves on to the next cell', () {
      // Eighty-one cells is the feature's real cost; reaching for each one
      // would make it unusable.
      cubit.select(0);
      cubit.place(5);
      expect(cubit.state.cells[0], 5);
      expect(cubit.state.selected, 1);
    });

    test('it does not run off the end', () {
      cubit.select(80);
      cubit.place(9);
      expect(cubit.state.selected, 80);
    });

    test('erase clears the selected cell', () {
      cubit.select(4);
      cubit.place(7);
      cubit.select(4);
      cubit.erase();
      expect(cubit.state.cells[4], 0);
    });
  });

  group('duplicates are shown before anyone asks', () {
    test('both offending cells are marked, not just the second', () {
      cubit.select(0);
      cubit.place(5);
      cubit.select(8);
      cubit.place(5);
      expect(cubit.state.conflicts, {0, 8});
    });

    test('and checking is blocked while one stands', () {
      cubit.select(0);
      cubit.place(5);
      cubit.select(8);
      cubit.place(5);
      expect(cubit.state.canCheck, isFalse);

      cubit.select(8);
      cubit.erase();
      expect(cubit.state.canCheck, isTrue);
    });

    test('an empty grid cannot be checked either', () {
      expect(cubit.state.canCheck, isFalse);
    });
  });

  group('pasting', () {
    test('accepts a plain 81-character string', () {
      final g = generator.generate(difficulty: Difficulty.easy, seed: 1);
      expect(cubit.paste(asString(1)), isTrue);
      expect(cubit.state.board, g.puzzle);
    });

    test('accepts dots for blanks and ignores layout', () {
      final g = generator.generate(difficulty: Difficulty.easy, seed: 2);
      final buffer = StringBuffer();
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          final v = g.puzzle.get(r, c);
          buffer.write(v == 0 ? '.' : '$v');
          if (c % 3 == 2 && c != 8) buffer.write(' | ');
        }
        buffer.write('\n');
      }
      expect(cubit.paste(buffer.toString()), isTrue);
      expect(cubit.state.board, g.puzzle);
    });

    test('refuses anything that is not a grid rather than guessing', () {
      // Silently filling in a partial paste would be worse than saying no.
      expect(cubit.paste('123'), isFalse);
      expect(cubit.paste(''), isFalse);
      expect(cubit.paste('x' * 81), isFalse);
      expect(cubit.state.filled, 0);
    });
  });

  group('a verdict never outlives the grid it was about', () {
    test('editing clears it', () async {
      cubit.paste(asString(3));
      await cubit.check();
      expect(cubit.state.analysis?.verdict, ImportVerdict.unique);

      cubit.select(cubit.state.cells.indexOf(0));
      cubit.place(1);
      expect(cubit.state.analysis, isNull,
          reason: 'a verdict about a grid the player has since changed is '
              'worse than none');
    });
  });

  group('checking', () {
    test('a real puzzle comes back playable with its answer', () async {
      final g = generator.generate(difficulty: Difficulty.medium, seed: 8);
      cubit.paste(asString(8, d: Difficulty.medium));
      await cubit.check();

      final a = cubit.state.analysis!;
      expect(a.isPlayable, isTrue);
      expect(a.solution, g.solution);
      expect(cubit.state.checking, isFalse);
    });

    test('an ambiguous grid is refused', () async {
      cubit.select(0);
      cubit.place(1);
      await cubit.check();
      expect(cubit.state.analysis!.verdict, ImportVerdict.manySolutions);
      expect(cubit.state.analysis!.isPlayable, isFalse);
    });
  });
}
