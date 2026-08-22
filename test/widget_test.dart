import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/app.dart';
import 'package:no_bs_sudoku/core/routing/app_router.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';

void main() {
  late AppDatabase db;
  late Repositories repositories;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repositories = Repositories(db);
    // The router is a cached global — without this, a test that ends on /home
    // leaves the next test mounted there instead of replaying the splash.
    resetAppRouter();
  });

  tearDown(() async {
    await db.close();
  });

  // Splash waits 2s then routes to /home or /onboarding depending on
  // hasSeenOnboarding (splash_screen.dart:24-28). Settle past that.
  Future<void> settlePastSplash(WidgetTester tester) =>
      tester.pumpAndSettle(const Duration(seconds: 3));

  testWidgets('returning user boots to splash then lands on home',
      (tester) async {
    // A fresh database defaults hasSeenOnboarding to false, which would route
    // to /onboarding. Mark it seen to exercise the returning-user path.
    await repositories.preferences.markOnboardingSeen();

    await tester.pumpWidget(App(repositories: repositories));
    await tester.pump();

    // Splash is up; the home daily card is not.
    expect(find.text('just sudoku.'), findsOneWidget);
    expect(find.textContaining('DAILY ·'), findsNothing);

    await settlePastSplash(tester);

    // Home renders the daily card header, e.g. "DAILY · AUG 22"
    // (daily_puzzle_card.dart:82).
    expect(find.textContaining('DAILY ·'), findsOneWidget);
  });

  testWidgets('first run routes to onboarding, not home', (tester) async {
    // Fresh database, onboarding never seen — the default first-run path.
    await tester.pumpWidget(App(repositories: repositories));
    await tester.pump();

    expect(find.text('just sudoku.'), findsOneWidget);

    await settlePastSplash(tester);

    // Assert onboarding is actually shown, not merely that home is absent —
    // an absence-only assertion would pass even if the app crashed.
    expect(find.text('how to play.'), findsOneWidget);
    expect(find.textContaining('DAILY ·'), findsNothing);
  });
}
