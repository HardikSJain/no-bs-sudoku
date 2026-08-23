import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/core/theme/app_theme_colors.dart';
import 'package:no_bs_sudoku/features/game/widgets/sudoku_cell.dart';

/// A hint used to be three shades of the same yellow: solid for the answer,
/// 35% for the evidence, 16% for the unit. That is a distinction nobody with
/// a colour vision deficiency, a dimmed screen, or sun on the phone can make.
/// Shape carries it now, and these hold it there.
void main() {
  Future<void> pumpCell(
    WidgetTester tester, {
    bool isHintTarget = false,
    bool isHintWitness = false,
    bool isHintUnit = false,
    bool isSelected = false,
  }) async {
    await tester.pumpWidget(MaterialApp(
      theme: appTheme(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 40,
            height: 40,
            child: SudokuCell(
              row: 0,
              col: 0,
              value: 0,
              notes: const {},
              isGiven: false,
              isSelected: isSelected,
              isSameNumber: false,
              isRelated: false,
              isConflict: false,
              isEvenBox: true,
              isHintTarget: isHintTarget,
              isHintWitness: isHintWitness,
              isHintUnit: isHintUnit,
              onTap: () {},
            ),
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
  }

  CustomPaint cellPaint(WidgetTester tester) => tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(SudokuCell),
          matching: find.byType(CustomPaint),
        ),
      );

  testWidgets('an ordinary cell is not ringed at all', (tester) async {
    await pumpCell(tester);
    expect(cellPaint(tester).foregroundPainter, isNull);
  });

  testWidgets('a hint unit is a wash, not a ring', (tester) async {
    // The weakest of the three states says "look over here". Ringing every
    // cell of a unit would be nine rings and no signal.
    await pumpCell(tester, isHintUnit: true);
    expect(cellPaint(tester).foregroundPainter, isNull);
  });

  testWidgets('the answer is ringed with a solid line', (tester) async {
    await pumpCell(tester, isHintTarget: true);

    expect(cellPaint(tester).foregroundPainter, isNotNull);
    expect(
      find.byType(SudokuCell),
      paints..rrect(style: PaintingStyle.stroke),
    );
  });

  testWidgets('the evidence is ringed with dashes', (tester) async {
    await pumpCell(tester, isHintWitness: true);

    expect(cellPaint(tester).foregroundPainter, isNotNull);
    // A dashed ring is many short subpaths rather than one rounded rect.
    expect(
      find.byType(SudokuCell),
      paints..path(style: PaintingStyle.stroke),
    );
  });

  testWidgets('the two rings are not the same ring', (tester) async {
    await pumpCell(tester, isHintTarget: true);
    final target = cellPaint(tester).foregroundPainter!;

    await pumpCell(tester, isHintWitness: true);
    final witness = cellPaint(tester).foregroundPainter!;

    expect(target.shouldRepaint(witness), isTrue);
  });

  testWidgets('the ring is ink, so it reads on any of the fills',
      (tester) async {
    await pumpCell(tester, isHintTarget: true);
    final ink = AppThemeColors.light.ink;
    expect(find.byType(SudokuCell), paints..rrect(color: ink));
  });
}
