import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/daily_key.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/features/daily/daily_archive_cubit.dart';
import 'package:no_bs_sudoku/features/game/game_state.dart';
import 'package:no_bs_sudoku/features/daily/daily_archive_screen.dart';

/// The archive hands out a puzzle for a past date. Nothing was stored to make
/// that possible — the same date has always produced the same grid — so the
/// tests that matter are about the window it offers and the state it shows
/// for each day.
void main() {
  group('the window', () {
    test('is ninety days long and ends today', () {
      final dates = dailyArchiveDates();
      expect(dates.length, dailyArchiveDays);
      expect(dates.last, todayUtc());
      expect(dates.first,
          todayUtc().subtract(Duration(days: dailyArchiveDays - 1)));
      // Strictly ascending, one day apart, no gaps or repeats.
      for (var i = 1; i < dates.length; i++) {
        expect(dates[i].difference(dates[i - 1]).inDays, 1);
      }
    });

    test('does not include tomorrow', () {
      expect(isInDailyArchive(todayUtc().add(const Duration(days: 1))), isFalse);
      expect(isInDailyArchive(todayUtc()), isTrue);
    });

    test('and stops at its far edge', () {
      final oldest = todayUtc().subtract(Duration(days: dailyArchiveDays - 1));
      expect(isInDailyArchive(oldest), isTrue);
      expect(isInDailyArchive(oldest.subtract(const Duration(days: 1))),
          isFalse);
    });
  });

  group('parsing a date out of a route', () {
    test('accepts the ids the app writes', () {
      expect(parseDailyPuzzleId('2026-08-22'), DateTime.utc(2026, 8, 22));
      expect(parseDailyPuzzleId(dailyPuzzleId(DateTime.utc(2025, 1, 1))),
          DateTime.utc(2025, 1, 1));
    });

    test('and refuses everything else', () {
      // A route parameter is user input, and DateTime.utc will happily roll
      // the 31st of February into March rather than complain.
      expect(parseDailyPuzzleId('2026-02-31'), isNull);
      expect(parseDailyPuzzleId('2026-13-01'), isNull);
      expect(parseDailyPuzzleId('2026-8-22'), isNull);
      expect(parseDailyPuzzleId('import'), isNull);
      expect(parseDailyPuzzleId(''), isNull);
      expect(parseDailyPuzzleId('2026-08-22T00:00'), isNull);
    });
  });

  group('the one-letter tier', () {
    test('is unique, so colour is never the only difference', () {
      final letters = Difficulty.values.map((d) => d.letter).toList();
      expect(letters.toSet().length, letters.length,
          reason: 'two tiers sharing a letter leaves colour doing the work: '
              '$letters');
      for (final d in Difficulty.values) {
        expect(d.letter.length, 1, reason: d.name);
      }
    });
  });

  group('the game knows which daily it is', () {
    GameState stateFor(String puzzleId, {bool isDaily = true}) => GameState(
          board: SudokuBoard.empty(),
          puzzle: SudokuBoard.empty(),
          solution: SudokuBoard.empty(),
          givenCells: const {},
          puzzleId: puzzleId,
          difficulty: Difficulty.hard,
          isDaily: isDaily,
        );

    test('a past daily names its date', () {
      final past = todayUtc().subtract(const Duration(days: 4));
      expect(stateFor(dailyPuzzleId(past)).archiveDate, past);
    });

    test("today's does not — the home card already said so", () {
      expect(stateFor(dailyPuzzleId(todayUtc())).archiveDate, isNull);
    });

    test('and an ordinary puzzle never does', () {
      expect(stateFor('1750000000000_42', isDaily: false).archiveDate, isNull);
      // A non-daily whose id happens to look like a date is still not one.
      expect(stateFor('2026-08-01', isDaily: false).archiveDate, isNull);
    });
  });

  group('the calendar', () {
    late AppDatabase db;
    late Repositories repos;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repos = Repositories(db);
    });

    tearDown(() async => db.close());

    Future<void> seedDaily(DateTime date, {int seconds = 300}) =>
        repos.records.saveRecord(PuzzleRecordsCompanion(
          puzzleId: Value(dailyPuzzleId(date)),
          difficulty: Value(SudokuGenerator.dailyDifficulty(date).name),
          isDaily: const Value(true),
          timeSeconds: Value(seconds),
          completedAt: Value(date),
        ));

    Future<DailyArchiveState> loaded() async {
      final cubit = DailyArchiveCubit(
        records: repos.records,
        savedGames: repos.savedGames,
      );
      addTearDown(cubit.close);
      // The constructor kicks off load(); wait for the emit.
      return cubit.stream.firstWhere((s) => s.loaded);
    }

    test('shows one entry per day in the window', () async {
      final state = await loaded();
      expect(state.days.length, dailyArchiveDays);
      expect(state.days.last.isToday, isTrue);
    });

    test('the tier is the weekday rotation, not a generated puzzle', () async {
      final state = await loaded();
      for (final day in state.days) {
        expect(day.difficulty, SudokuGenerator.dailyDifficulty(day.date),
            reason: '${day.date} showed ${day.difficulty.name}');
      }
    });

    test('a solved day carries its record', () async {
      final target = todayUtc().subtract(const Duration(days: 3));
      await seedDaily(target, seconds: 421);

      final state = await loaded();
      final day = state.days.firstWhere((d) => d.date == target);
      expect(day.isSolved, isTrue);
      expect(day.record!.timeSeconds, 421);
      expect(state.solvedCount, 1);
    });

    test('today does not count as missed until it is over', () async {
      final state = await loaded();
      expect(state.missedCount, dailyArchiveDays - 1);
    });

    test('a record outside the window is ignored, not crashed on', () async {
      await seedDaily(todayUtc().subtract(const Duration(days: 400)));
      final state = await loaded();
      expect(state.solvedCount, 0);
      expect(state.days.length, dailyArchiveDays);
    });

    test('the saved slot marks exactly one day in progress', () async {
      final target = todayUtc().subtract(const Duration(days: 2));
      await repos.savedGames.saveGame(SavedGamesCompanion(
        puzzleId: Value(dailyPuzzleId(target)),
        difficulty: const Value('hard'),
        isDaily: const Value(true),
        givenCells: Value(List.filled(81, 0).join(',')),
        solutionCells: Value(List.filled(81, 1).join(',')),
        boardCells: Value(List.filled(81, 0).join(',')),
        notes: const Value(''),
        elapsedSeconds: const Value(60),
        hintsRemaining: const Value(0),
        mistakeCount: const Value(0),
        isNotesMode: const Value(false),
        savedAt: Value(DateTime.now()),
      ));

      final state = await loaded();
      expect(state.days.where((d) => d.inProgress).length, 1);
      expect(state.days.firstWhere((d) => d.inProgress).date, target);
    });

    test('solving an old one does not mark today done', () async {
      // The archive is a catch-up, not a way to tick off today without
      // playing today. The join key is the puzzle's own date, so this holds
      // as long as nobody starts keying dailies by when they were finished.
      await seedDaily(todayUtc().subtract(const Duration(days: 1)));

      expect(await repos.records.hasCompletedDailyToday(), isFalse);

      await seedDaily(todayUtc());
      expect(await repos.records.hasCompletedDailyToday(), isTrue);
    });

    test('but it does count towards the daily total', () async {
      await seedDaily(todayUtc().subtract(const Duration(days: 1)));
      await seedDaily(todayUtc().subtract(const Duration(days: 2)));
      expect(await repos.records.getDailyCount(), 2);
    });

    testWidgets('renders every day without overflowing', (tester) async {
      await seedDaily(todayUtc().subtract(const Duration(days: 5)));
      tester.view.physicalSize = const Size(320 * 3, 900 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: repos.records),
          RepositoryProvider.value(value: repos.savedGames),
        ],
        child: MaterialApp(
          theme: appTheme(),
          home: const DailyArchiveScreen(),
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.text('past dailies.'), findsOneWidget);
      expect(find.textContaining('the last $dailyArchiveDays days'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
