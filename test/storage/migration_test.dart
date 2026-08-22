import 'package:drift/native.dart';
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';

import '../drift_schemas/schema.dart';

/// Migration safety net.
///
/// The app has no `onDowngrade`, and neither Play nor the App Store can move a
/// user to a lower versionCode — so once a schema bump ships, that user's
/// database cannot be walked back. Every column added from here on must be
/// covered by a snapshot in `drift_schemas/` and verified here before release.
///
/// Regenerate snapshots after any table change:
///   fvm dart run drift_dev schema dump lib/core/storage/app_database.dart drift_schemas/
///   fvm dart run drift_dev schema generate drift_schemas/ test/drift_schemas/
void main() {
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  test('onCreate produces exactly the v8 snapshot', () async {
    // Guards against schema drift with no version bump: if someone adds a
    // column to a table without bumping schemaVersion and re-dumping, a fresh
    // install diverges from the recorded schema and this fails.
    final connection = await verifier.startAt(8);
    final db = AppDatabase.forTesting(connection);
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 8);
  });

  test('schemaVersion matches the highest recorded snapshot', () async {
    // If this fails, someone bumped schemaVersion without dumping a snapshot.
    // Dump it before shipping — the migration is irreversible for users who
    // take the release.
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    expect(
      db.schemaVersion,
      8,
      reason: 'schemaVersion changed but drift_schemas/ has no matching '
          'snapshot. Run the two drift_dev schema commands in this file\'s '
          'doc comment, then update this expectation.',
    );
  });
}
