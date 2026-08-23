import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/features/stats/stats_screen.dart';
import 'package:no_bs_sudoku/features/stats/widgets/mastery_card.dart';

/// The stats screen end to end, over a real (in-memory) database.
///
/// Mastery arrives from a fifth repository the screen did not used to read,
/// and the failure mode of adding one to a `Future.wait` is an index that
/// quietly points at the wrong result. Rendering the screen is the only way
/// to catch that.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  Future<void> seedSolve({String difficulty = 'medium'}) =>
      repos.records.saveRecord(PuzzleRecordsCompanion(
        puzzleId: Value('t${DateTime.now().microsecondsSinceEpoch}'),
        difficulty: Value(difficulty),
        timeSeconds: const Value(412),
        completedAt: Value(DateTime.now()),
        qualityScore: const Value(72),
        formulaVersion: const Value(2),
        timingVersion: const Value(2),
      ));

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402 * 3, 2600 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: repos.records),
        RepositoryProvider.value(value: repos.profiles),
        RepositoryProvider.value(value: repos.mastery),
      ],
      child: MaterialApp(theme: appTheme(), home: const StatsScreen()),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('mastery sits alongside the other progress', (tester) async {
    await seedSolve();
    await repos.mastery.recordDrill(
      Technique.hiddenSingle,
      unaided: true,
      seconds: 19,
      at: DateTime.now(),
    );

    await pump(tester);

    expect(find.byType(MasteryCard), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the count reflects what is actually in the database',
      (tester) async {
    await seedSolve();
    final drillable = Technique.values.where((t) => t.isDrillable).toList();
    // Six clean drills is the mastery threshold.
    for (var i = 0; i < 6; i++) {
      await repos.mastery.recordDrill(
        drillable.first,
        unaided: true,
        seconds: 12,
        at: DateTime.now(),
      );
    }

    await pump(tester);

    expect(find.text('1 of ${drillable.length}'), findsOneWidget);
  });

  testWidgets('with no drills yet it still renders, at zero', (tester) async {
    await seedSolve();
    await pump(tester);

    final total = Technique.values.where((t) => t.isDrillable).length;
    expect(find.text('0 of $total'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the empty screen stays empty — no card before a first solve',
      (tester) async {
    await pump(tester);
    expect(find.byType(MasteryCard), findsNothing);
  });
}
