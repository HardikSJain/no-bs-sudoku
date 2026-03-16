import 'dart:async';

import 'package:drift/drift.dart';

import '../logger.dart';
import 'app_database.dart';

/// All app code talks to StorageService — never to the database directly.
class StorageService {
  final AppDatabase _db;

  StorageService(this._db);

  /// Notifies listeners when saved game state changes (saved/deleted).
  final _savedGameController = StreamController<SavedGame?>.broadcast();
  Stream<SavedGame?> get savedGameStream => _savedGameController.stream;

  static StorageService? _instance;
  static StorageService get instance {
    assert(_instance != null, 'StorageService.init(db) must be called before use');
    return _instance!;
  }
  static void init(AppDatabase db) => _instance = StorageService(db);

  // ── WRITE ──────────────────────────────────────────────────────────

  Future<void> saveRecord(PuzzleRecordsCompanion record) async {
    await _db.into(_db.puzzleRecords).insert(record);
    Log.storage('saveRecord');
  }

  Future<void> updateProfile(PlayerProfilesCompanion profile) async {
    await (_db.update(_db.playerProfiles)
          ..where((t) => t.id.equals(1)))
        .write(profile);
  }

  Future<void> updatePreferences(GamePreferencesTableCompanion prefs) async {
    await (_db.update(_db.gamePreferencesTable)
          ..where((t) => t.id.equals(1)))
        .write(prefs);
  }

  // ── READ ───────────────────────────────────────────────────────────

