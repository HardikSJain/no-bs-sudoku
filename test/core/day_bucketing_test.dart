import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:no_bs_sudoku/core/daily_key.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/home/widgets/daily_puzzle_card.dart';

/// Which day it is gets decided in exactly one place.
///
/// `daily_key.dart` exists because the app disagreed with itself about that,
/// and its own doc names the sites it converted. Four more were missed and all
/// four were the same bug: the daily card printed a local date while serving a
/// UTC puzzle — five and a half hours of every day in India — and the heatmap,
/// the sparkline and the daily insight each counted days on a different clock
/// from the streak.
///
/// The behaviour is checked where it renders. The rest is a source guard,
/// which is how this repo already pins the mistakes it has made once: a
/// widget that builds its own `DateTime(y, m, d)` is bucketing by local time,
/// and that is the whole bug.
void main() {
  group('the daily card names the day the puzzle is keyed to', () {
    testWidgets('and that day is UTC, not the device', (tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: appTheme(),
        home: Scaffold(
          body: DailyPuzzleCard(
            completed: false,
            difficulty: Difficulty.easy,
            puzzleNum: 1,
          ),
        ),
      ));
      await tester.pumpAndSettle();

      final expected =
          DateFormat('MMM d').format(todayUtc()).toUpperCase();
      expect(find.textContaining(expected), findsOneWidget,
          reason: 'the card must name the same day `dailyPuzzleId` does — '
              'east of Greenwich a local date names tomorrow while the app '
              'serves today\'s puzzle');
    });
  });

  group('nothing buckets a day on its own', () {
    // Screens that group records by day. Each one has to go through
    // daily_key, or it disagrees with the streak.
    const dayBucketing = [
      'lib/features/stats/widgets/activity_heatmap.dart',
      'lib/features/stats/widgets/performance_sparkline.dart',
      'lib/core/intelligence/intelligence_engine.dart',
      'lib/features/home/widgets/daily_puzzle_card.dart',
    ];

    test('every day-bucketed screen reads the day from daily_key', () {
      final offenders = <String>[];
      for (final path in dayBucketing) {
        final source = File(path).readAsStringSync();
        if (!source.contains('daily_key.dart')) {
          offenders.add('$path does not import daily_key');
        }
        // `DateTime(y, m, d)` with no `.utc` is a local midnight.
        if (RegExp(r'DateTime\(\s*now\.year').hasMatch(source) ||
            RegExp(r'DateTime\(\s*\w+\.completedAt\.year').hasMatch(source)) {
          offenders.add('$path builds a local midnight of its own');
        }
      }
      expect(offenders, isEmpty,
          reason: 'use todayUtc() and dayUtc(), so the heatmap, the streak '
              'and the daily agree about what today is:\n  '
              '${offenders.join('\n  ')}');
    });
  });
}
