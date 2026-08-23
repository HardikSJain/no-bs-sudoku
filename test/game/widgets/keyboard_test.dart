import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/widgets/game_keyboard.dart';

/// An iPad in a keyboard case is a very good way to solve sudoku and a very
/// bad one to reach across the screen ninety times.
///
/// GameCubit runs a periodic timer, so nothing here settles — see the note on
/// `GameCubit.close`, and note the cubit is closed inside the test body.
void main() {
  late AppDatabase db;
  late Repositories repos;
  GameCubit? cubit;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  Future<GameCubit> pumpBoard(WidgetTester tester) async {
    final c = GameCubit.newGame(
        repos: repos, difficulty: Difficulty.easy, seed: 42)
      ..pauseTimer();
    cubit = c;
    await tester.pumpWidget(MaterialApp(
      theme: appTheme(),
      home: Scaffold(
        body: BlocProvider.value(
          value: c,
          child: const GameKeyboard(child: SizedBox.expand()),
        ),
      ),
    ));
    await tester.pump();
    return c;
  }

  Future<void> press(WidgetTester tester, LogicalKeyboardKey key) async {
    await tester.sendKeyEvent(key);
    await tester.pump();
  }

  Future<void> finish() async {
    await cubit?.close();
    cubit = null;
  }

  /// The first cell that is not a given, so a test can place a digit
  /// somewhere the board will accept one.
  (int, int) firstEmpty(GameCubit c) {
    for (var i = 0; i < 81; i++) {
      if (!c.state.isGiven(i ~/ 9, i % 9)) return (i ~/ 9, i % 9);
    }
    throw StateError('a generated puzzle with no empty cells');
  }

  testWidgets('the first arrow puts a cursor in the middle', (tester) async {
    final c = await pumpBoard(tester);
    expect(c.state.hasSelection, isFalse);

    await press(tester, LogicalKeyboardKey.arrowRight);

    expect(c.state.selectedRow, 4);
    expect(c.state.selectedCol, 4);
    await finish();
  });

  testWidgets('arrows walk the grid one cell at a time', (tester) async {
    final c = await pumpBoard(tester);
    c.selectCell(4, 4);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowRight);
    expect((c.state.selectedRow, c.state.selectedCol), (4, 5));
    await press(tester, LogicalKeyboardKey.arrowDown);
    expect((c.state.selectedRow, c.state.selectedCol), (5, 5));
    await press(tester, LogicalKeyboardKey.arrowLeft);
    expect((c.state.selectedRow, c.state.selectedCol), (5, 4));
    await press(tester, LogicalKeyboardKey.arrowUp);
    expect((c.state.selectedRow, c.state.selectedCol), (4, 4));
    await finish();
  });

  testWidgets('and stop at the edge rather than wrapping round',
      (tester) async {
    final c = await pumpBoard(tester);
    c.selectCell(0, 0);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.arrowUp);
    await press(tester, LogicalKeyboardKey.arrowLeft);
    // Wrapping would teleport the cursor to the far corner, which loses the
    // player's place on a grid.
    expect((c.state.selectedRow, c.state.selectedCol), (0, 0));

    c.selectCell(8, 8);
    await tester.pump();
    await press(tester, LogicalKeyboardKey.arrowDown);
    await press(tester, LogicalKeyboardKey.arrowRight);
    expect((c.state.selectedRow, c.state.selectedCol), (8, 8));
    await finish();
  });

  testWidgets('j k l move too', (tester) async {
    final c = await pumpBoard(tester);
    c.selectCell(4, 4);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.keyJ);
    expect(c.state.selectedRow, 5);
    await press(tester, LogicalKeyboardKey.keyK);
    expect(c.state.selectedRow, 4);
    await press(tester, LogicalKeyboardKey.keyL);
    expect(c.state.selectedCol, 5);
    await finish();
  });

  testWidgets('a digit key places that digit', (tester) async {
    final c = await pumpBoard(tester);
    final (row, col) = firstEmpty(c);
    c.selectCell(row, col);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.digit5);
    expect(c.state.board.get(row, col), 5);
    await finish();
  });

  testWidgets('the numpad places the same digit', (tester) async {
    final c = await pumpBoard(tester);
    final (row, col) = firstEmpty(c);
    c.selectCell(row, col);
    await tester.pump();

    await press(tester, LogicalKeyboardKey.numpad7);
    expect(c.state.board.get(row, col), 7);
    await finish();
  });

  testWidgets('backspace clears the cell', (tester) async {
    final c = await pumpBoard(tester);
    final (row, col) = firstEmpty(c);
    c.selectCell(row, col);
    await tester.pump();
    await press(tester, LogicalKeyboardKey.digit5);
    expect(c.state.board.get(row, col), 5);

    await press(tester, LogicalKeyboardKey.backspace);
    expect(c.state.board.get(row, col), 0);
    await finish();
  });

  testWidgets('n toggles notes mode', (tester) async {
    final c = await pumpBoard(tester);
    expect(c.state.isNotesMode, isFalse);

    await press(tester, LogicalKeyboardKey.keyN);
    expect(c.state.isNotesMode, isTrue);
    await press(tester, LogicalKeyboardKey.keyN);
    expect(c.state.isNotesMode, isFalse);
    await finish();
  });

  testWidgets('u undoes the last placement', (tester) async {
    final c = await pumpBoard(tester);
    final (row, col) = firstEmpty(c);
    c.selectCell(row, col);
    await tester.pump();
    await press(tester, LogicalKeyboardKey.digit5);

    await press(tester, LogicalKeyboardKey.keyU);
    expect(c.state.board.get(row, col), 0);
    await finish();
  });

  testWidgets('u on an untouched board does nothing at all', (tester) async {
    final c = await pumpBoard(tester);
    final before = c.state.board.toFlatString();

    await press(tester, LogicalKeyboardKey.keyU);
    expect(c.state.board.toFlatString(), before);
    await finish();
  });

  testWidgets('h asks for a hint, and esc dismisses it', (tester) async {
    final c = await pumpBoard(tester);

    await press(tester, LogicalKeyboardKey.keyH);
    expect(c.state.hasHint, isTrue);

    await press(tester, LogicalKeyboardKey.escape);
    expect(c.state.hasHint, isFalse);
    await finish();
  });

  testWidgets('a held arrow keeps moving', (tester) async {
    final c = await pumpBoard(tester);
    c.selectCell(0, 0);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(c.state.selectedCol, 3);
    await finish();
  });

  testWidgets('but a held digit is one placement, not a stutter',
      (tester) async {
    final c = await pumpBoard(tester);
    final (row, col) = firstEmpty(c);
    c.selectCell(row, col);
    await tester.pump();

    await tester.sendKeyDownEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.digit5);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.digit5);
    await tester.pump();

    // Repeats acting would have toggled the digit back off, or filled the
    // undo stack with three entries for one keypress.
    expect(c.state.board.get(row, col), 5);
    expect(c.state.history.length, 1);
    await finish();
  });

  testWidgets('and a held n does not flicker notes mode', (tester) async {
    final c = await pumpBoard(tester);

    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyN);
    await tester.pump();

    expect(c.state.isNotesMode, isTrue);
    await finish();
  });

  test('every binding in settings is one the handler answers to', () {
    // The list in settings is read off the handler, so the only thing left to
    // check is that somebody has not left an empty row in it.
    expect(GameKeyboard.bindings, isNotEmpty);
    for (final (keys, what) in GameKeyboard.bindings) {
      expect(keys.trim(), isNotEmpty);
      expect(what.trim(), isNotEmpty);
      expect(what, what.toLowerCase(), reason: 'copy voice is lowercase');
    }
  });
}
