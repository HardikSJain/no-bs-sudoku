import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/features/game/widgets/sudoku_cell.dart';

void main() {
  Future<void> pumpGrid(WidgetTester tester, {required bool noted}) {
    return tester.pumpWidget(MaterialApp(
      theme: appTheme(),
      home: Scaffold(
        body: SizedBox(
          width: 360,
          height: 360,
          child: GridView.count(
            crossAxisCount: 9,
            children: [
              for (int i = 0; i < 81; i++)
                SudokuCell(
                  row: i ~/ 9,
                  col: i % 9,
                  value: 0,
                  notes: noted ? const {1, 2, 3, 4, 5, 6, 7, 8, 9} : const {},
                  isGiven: false,
                  isSelected: false,
                  isSameNumber: false,
                  isRelated: false,
                  isConflict: false,
                  isEvenBox: (i ~/ 27 + (i % 9) ~/ 3) % 2 == 0,
                  onTap: () {},
                ),
            ],
          ),
        ),
      ),
    ));
  }

  group('pencil marks are painted, not built', () {
    // They used to be a shrink-wrapping GridView plus nine Text widgets per
    // empty cell. A fully pencilled grid was 60+ grid views and 540 text
    // widgets, rebuilt on every hint tap — and technique drills now arrive
    // with the notes already seeded, so this is the common case.
    testWidgets('a fully noted grid adds no text widgets', (tester) async {
      await pumpGrid(tester, noted: false);
      final bare = find.byType(Text).evaluate().length;

      await pumpGrid(tester, noted: true);
      final noted = find.byType(Text).evaluate().length;

      expect(noted, bare,
          reason: 'notes should cost no widgets at all; they are painted');
    });

    testWidgets('and no nested scrollables', (tester) async {
      await pumpGrid(tester, noted: true);
      // One GridView — the board. Any more means a shrink-wrapping grid per
      // cell came back.
      expect(find.byType(GridView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the marks still render', (tester) async {
      await pumpGrid(tester, noted: true);
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