  Future<PlayerProfile> getProfile() async {
    final row = await (_db.select(_db.playerProfiles)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    // Seed on first access
    await _db.into(_db.playerProfiles).insert(
          PlayerProfilesCompanion.insert(),
        );
    return (_db.select(_db.playerProfiles)
          ..where((t) => t.id.equals(1)))
        .getSingle();
  }

  Future<GamePreferencesTableData> getPreferences() async {
    final row = await (_db.select(_db.gamePreferencesTable)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    await _db.into(_db.gamePreferencesTable).insert(
          GamePreferencesTableCompanion.insert(),
        );
    return (_db.select(_db.gamePreferencesTable)
          ..where((t) => t.id.equals(1)))
        .getSingle();
  }

  Future<List<PuzzleRecord>> getAllRecords() {
    return (_db.select(_db.puzzleRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  Future<List<PuzzleRecord>> getRecordsForDifficulty(String difficulty) {
    return (_db.select(_db.puzzleRecords)
          ..where((t) => t.difficulty.equals(difficulty))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  Future<List<PuzzleRecord>> getRecentRecords(int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    return (_db.select(_db.puzzleRecords)
          ..where((t) => t.completedAt.isBiggerThanValue(cutoff))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  Future<PuzzleRecord?> getBestRecord(String difficulty) {
    return (_db.select(_db.puzzleRecords)
          ..where((t) => t.difficulty.equals(difficulty))
          ..orderBy([(t) => OrderingTerm.asc(t.timeSeconds)])
          ..limit(1))
        .getSingleOrNull();
  }

  Future<bool> hasCompletedDailyToday() async {
    final record = await getTodayDailyRecord();
    return record != null;
  }

  Future<PuzzleRecord?> getTodayDailyRecord() async {
    final today = DateTime.now();
    final todayId =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    return (_db.select(_db.puzzleRecords)
          ..where((t) => t.isDaily.equals(true) & t.puzzleId.equals(todayId))
          ..limit(1))
        .getSingleOrNull();
  }

  // ── STREAK LOGIC ───────────────────────────────────────────────────

  Future<void> updateStreak() async {
    final profile = await getProfile();
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);
    final lastPlayed = profile.lastPlayedDate;

    int newStreak = profile.currentStreak;

    if (lastPlayed != null) {
      final lastDate = DateTime(lastPlayed.year, lastPlayed.month, lastPlayed.day);
      final diff = todayDate.difference(lastDate).inDays;

      if (diff == 0) {
        // Same day — streak unchanged, but still increment totalSolved below
      } else if (diff == 1) {
        newStreak += 1;
      } else if (diff == 2 && canUseStreakFreeze(profile)) {
        // Missed exactly one day — auto-apply freeze
        newStreak += 1;
        Log.streakFreezeUsed();
        await updateProfile(PlayerProfilesCompanion(
          lastFreezeUsedDate: Value(todayDate),
        ));
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

    await updateProfile(PlayerProfilesCompanion(
      currentStreak: Value(newStreak),
      longestStreak: Value(newLongest),
      lastPlayedDate: Value(todayDate),
      totalSolved: Value(profile.totalSolved + 1),
    ));

    Log.streakUpdated(streak: newStreak);
  }

  /// One free freeze per 7-day window.
  bool canUseStreakFreeze(PlayerProfile profile) {
    final lastFreeze = profile.lastFreezeUsedDate;
    if (lastFreeze == null) return true;
    final today = DateTime.now();
    return today.difference(lastFreeze).inDays >= 7;
  }

  Future<void> incrementStarted() async {
    final profile = await getProfile();
    await updateProfile(PlayerProfilesCompanion(
      totalStarted: Value(profile.totalStarted + 1),
    ));
  }

  // ── SYNC QUEUE ─────────────────────────────────────────────────────

  Future<void> addToSyncQueue(String type, String payload) async {
    await _db.into(_db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            type: type,
            payload: payload,
            queuedAt: DateTime.now(),
          ),
        );
  }

  Future<List<SyncQueueItem>> getSyncQueue() {
    return _db.select(_db.syncQueueItems).get();
  }

  Future<void> deleteSyncItem(int id) async {
    await (_db.delete(_db.syncQueueItems)..where((t) => t.id.equals(id))).go();
  }

  Future<void> incrementSyncAttempt(int id) async {
    await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(id)))
        .write(SyncQueueItemsCompanion.custom(
      attempts: _db.syncQueueItems.attempts + const Constant(1),
    ));
  }

  // ── DAILY PUZZLE CACHE ──────────────────────────────────────────────

  Future<DailyPuzzleCacheData?> getCachedDailyPuzzle(String key) {
    return (_db.select(_db.dailyPuzzleCache)
          ..where((t) => t.key.equals(key)))
        .getSingleOrNull();
  }

  Future<void> cacheDailyPuzzle({
    required String key,
    required String clues,
    required String solution,
    required String difficulty,
  }) async {
    await _db.into(_db.dailyPuzzleCache).insertOnConflictUpdate(
          DailyPuzzleCacheCompanion.insert(
            key: key,
            clues: clues,
            solution: solution,
            difficulty: difficulty,
            cachedAt: DateTime.now(),
          ),
        );
  }

  // ── SAVED GAME ─────────────────────────────────────────────────────

  Future<void> saveGame(SavedGamesCompanion game) async {
    await _db.transaction(() async {
      await _db.delete(_db.savedGames).go();
      await _db.into(_db.savedGames).insert(game);
    });
    final saved = await getSavedGame();
    _savedGameController.add(saved);
  }

  Future<SavedGame?> getSavedGame() {
    return (_db.select(_db.savedGames)..limit(1)).getSingleOrNull();
  }

  Future<void> deleteSavedGame() async {
    await _db.delete(_db.savedGames).go();
    _savedGameController.add(null);
  }

  // ── AGGREGATION QUERIES ────────────────────────────────────────────

  Future<int> getRecordCount() async {
    final count = _db.puzzleRecords.id.count();
    final query = _db.selectOnly(_db.puzzleRecords)..addColumns([count]);
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<double> getAvgQualityScore() async {
    final avg = _db.puzzleRecords.qualityScore.avg();
    final query = _db.selectOnly(_db.puzzleRecords)..addColumns([avg]);
    final row = await query.getSingle();
    return row.read(avg) ?? 0.0;
  }

  Future<Map<String, int>> getCountByDifficulty() async {
    final count = _db.puzzleRecords.id.count();
    final diff = _db.puzzleRecords.difficulty;
    final query = _db.selectOnly(_db.puzzleRecords)
      ..addColumns([diff, count])
      ..groupBy([diff]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(diff)!: row.read(count) ?? 0,
    };
  }

  Future<Map<String, double>> getAvgQualityByDifficulty() async {
    final avg = _db.puzzleRecords.qualityScore.avg();
    final diff = _db.puzzleRecords.difficulty;
    final query = _db.selectOnly(_db.puzzleRecords)
      ..addColumns([diff, avg])
      ..groupBy([diff]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(diff)!: row.read(avg) ?? 0.0,
    };
  }

  Future<Map<String, int>> getBestTimeByDifficulty() async {
    final minTime = _db.puzzleRecords.timeSeconds.min();
    final diff = _db.puzzleRecords.difficulty;
    final query = _db.selectOnly(_db.puzzleRecords)
      ..addColumns([diff, minTime])
      ..groupBy([diff]);
    final rows = await query.get();
    return {
      for (final row in rows)
        row.read(diff)!: row.read(minTime) ?? 0,
    };
  }

  Future<int> getDailyCount() async {
    final count = _db.puzzleRecords.id.count();
    final query = _db.selectOnly(_db.puzzleRecords)
      ..addColumns([count])
      ..where(_db.puzzleRecords.isDaily.equals(true));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  // ── DATA MANAGEMENT ────────────────────────────────────────────────

  Future<void> resetAllData() async {
    Log.storage('resetAllData');
    await _db.delete(_db.puzzleRecords).go();
    await _db.delete(_db.dailyPuzzleCache).go();
    await _db.delete(_db.savedGames).go();
    await _db.delete(_db.syncQueueItems).go();
    await updateProfile(PlayerProfilesCompanion(
      displayName: const Value('anon'),
      currentStreak: const Value(0),
      longestStreak: const Value(0),
      lastPlayedDate: const Value(null),
      totalSolved: const Value(0),
      totalStarted: const Value(0),
      preferredDifficulty: const Value('medium'),
      lastFreezeUsedDate: const Value(null),
    ));
  }
}
