import 'package:drift/drift.dart';

import '../../daily_key.dart';
import '../../logger.dart';
import '../app_database.dart';

/// Everything that reads or writes `puzzle_records`.
class PuzzleRecordRepository {
  PuzzleRecordRepository(this._db);

  final AppDatabase _db;

  /// Returns the autoincrement id of the inserted row.
  ///
  /// The old signature discarded it, which is why anything computed *after*
  /// the row is written (technique attribution, for one) had nowhere to put
  /// its result and had to live on the profile aggregate instead.
  Future<int> saveRecord(PuzzleRecordsCompanion record) async {
    final id = await _db.into(_db.puzzleRecords).insert(record);
    Log.storage('saveRecord');
    return id;
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
    return await getTodayDailyRecord() != null;
  }

  Future<PuzzleRecord?> getTodayDailyRecord() {
    final todayId = dailyPuzzleId();
    return (_db.select(_db.puzzleRecords)
          ..where((t) => t.isDaily.equals(true) & t.puzzleId.equals(todayId))
          ..limit(1))
        .getSingleOrNull();
  }

  // ── aggregates ─────────────────────────────────────────────────────

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
    return {for (final row in rows) row.read(diff)!: row.read(count) ?? 0};
  }

  Future<Map<String, double>> getAvgQualityByDifficulty() async {
    final avg = _db.puzzleRecords.qualityScore.avg();
    final diff = _db.puzzleRecords.difficulty;
    final query = _db.selectOnly(_db.puzzleRecords)
      ..addColumns([diff, avg])
      ..groupBy([diff]);
    final rows = await query.get();
    return {for (final row in rows) row.read(diff)!: row.read(avg) ?? 0.0};
  }

  Future<Map<String, int>> getBestTimeByDifficulty() async {
    final minTime = _db.puzzleRecords.timeSeconds.min();
    final diff = _db.puzzleRecords.difficulty;
    final query = _db.selectOnly(_db.puzzleRecords)
      ..addColumns([diff, minTime])
      ..groupBy([diff]);
    final rows = await query.get();
    return {for (final row in rows) row.read(diff)!: row.read(minTime) ?? 0};
  }

  Future<int> getDailyCount() async {
    final count = _db.puzzleRecords.id.count();
    final query = _db.selectOnly(_db.puzzleRecords)
      ..addColumns([count])
      ..where(_db.puzzleRecords.isDaily.equals(true));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  /// Every inter-placement gap this player has recorded at [difficulty],
  /// from records whose timing can be trusted.
  ///
  /// Version 1 records measured against the wall clock, so one backgrounded
  /// session contributed a gap of hours. Pooling those would push a personal
  /// p90 so high the stuck nudge could never fire again.
  Future<List<int>> trustedSolveTimeDeltas(String difficulty) async {
    final rows = await (_db.select(_db.puzzleRecords)
          ..where((t) =>
              t.difficulty.equals(difficulty) &
              t.timingVersion.isBiggerOrEqualValue(2)))
        .get();
    return [
      for (final row in rows)
        for (final part in row.solveTimes.split(',')) ?int.tryParse(part),
    ];
  }

  /// How many of this player's records at [difficulty] have trustworthy
  /// timing. Below three there is not enough to build a personal threshold.
  Future<int> trustedRecordCount(String difficulty) async {
    final count = _db.puzzleRecords.id.count();
    final query = _db.selectOnly(_db.puzzleRecords)
      ..addColumns([count])
      ..where(_db.puzzleRecords.difficulty.equals(difficulty) &
          _db.puzzleRecords.timingVersion.isBiggerOrEqualValue(2));
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  Future<void> deleteAll() => _db.delete(_db.puzzleRecords).go();
}
