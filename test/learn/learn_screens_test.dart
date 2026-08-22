import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/features/learn/learn_cubit.dart';
import 'package:no_bs_sudoku/features/learn/learn_screen.dart';
import 'package:no_bs_sudoku/features/learn/technique_detail_screen.dart';
import 'package:no_bs_sudoku/features/game/technique_copy.dart';

void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  Future<void> pump(WidgetTester tester, Widget child,
      {String theme = 'paper'}) async {
    // Tall enough that the whole page builds; a ListView does not construct
    // what is below the fold, and these assertions are about content rather
    // than scroll position.
    tester.view.physicalSize = const Size(402 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      theme: appTheme(theme: theme),
      home: BlocProvider(
        create: (_) => LearnCubit(repos.mastery),
        child: child,
      ),
    ));
    await tester.pumpAndSettle();
  }

  group('the library renders', () {
    testWidgets('every technique, grouped by tier', (tester) async {
      await pump(tester, const LearnScreen());

      for (final t in Technique.values) {
        // At least one: the suggested technique also appears in the NEXT UP
        // card, which is the point of that card.
        expect(find.text(t.singular), findsAtLeastNWidgets(1), reason: t.name);
      }
      expect(tester.takeException(), isNull);
    });

    testWidgets('on a narrow phone without overflowing', (tester) async {
      await pump(tester, const LearnScreen());
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('in every theme', (tester) async {
      for (final theme in ['paper', 'dark', 'amoled']) {
        await pump(tester, const LearnScreen(), theme: theme);
        expect(tester.takeException(), isNull, reason: theme);
      }
    });
  });

  group('a technique page renders', () {
    testWidgets('for all twelve, including the undrillable one',
        (tester) async {
      for (final t in Technique.values) {
        await pump(tester, TechniqueDetailScreen(technique: t));
        expect(find.text(t.singular), findsOneWidget, reason: t.name);
        expect(find.text('WHAT TO LOOK FOR'), findsOneWidget, reason: t.name);
        expect(find.text('YOUR RECORD'), findsOneWidget, reason: t.name);

        // The drill button is present exactly when a drill can be built, and
        // its absence is explained rather than silent.
        if (t.isDrillable) {
          expect(find.text('practise this'), findsOneWidget, reason: t.name);
        } else {
          expect(find.text('practise this'), findsNothing, reason: t.name);
          expect(find.textContaining('no drill for this one'), findsOneWidget);
        }
        expect(tester.takeException(), isNull, reason: t.name);
      }
    });

    testWidgets('with no invented accuracy before three drills',
        (tester) async {
      await repos.mastery.recordDrill(Technique.xWing,
          unaided: true, seconds: 10, at: DateTime.utc(2026));
      await pump(tester, const TechniqueDetailScreen(technique: Technique.xWing));

      expect(find.textContaining('% of the time'), findsNothing,
          reason: 'one drill is not a rate');
      expect(find.textContaining('not enough to tell'), findsOneWidget);
    });

    testWidgets('and a rate once there is enough to say', (tester) async {
      for (int i = 0; i < 4; i++) {
        await repos.mastery.recordDrill(Technique.xWing,
            unaided: true, seconds: 10, at: DateTime.utc(2026));
      }
      await pump(tester, const TechniqueDetailScreen(technique: Technique.xWing));
      expect(find.textContaining('100% of the time'), findsOneWidget);
    });
  });
}
