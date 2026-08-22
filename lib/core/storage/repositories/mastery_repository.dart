import 'package:drift/drift.dart';

import '../../../engine/deduction/deduction.dart';
import '../../../features/learn/mastery.dart';
import '../app_database.dart';

/// Everything that reads or writes per-technique mastery.
class MasteryRepository {
  MasteryRepository(this._db);

  final AppDatabase _db;

  Future<MasteryProfile> getProfile() async {
    final rows = await _db.select(_db.techniqueMasteryTable).get();
    final byName = {for (final t in Technique.values) t.name: t};
    final out = <Technique, TechniqueMastery>{};
    for (final row in rows) {
      // A row written by a build that knew a technique this one does not is
      // skipped rather than crashing the library screen.
      final technique = byName[row.technique];
      if (technique == null) continue;
      out[technique] = TechniqueMastery(
        technique: technique,
        drillsAttempted: row.drillsAttempted,
        drillsUnaided: row.drillsUnaided,
        encountered: row.encountered,
        assisted: row.assisted,
        bestSeconds: row.bestSeconds,
        lastPractisedAt: row.lastPractisedAt,
      );
    }
    return MasteryProfile(out);
  }

  Future<TechniqueMastery> get(Technique technique) async =>
      (await getProfile())[technique];

  /// Records a finished drill.
  ///
  /// [unaided] means no hint was taken. That is the whole measurement — a
  /// drill where the app pointed at the answer says nothing about whether the
  /// player can spot the pattern.
  Future<void> recordDrill(
    Technique technique, {
    required bool unaided,
    required int seconds,
    required DateTime at,
  }) async {
    final current = await get(technique);
    final best = current.bestSeconds;
    await _upsert(
      technique,
      TechniqueMasteryTableCompanion(
        technique: Value(technique.name),
        drillsAttempted: Value(current.drillsAttempted + 1),
        drillsUnaided: Value(current.drillsUnaided + (unaided ? 1 : 0)),
        // Only a clean solve sets a best time. A hinted one is not a time.
        bestSeconds: Value(
          unaided && (best == null || seconds < best) ? seconds : best,
        ),
        lastPractisedAt: Value(at),
      ),
    );
  }

  /// Records that a completed puzzle needed these techniques.
  ///
  /// Weak on purpose: it says the puzzle required the technique, not that the
  /// player recognised it. It is what stops the library reading "not met yet"
  /// for someone who has solved fifty puzzles full of pointing pairs.
  Future<void> recordEncountered(Iterable<Technique> techniques) async {
    for (final technique in techniques.toSet()) {
      final current = await get(technique);
      await _upsert(
        technique,
        TechniqueMasteryTableCompanion(
          technique: Value(technique.name),
          encountered: Value(current.encountered + 1),
        ),
      );
    }
  }

  /// Records that a hint explained this technique.
  Future<void> recordAssisted(Technique technique) async {
    final current = await get(technique);
    await _upsert(
      technique,
      TechniqueMasteryTableCompanion(
        technique: Value(technique.name),
        assisted: Value(current.assisted + 1),
      ),
    );
  }

  Future<void> _upsert(
          Technique technique, TechniqueMasteryTableCompanion values) =>
      _db.into(_db.techniqueMasteryTable).insertOnConflictUpdate(values);

  /// Part of "delete all my data". A mastery profile left behind after a
  /// factory reset is exactly the kind of thing that erodes trust.
  Future<void> deleteAll() => _db.delete(_db.techniqueMasteryTable).go();
}
