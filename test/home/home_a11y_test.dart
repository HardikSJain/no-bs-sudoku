import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/a11y/tappable.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/home/widgets/stats_strip.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      theme: appTheme(),
      home: Scaffold(body: child),
    ));
    await tester.pumpAndSettle();
  }

  group('durations are spoken, not shown', () {
    test('a clock face is not a length of time', () {
      // A screen reader reads "04:12" as "four twelve".
      expect(spokenDuration(252), '4 minutes 12 seconds');
      expect(spokenDuration(60), '1 minute');
      expect(spokenDuration(1), '1 second');
      expect(spokenDuration(0), 'no time yet');
      expect(spokenDuration(-5), 'no time yet');
    });
  });

  group('the stats strip reads as one control', () {
    testWidgets('carrying its numbers rather than three loose fragments',
        (tester) async {
      await pump(
        tester,
        StatsStrip(
          currentStreak: 4,
          totalSolved: 12,
          avgQuality: 78,
          onTap: () {},
        ),
      );

      final node = tester.getSemantics(find.byType(Tappable));
      expect(node.label, '4 day streak, 12 solved, average quality 78');
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
    });

    testWidgets('and omits the streak when there is not one', (tester) async {
      await pump(
        tester,
        StatsStrip(
          currentStreak: 0,
          totalSolved: 3,
          avgQuality: 50,
          onTap: () {},
        ),
      );
      expect(tester.getSemantics(find.byType(Tappable)).label,
          '3 solved, average quality 50');
    });
  });

  group('difficulty is more than a colour', () {
    test('every label has a spoken name and a ceiling', () {
      // The cards are told apart by colour and a two-word label. Without a
      // semantic name they are four identical buttons.
      for (final d in Difficulty.values) {
        expect(d.name.trim(), isNotEmpty);
        expect(d.maxTier.name.trim(), isNotEmpty);
      }
    });
  });
}
