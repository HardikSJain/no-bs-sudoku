import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/a11y/tappable.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/features/game/widgets/sudoku_cell.dart';

void main() {
  Future<void> pumpCell(
    WidgetTester tester, {
    int value = 0,
    Set<int> notes = const {},
    bool isGiven = false,
    bool isConflict = false,
    bool isSelected = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: appTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 40,
          height: 40,
          child: SudokuCell(
            row: 2,
            col: 4,
            value: value,
            notes: notes,
            isGiven: isGiven,
            isSelected: isSelected,
            isSameNumber: false,
            isRelated: false,
            isConflict: isConflict,
            isEvenBox: true,
            onTap: () {},
          ),
        ),
      ),
    ));
    // The cell runs flash animations on mount; without settling they are
    // still pending when the test ends.
    await tester.pumpAndSettle();
  }

  group('the board can be described', () {
    // Before this the whole app had zero Semantics nodes, so a screen reader
    // saw eighty-one unlabelled boxes and no way to tell them apart.
    testWidgets('a cell announces where it is and what it holds',
        (tester) async {
      await pumpCell(tester, value: 7);
      expect(
        tester.getSemantics(find.byType(SudokuCell)).label,
        'row 3, column 5, 7',
      );
    });

    testWidgets('an empty cell says so', (tester) async {
      await pumpCell(tester);
      expect(tester.getSemantics(find.byType(SudokuCell)).label,
          'row 3, column 5, empty');
    });

    testWidgets('pencil marks are read out', (tester) async {
      await pumpCell(tester, notes: {3, 1, 9});
      expect(tester.getSemantics(find.byType(SudokuCell)).label,
          'row 3, column 5, notes 1, 3, 9');
    });

    testWidgets('a given is not offered as a button', (tester) async {
      await pumpCell(tester, value: 4, isGiven: true);
      final node = tester.getSemantics(find.byType(SudokuCell));
      expect(node.label, contains('given'));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
    });

    testWidgets('a wrong digit is announced as wrong', (tester) async {
      await pumpCell(tester, value: 5, isConflict: true);
      expect(tester.getSemantics(find.byType(SudokuCell)).label,
          contains('wrong'));
    });

    testWidgets('selection is a state, not a colour', (tester) async {
      await pumpCell(tester, isSelected: true);
      expect(
        tester.getSemantics(find.byType(SudokuCell))
            .flagsCollection.isSelected,
        Tristate.isTrue,
      );
    });
  });

  group('Tappable', () {
    testWidgets('is a named, activatable button', (tester) async {
      var taps = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: Tappable(
            label: 'hint',
            hint: 'get a hint',
            onTap: () => taps++,
            child: const SizedBox(width: 40, height: 40),
          ),
        ),
      ));

      final node = tester.getSemantics(find.byType(Tappable));
      expect(node.label, 'hint');
      // isButton is a plain flag; isEnabled and isSelected are tristate,
      // since "not specified" is meaningfully different from "false".
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);

      await tester.tap(find.byType(Tappable));
      expect(taps, 1);
    });

    testWidgets('reports itself disabled with no handlers', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Tappable(
            label: '4, all placed',
            child: SizedBox(width: 40, height: 40),
          ),
        ),
      ));
      expect(
        tester.getSemantics(find.byType(Tappable))
            .flagsCollection.isEnabled,
        Tristate.isFalse,
      );
    });
  });

  group('text scaling policy', () {
    test('the board clamps and the rest does not', () {
      // A 2x digit in a 39dp cell is not larger, it is clipped — the board
      // is the one surface that cannot grow with the system setting.
      expect(TextScale.boardMax, lessThan(TextScale.contentMax));
      expect(TextScale.contentMax, greaterThanOrEqualTo(2.0));
    });
  });
}
