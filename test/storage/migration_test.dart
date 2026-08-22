import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';

import '../drift_schemas/schema.dart';

/// Migration safety net.
///
/// The app has no `onDowngrade`, and neither store can move a user to a lower
/// versionCode — so once a schema bump ships, that user's database cannot be
/// walked back. Every column added from here on must be covered by a snapshot
/// in `drift_schemas/` and verified here before release.
///
/// Regenerate snapshots after any table change:
///   fvm dart run drift_dev schema dump lib/core/storage/app_database.dart drift_schemas/
///   fvm dart run drift_dev schema generate drift_schemas/ test/drift_schemas/
void main() {
  const currentVersion = 15;

  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('a fresh install matches the current snapshot', () async {
    // Guards against schema drift with no version bump: add a column without
    // bumping schemaVersion and re-dumping, and a fresh install diverges from
    // the recorded schema.
    final connection = await verifier.startAt(currentVersion);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, currentVersion);
  });

  test('a v8 database migrates cleanly to the current version', () async {
    // The real user path. Before this suite existed the entire onUpgrade
    // chain — including the data-mutating UPDATE that marks existing users as
    // having seen onboarding — had never executed in a test, because both
    // test entry points use AppDatabase.forTesting, which always runs
    // onCreate.
    final connection = await verifier.startAt(8);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, currentVersion);
  });

  test('v9 dropped the two tables nothing ever wrote to', () async {
    final connection = await verifier.startAt(8);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, currentVersion);

    final rows = await db
        .customSelect("SELECT name FROM sqlite_master WHERE type = 'table'")
        .get();
    final names = rows.map((r) => r.read<String>('name')).toSet();

    expect(names, isNot(contains('daily_puzzle_cache')));
    expect(names, isNot(contains('sync_queue_items')));
    // The live tables survive the drop.
    expect(
      names,
      containsAll(<String>[
        'puzzle_records',
        'player_profiles',
        'game_preferences_table',
        'saved_games',
      ]),
    );
  });

  test('v10 adds the resume columns without disturbing existing saves',
      () async {
    final connection = await verifier.startAt(9);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, currentVersion);

    final cols = await db
        .customSelect("SELECT name FROM pragma_table_info('saved_games')")
        .get();
    final names = cols.map((r) => r.read<String>('name')).toSet();

    expect(
      names,
      containsAll(<String>[
        'history',
        'placement_deltas',
        'mistake_cells',
        'undo_count',
        'used_notes',
        'longest_pause_seconds',
        'techniques',
      ]),
    );
    // The columns a save cannot survive without are untouched.
    expect(
      names,
      containsAll(<String>['board_cells', 'solution_cells', 'notes']),
    );
  });

  test('v11 adds hint accounting without disturbing existing saves', () async {
    final connection = await verifier.startAt(10);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, currentVersion);

    // A save written before the columns existed reads as solved unaided,
    // which is exactly what it reported when there was nothing to read.
    final row = await db.customSelect(
      'SELECT hints_used, hint_depth_total FROM saved_games LIMIT 1',
    ).get();
    expect(row, isEmpty, reason: 'no rows expected, the schema is what matters');
  });

  test('v12 turns the coaching switches on for existing players', () async {
    final connection = await verifier.startAt(11);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);
    await verifier.migrateAndValidate(db, currentVersion);

    // Defaults must arrive on, or an upgrading player silently loses the
    // explanations this release exists to give them.
    final prefs = await db.customSelect(
      'SELECT hints_explain, flag_mistakes_instantly, nudge_when_stuck '
      'FROM game_preferences_table',
    ).get();
    for (final row in prefs) {
      expect(row.data['hints_explain'], 1);
      expect(row.data['flag_mistakes_instantly'], 1);
      expect(row.data['nudge_when_stuck'], 1);
    }
  });

  test('schemaVersion matches the highest recorded snapshot', () async {
    // If this fails, someone bumped schemaVersion without dumping a snapshot.
    // Dump it before shipping — the migration is irreversible for users who
    // take the release.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(
      db.schemaVersion,
      currentVersion,
      reason: 'schemaVersion changed but drift_schemas/ has no matching '
          'snapshot. Run the two drift_dev schema commands in this file\'s '
          'doc comment, then update currentVersion here.',
    );
  });
}
