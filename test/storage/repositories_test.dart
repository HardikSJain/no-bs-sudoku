import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:no_bs_sudoku/core/daily_key.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/data_reset_service.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';

void main() {
  late AppDatabase db;
  late Repositories repos;
  late DataResetService reset;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
    reset = DataResetService(
      records: repos.records,
      savedGames: repos.savedGames,
      profiles: repos.profiles,
    );
  });

  tearDown(() async {
    await db.close();
  });

  group('Profile', () {
    test('getProfile seeds default profile on first access', () async {
      final profile = await repos.profiles.getProfile();
      expect(profile.displayName, 'anon');
      expect(profile.currentStreak, 0);
      expect(profile.totalSolved, 0);
    });

    test('updateProfile persists changes', () async {
      await repos.profiles.getProfile(); // seed
      await repos.profiles.updateProfile(
        const PlayerProfilesCompanion(displayName: Value('alice')),
      );
      final profile = await repos.profiles.getProfile();
      expect(profile.displayName, 'alice');
    });
  });

  group('Streak logic', () {
    test('first solve sets streak to 1', () async {
      await repos.profiles.updateStreak();
      final profile = await repos.profiles.getProfile();
      expect(profile.currentStreak, 1);
      expect(profile.totalSolved, 1);
    });

    test('same day solve does not increment streak', () async {
      await repos.profiles.updateStreak();
      await repos.profiles.updateStreak();
      final profile = await repos.profiles.getProfile();
      expect(profile.currentStreak, 1);
      expect(profile.totalSolved, 2);
    });

    test('consecutive day increments streak', () async {
      // Simulate yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await repos.profiles.getProfile(); // seed
      await repos.profiles.updateProfile(PlayerProfilesCompanion(
        currentStreak: const Value(3),
        lastPlayedDate: Value(yesterday),
        totalSolved: const Value(3),
      ));

      await repos.profiles.updateStreak();
      final profile = await repos.profiles.getProfile();
      expect(profile.currentStreak, 4);
      expect(profile.totalSolved, 4);
    });

    test('gap of 2+ days resets streak to 1', () async {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      await repos.profiles.getProfile(); // seed
      await repos.profiles.updateProfile(PlayerProfilesCompanion(
        currentStreak: const Value(10),
        lastPlayedDate: Value(twoDaysAgo),
        totalSolved: const Value(10),
      ));

      await repos.profiles.updateStreak();
      final profile = await repos.profiles.getProfile();
      expect(profile.currentStreak, 1);
      expect(profile.totalSolved, 11);
    });

    test('longestStreak is updated when current exceeds it', () async {
      await repos.profiles.getProfile(); // seed
      await repos.profiles.updateProfile(const PlayerProfilesCompanion(
        currentStreak: Value(5),
        longestStreak: Value(5),
      ));

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await repos.profiles.updateProfile(PlayerProfilesCompanion(
        lastPlayedDate: Value(yesterday),
        totalSolved: const Value(5),
      ));

      await repos.profiles.updateStreak();
      final profile = await repos.profiles.getProfile();
      expect(profile.currentStreak, 6);
      expect(profile.longestStreak, 6);
    });
  });

  group('Streak freeze', () {
    test('canUseStreakFreeze returns true when never used', () async {
      final profile = await repos.profiles.getProfile();
      expect(repos.profiles.canUseStreakFreeze(profile), true);
    });

    test('canUseStreakFreeze returns false within 7 days of use', () async {
      await repos.profiles.getProfile(); // seed
      await repos.profiles.updateProfile(PlayerProfilesCompanion(
        lastFreezeUsedDate: Value(DateTime.now().subtract(const Duration(days: 3))),
      ));
      final profile = await repos.profiles.getProfile();
      expect(repos.profiles.canUseStreakFreeze(profile), false);
    });

    test('canUseStreakFreeze returns true after 7 days', () async {
      await repos.profiles.getProfile(); // seed
      await repos.profiles.updateProfile(PlayerProfilesCompanion(
        lastFreezeUsedDate: Value(DateTime.now().subtract(const Duration(days: 8))),
      ));
      final profile = await repos.profiles.getProfile();
      expect(repos.profiles.canUseStreakFreeze(profile), true);
    });
  });

  group('Records', () {
    test('saveRecord and getAllRecords roundtrip', () async {
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'test1',
        difficulty: 'medium',
        timeSeconds: 300,
        completedAt: DateTime.now(),
      ));

      final records = await repos.records.getAllRecords();
      expect(records.length, 1);
      expect(records.first.puzzleId, 'test1');
      expect(records.first.difficulty, 'medium');
      expect(records.first.timeSeconds, 300);
    });

    test('getBestRecord returns fastest time', () async {
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'slow',
        difficulty: 'easy',
        timeSeconds: 600,
        completedAt: DateTime.now(),
      ));
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'fast',
        difficulty: 'easy',
        timeSeconds: 200,
        completedAt: DateTime.now(),
      ));

      final best = await repos.records.getBestRecord('easy');
      expect(best!.puzzleId, 'fast');
      expect(best.timeSeconds, 200);
    });

    test('getRecordCount returns total count', () async {
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'a', difficulty: 'easy', timeSeconds: 100, completedAt: DateTime.now(),
      ));
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'b', difficulty: 'hard', timeSeconds: 200, completedAt: DateTime.now(),
      ));

      final count = await repos.records.getRecordCount();
      expect(count, 2);
    });

    test('getAvgQualityScore returns average', () async {
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'a', difficulty: 'easy', timeSeconds: 100, completedAt: DateTime.now(),
        qualityScore: const Value(80.0),
      ));
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'b', difficulty: 'easy', timeSeconds: 200, completedAt: DateTime.now(),
        qualityScore: const Value(60.0),
      ));

      final avg = await repos.records.getAvgQualityScore();
      expect(avg, 70.0);
    });
  });

  group('Saved games', () {
    test('saveGame and getSavedGame roundtrip', () async {
      await repos.savedGames.saveGame(SavedGamesCompanion.insert(
        puzzleId: 'test',
        difficulty: 'medium',
        isDaily: false,
        givenCells: '0,1,2',
        solutionCells: '1,2,3',
        boardCells: '0,1,2',
        notes: '{}',
        elapsedSeconds: 120,
        hintsRemaining: 2,
        mistakeCount: 1,
        isNotesMode: false,
        savedAt: DateTime.now(),
      ));

      final saved = await repos.savedGames.getSavedGame();
      expect(saved, isNotNull);
      expect(saved!.puzzleId, 'test');
      expect(saved.elapsedSeconds, 120);
    });

    test('deleteSavedGame removes saved game', () async {
      await repos.savedGames.saveGame(SavedGamesCompanion.insert(
        puzzleId: 'test',
        difficulty: 'medium',
        isDaily: false,
        givenCells: '0,1,2',
        solutionCells: '1,2,3',
        boardCells: '0,1,2',
        notes: '{}',
        elapsedSeconds: 120,
        hintsRemaining: 2,
        mistakeCount: 1,
        isNotesMode: false,
        savedAt: DateTime.now(),
      ));

      await repos.savedGames.deleteSavedGame();
      final saved = await repos.savedGames.getSavedGame();
      expect(saved, isNull);
    });
  });

  group('Preferences', () {
    test('getPreferences returns defaults', () async {
      final prefs = await repos.preferences.getPreferences();
      expect(prefs.autoRemoveNotes, true);
      expect(prefs.highlightMatching, true);
      expect(prefs.showTimer, false);
      expect(prefs.mistakeLimit, 0);
      // The schema default is 'paper'. The committed generated code said
      // 'dark' because build_runner was never re-run after the change, so
      // this assertion was pinned to stale generated output.
      expect(prefs.theme, 'paper');
    });

    test('updatePreferences persists changes', () async {
      await repos.preferences.getPreferences(); // seed
      await repos.preferences.updatePreferences(
        const GamePreferencesTableCompanion(showTimer: Value(true)),
      );
      final prefs = await repos.preferences.getPreferences();
      expect(prefs.showTimer, true);
    });
  });

  group('Daily', () {
    test('hasCompletedDailyToday returns false with no records', () async {
      final result = await repos.records.hasCompletedDailyToday();
      expect(result, false);
    });

    test('hasCompletedDailyToday returns true after daily completion', () async {
      // dailyPuzzleId, not a hand-built local date. The repository asks in
      // UTC, so building the expected id from DateTime.now() made this fail
      // for the 5.5 hours a day when the local date is already tomorrow — a
      // test that is green in CI and red on the author's machine after
      // half past eleven at night.
      final todayId = dailyPuzzleId();
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: todayId,
        difficulty: 'hard',
        isDaily: const Value(true),
        timeSeconds: 300,
        completedAt: DateTime.now(),
      ));

      final result = await repos.records.hasCompletedDailyToday();
      expect(result, true);
    });

    test('getDailyCount returns daily record count', () async {
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'daily1',
        difficulty: 'hard',
        isDaily: const Value(true),
        timeSeconds: 300,
        completedAt: DateTime.now(),
      ));
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'custom1',
        difficulty: 'easy',
        timeSeconds: 200,
        completedAt: DateTime.now(),
      ));

      final count = await repos.records.getDailyCount();
      expect(count, 1);
    });
  });

  group('Data management', () {
    test('resetAllData notifies the saved-game stream', () async {
      await repos.savedGames.saveGame(SavedGamesCompanion.insert(
        puzzleId: 'p1',
        difficulty: 'easy',
        isDaily: false,
        givenCells: '0',
        solutionCells: '0',
        boardCells: '0',
        notes: '{}',
        elapsedSeconds: 10,
        hintsRemaining: 3,
        mistakeCount: 0,
        isNotesMode: false,
        savedAt: DateTime.now(),
      ));

      final emitted = <SavedGame?>[];
      final sub = repos.savedGames.savedGameStream.listen(emitted.add);
      addTearDown(sub.cancel);

      await reset.resetAll();
      await Future<void>.delayed(Duration.zero);

      // The old resetAllData deleted saved_games directly and never fired the
      // stream, so the home screen kept rendering a resume bar for a game that
      // had just been erased.
      expect(emitted, isNotEmpty);
      expect(emitted.last, isNull);
      expect(await repos.savedGames.getSavedGame(), isNull);
    });

    test('resetAllData clears records and resets profile', () async {
      await repos.records.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'test', difficulty: 'easy', timeSeconds: 100, completedAt: DateTime.now(),
      ));
      await repos.profiles.updateProfile(
        const PlayerProfilesCompanion(totalSolved: Value(5), displayName: Value('bob')),
      );

      await reset.resetAll();

      final records = await repos.records.getAllRecords();
      expect(records, isEmpty);

      final profile = await repos.profiles.getProfile();
      expect(profile.displayName, 'anon');
      expect(profile.totalSolved, 0);
    });
  });
}
