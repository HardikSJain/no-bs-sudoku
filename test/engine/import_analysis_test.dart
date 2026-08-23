import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

/// Import cannot borrow the shortcut generation uses.
///
/// "A complete ladder solve proves uniqueness" holds for a puzzle this app
/// built. For a grid somebody typed, a stalled ladder proves nothing — so
/// this does the real exponential count, and every way that can go wrong has
/// to produce an answer rather than a spinner.
void main() {
  final solver = SudokuSolver();
  final generator = SudokuGenerator();

  SudokuBoard empty() => SudokuBoard.empty();

  group('a real puzzle is recognised', () {
    test('every difficulty we generate comes back unique', () {
      for (final d in Difficulty.classic) {
        final g = generator.generate(difficulty: d, seed: 5);
        final a = solver.analyseImport(g.puzzle);
        expect(a.verdict, ImportVerdict.unique, reason: d.name);
        expect(a.isPlayable, isTrue);
        expect(a.solution, g.solution, reason: d.name);
      }
    });
  });

  group('and every way it can be wrong is named', () {
    test('nothing entered', () {
      expect(solver.analyseImport(empty()).verdict, ImportVerdict.empty);
    });

    test('a digit repeated in a unit', () {
      final b = empty();
      b.set(0, 0, 5);
      b.set(0, 8, 5);
      expect(solver.analyseImport(b).verdict, ImportVerdict.contradictory);
    });

    test('a genuinely unsolvable grid', () {
      // Take a real puzzle and change one given to something the solution
      // cannot accommodate.
      final g = generator.generate(difficulty: Difficulty.easy, seed: 2);
      final b = g.puzzle.copy();
      for (int i = 0; i < 81; i++) {
        final r = i ~/ 9, c = i % 9;
        if (b.get(r, c) != 0) continue;
        final truth = g.solution.get(r, c);
        // A digit that is legal here but wrong makes it unsolvable only if it
        // truly is; walk until we find one the board rejects downstream.
        for (int v = 1; v <= 9; v++) {
          if (v == truth || !b.isValid(r, c, v)) continue;
          b.set(r, c, v);
          if (solver.solve(b) == null) {
            expect(solver.analyseImport(b).verdict, ImportVerdict.unsolvable);
            return;
          }
          b.set(r, c, 0);
        }
      }
      fail('could not construct an unsolvable grid');
    });

    test('a grid with more than one answer', () {
      // Strip a real puzzle until uniqueness is gone.
      final g = generator.generate(difficulty: Difficulty.easy, seed: 4);
      final b = g.puzzle.copy();
      for (int i = 0; i < 81 && solver.hasUniqueSolution(b); i++) {
        if (b.get(i ~/ 9, i % 9) != 0) b.set(i ~/ 9, i % 9, 0);
      }
      expect(solver.analyseImport(b).verdict, ImportVerdict.manySolutions);
    });

    test('a search past its budget says so instead of spinning', () {
      // Worth being precise about which grids are expensive, because the
      // obvious guess is wrong. A nearly empty board is *cheap*: counting
      // stops at the second solution and a sparse grid finds two almost
      // immediately. The costly case is the opposite — a grid the search has
      // to explore deeply to prove has no second answer, or none at all. The
      // budget exists for that, and a small one on a real puzzle proves the
      // mechanism fires rather than hanging.
      final g = generator.generate(difficulty: Difficulty.expert, seed: 6);
      final a = solver.analyseImport(g.puzzle, nodeBudget: 5);
      expect(a.verdict, ImportVerdict.budgetExhausted);
      expect(a.isPlayable, isFalse);
    });

    test('a sparse grid resolves quickly rather than exhausting', () {
      // The counterpart to the note above, pinned so the reasoning does not
      // rot: one clue on an empty board is answered, not abandoned.
      final b = empty();
      b.set(0, 0, 1);
      expect(solver.analyseImport(b, nodeBudget: 500).verdict,
          ImportVerdict.manySolutions);
    });
  });

  group('the budget does not fire on real work', () {
    test('a hard puzzle finishes well inside it', () {
      final g = generator.generate(difficulty: Difficulty.expert, seed: 1);
      final a = solver.analyseImport(g.puzzle);
      expect(a.verdict, ImportVerdict.unique,
          reason: 'the default budget must not reject a legitimate puzzle');
    });
  });

  group('only a unique grid is playable', () {
    test('nothing else offers a solution to play', () {
      for (final v in ImportVerdict.values) {
        if (v == ImportVerdict.unique) continue;
        expect(ImportAnalysis(v).isPlayable, isFalse, reason: v.name);
        expect(ImportAnalysis(v).solution, isNull, reason: v.name);
      }
    });
  });
}
