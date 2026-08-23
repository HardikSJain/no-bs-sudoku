import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/features/game/technique_copy.dart';
import 'package:no_bs_sudoku/features/learn/mastery.dart';
import 'package:no_bs_sudoku/features/stats/widgets/mastery_card.dart';

/// The card on the stats screen that says how much of the game you know.
///
/// It is the only place on that screen with a variable-length sentence in it,
/// so the failure mode is layout: a long "next step" line on a narrow phone
/// at a large text scale. These pin that down, because a stats screen that
/// overflows is worse than one without the card.
void main() {
  MasteryProfile profileOf(Map<Technique, TechniqueMastery> m) =>
      MasteryProfile(m);

  TechniqueMastery mastered(Technique t) => TechniqueMastery(
        technique: t,
        drillsAttempted: 8,
        drillsUnaided: 8,
      );

  Future<void> pump(
    WidgetTester tester,
    MasteryProfile profile, {
    Size size = const Size(402, 874),
    double textScale = 1.0,
  }) async {
    tester.view.physicalSize = Size(size.width * 3, size.height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: MasteryCard(profile: profile),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/learn',
          builder: (_, _) => const Scaffold(body: Text('the library')),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(
      theme: appTheme(),
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('a fresh player is told none are mastered and what to try',
      (tester) async {
    await pump(tester, const MasteryProfile({}));

    final total = Technique.values.where((t) => t.isDrillable).length;
    expect(find.text('0 of $total'), findsOneWidget);
    expect(find.textContaining('next up:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the suggestion is the easiest technique not yet practised',
      (tester) async {
    final easiest = ([...Technique.values]
          ..sort((a, b) => a.rank.compareTo(b.rank)))
        .firstWhere((t) => t.isDrillable);

    await pump(tester, const MasteryProfile({}));
    expect(find.textContaining(easiest.singular), findsOneWidget);
  });

  testWidgets('a finished player is told there is nothing left', (tester) async {
    await pump(
      tester,
      profileOf({
        for (final t in Technique.values)
          if (t.isDrillable) t: mastered(t),
      }),
    );

    final total = Technique.values.where((t) => t.isDrillable).length;
    expect(find.text('$total of $total'), findsOneWidget);
    expect(find.textContaining('nothing left to teach you'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('one pip per drillable technique, and no more', (tester) async {
    await pump(tester, const MasteryProfile({}));

    final total = Technique.values.where((t) => t.isDrillable).length;
    final pips = find.byWidgetPredicate((w) =>
        w is Container &&
        (w.decoration as BoxDecoration?)?.borderRadius ==
            BorderRadius.circular(3));
    expect(pips, findsNWidgets(total));
  });

  testWidgets('it survives a narrow phone at a large text scale',
      (tester) async {
    await pump(
      tester,
      const MasteryProfile({}),
      size: const Size(320, 640),
      textScale: 1.6,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('a screen reader hears the count and the suggestion',
      (tester) async {
    final handle = tester.ensureSemantics();
    await pump(tester, const MasteryProfile({}));

    final total = Technique.values.where((t) => t.isDrillable).length;
    expect(
      find.bySemanticsLabel(RegExp('techniques, 0 of $total mastered')),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('tapping it opens the library', (tester) async {
    await pump(tester, const MasteryProfile({}));

    await tester.tap(find.byType(MasteryCard));
    await tester.pumpAndSettle();

    expect(find.text('the library'), findsOneWidget);
  });
}
