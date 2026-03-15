import 'package:drift/drift.dart';

import 'app_database.dart';

/// All app code talks to StorageService — never to the database directly.
class StorageService {
  final AppDatabase _db;

  StorageService(this._db);

  static StorageService? _instance;
  static StorageService get instance => _instance!;
  static void init(AppDatabase db) => _instance = StorageService(db);

  // ── WRITE ──────────────────────────────────────────────────────────

  Future<void> saveRecord(PuzzleRecordsCompanion record) async {
    await _db.into(_db.puzzleRecords).insert(record);
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
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final end = start.add(const Duration(days: 1));
    final count = await (_db.select(_db.puzzleRecords)
          ..where((t) =>
              t.isDaily.equals(true) &
              t.completedAt.isBiggerOrEqualValue(start) &
              t.completedAt.isSmallerThanValue(end)))
        .get();
    return count.isNotEmpty;
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
        // Already counted today
        return;
      } else if (diff == 1) {
        newStreak += 1;
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

  // ── DATA MANAGEMENT ────────────────────────────────────────────────

  Future<void> resetAllData() async {
    await _db.delete(_db.puzzleRecords).go();
    await _db.delete(_db.syncQueueItems).go();
    await updateProfile(PlayerProfilesCompanion(
      displayName: const Value('anon'),
      currentStreak: const Value(0),
      longestStreak: const Value(0),
      lastPlayedDate: const Value(null),
      totalSolved: const Value(0),
      totalStarted: const Value(0),
      preferredDifficulty: const Value('medium'),
    ));
  }
}
