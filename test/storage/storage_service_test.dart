import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/storage_service.dart';

void main() {
  late AppDatabase db;
  late StorageService storage;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    storage = StorageService(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Profile', () {
    test('getProfile seeds default profile on first access', () async {
      final profile = await storage.getProfile();
      expect(profile.displayName, 'anon');
      expect(profile.currentStreak, 0);
      expect(profile.totalSolved, 0);
    });

    test('updateProfile persists changes', () async {
      await storage.getProfile(); // seed
      await storage.updateProfile(
        const PlayerProfilesCompanion(displayName: Value('alice')),
      );
      final profile = await storage.getProfile();
      expect(profile.displayName, 'alice');
    });
  });

  group('Streak logic', () {
    test('first solve sets streak to 1', () async {
      await storage.updateStreak();
      final profile = await storage.getProfile();
      expect(profile.currentStreak, 1);
      expect(profile.totalSolved, 1);
    });

    test('same day solve does not increment streak', () async {
      await storage.updateStreak();
      await storage.updateStreak();
      final profile = await storage.getProfile();
      expect(profile.currentStreak, 1);
      expect(profile.totalSolved, 2);
    });

    test('consecutive day increments streak', () async {
      // Simulate yesterday
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await storage.getProfile(); // seed
      await storage.updateProfile(PlayerProfilesCompanion(
        currentStreak: const Value(3),
        lastPlayedDate: Value(yesterday),
        totalSolved: const Value(3),
      ));

      await storage.updateStreak();
      final profile = await storage.getProfile();
      expect(profile.currentStreak, 4);
      expect(profile.totalSolved, 4);
    });

    test('gap of 2+ days resets streak to 1', () async {
      final twoDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      await storage.getProfile(); // seed
      await storage.updateProfile(PlayerProfilesCompanion(
        currentStreak: const Value(10),
        lastPlayedDate: Value(twoDaysAgo),
        totalSolved: const Value(10),
      ));

      await storage.updateStreak();
      final profile = await storage.getProfile();
      expect(profile.currentStreak, 1);
      expect(profile.totalSolved, 11);
    });

    test('longestStreak is updated when current exceeds it', () async {
      await storage.getProfile(); // seed
      await storage.updateProfile(const PlayerProfilesCompanion(
        currentStreak: Value(5),
        longestStreak: Value(5),
      ));

      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      await storage.updateProfile(PlayerProfilesCompanion(
        lastPlayedDate: Value(yesterday),
        totalSolved: const Value(5),
      ));

      await storage.updateStreak();
      final profile = await storage.getProfile();
      expect(profile.currentStreak, 6);
      expect(profile.longestStreak, 6);
    });
  });

  group('Streak freeze', () {
    test('canUseStreakFreeze returns true when never used', () async {
      final profile = await storage.getProfile();
      expect(storage.canUseStreakFreeze(profile), true);
    });

    test('canUseStreakFreeze returns false within 7 days of use', () async {
      await storage.getProfile(); // seed
      await storage.updateProfile(PlayerProfilesCompanion(
        lastFreezeUsedDate: Value(DateTime.now().subtract(const Duration(days: 3))),
      ));
      final profile = await storage.getProfile();
      expect(storage.canUseStreakFreeze(profile), false);
    });

    test('canUseStreakFreeze returns true after 7 days', () async {
      await storage.getProfile(); // seed
      await storage.updateProfile(PlayerProfilesCompanion(
        lastFreezeUsedDate: Value(DateTime.now().subtract(const Duration(days: 8))),
      ));
      final profile = await storage.getProfile();
      expect(storage.canUseStreakFreeze(profile), true);
    });
  });

  group('Records', () {
    test('saveRecord and getAllRecords roundtrip', () async {
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'test1',
        difficulty: 'medium',
        timeSeconds: 300,
        completedAt: DateTime.now(),
      ));

      final records = await storage.getAllRecords();
      expect(records.length, 1);
      expect(records.first.puzzleId, 'test1');
      expect(records.first.difficulty, 'medium');
      expect(records.first.timeSeconds, 300);
    });

    test('getBestRecord returns fastest time', () async {
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'slow',
        difficulty: 'easy',
        timeSeconds: 600,
        completedAt: DateTime.now(),
      ));
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'fast',
        difficulty: 'easy',
        timeSeconds: 200,
        completedAt: DateTime.now(),
      ));

      final best = await storage.getBestRecord('easy');
      expect(best!.puzzleId, 'fast');
      expect(best.timeSeconds, 200);
    });

    test('getRecordCount returns total count', () async {
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'a', difficulty: 'easy', timeSeconds: 100, completedAt: DateTime.now(),
      ));
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'b', difficulty: 'hard', timeSeconds: 200, completedAt: DateTime.now(),
      ));

      final count = await storage.getRecordCount();
      expect(count, 2);
    });

    test('getAvgQualityScore returns average', () async {
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'a', difficulty: 'easy', timeSeconds: 100, completedAt: DateTime.now(),
        qualityScore: const Value(80.0),
      ));
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'b', difficulty: 'easy', timeSeconds: 200, completedAt: DateTime.now(),
        qualityScore: const Value(60.0),
      ));

      final avg = await storage.getAvgQualityScore();
      expect(avg, 70.0);
    });
  });

  group('Saved games', () {
    test('saveGame and getSavedGame roundtrip', () async {
      await storage.saveGame(SavedGamesCompanion.insert(
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

      final saved = await storage.getSavedGame();
      expect(saved, isNotNull);
      expect(saved!.puzzleId, 'test');
      expect(saved.elapsedSeconds, 120);
    });

    test('deleteSavedGame removes saved game', () async {
      await storage.saveGame(SavedGamesCompanion.insert(
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

      await storage.deleteSavedGame();
      final saved = await storage.getSavedGame();
      expect(saved, isNull);
    });
  });

  group('Preferences', () {
    test('getPreferences returns defaults', () async {
      final prefs = await storage.getPreferences();
      expect(prefs.autoRemoveNotes, true);
      expect(prefs.highlightMatching, true);
      expect(prefs.showTimer, false);
      expect(prefs.mistakeLimit, 0);
      expect(prefs.theme, 'dark');
    });

    test('updatePreferences persists changes', () async {
      await storage.getPreferences(); // seed
      await storage.updatePreferences(
        const GamePreferencesTableCompanion(showTimer: Value(true)),
      );
      final prefs = await storage.getPreferences();
      expect(prefs.showTimer, true);
    });
  });

  group('Daily', () {
    test('hasCompletedDailyToday returns false with no records', () async {
      final result = await storage.hasCompletedDailyToday();
      expect(result, false);
    });

    test('hasCompletedDailyToday returns true after daily completion', () async {
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'daily',
        difficulty: 'hard',
        isDaily: const Value(true),
        timeSeconds: 300,
        completedAt: DateTime.now(),
      ));

      final result = await storage.hasCompletedDailyToday();
      expect(result, true);
    });

    test('getDailyCount returns daily record count', () async {
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'daily1',
        difficulty: 'hard',
        isDaily: const Value(true),
        timeSeconds: 300,
        completedAt: DateTime.now(),
      ));
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'custom1',
        difficulty: 'easy',
        timeSeconds: 200,
        completedAt: DateTime.now(),
      ));

      final count = await storage.getDailyCount();
      expect(count, 1);
    });
  });

  group('Data management', () {
    test('resetAllData clears records and resets profile', () async {
      await storage.saveRecord(PuzzleRecordsCompanion.insert(
        puzzleId: 'test', difficulty: 'easy', timeSeconds: 100, completedAt: DateTime.now(),
      ));
      await storage.updateProfile(
        const PlayerProfilesCompanion(totalSolved: Value(5), displayName: Value('bob')),
      );

      await storage.resetAllData();

      final records = await storage.getAllRecords();
      expect(records, isEmpty);

      final profile = await storage.getProfile();
      expect(profile.displayName, 'anon');
      expect(profile.totalSolved, 0);
    });
  });
}
