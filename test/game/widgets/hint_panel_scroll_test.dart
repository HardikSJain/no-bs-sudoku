import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/a11y/tappable.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/widgets/hint_panel.dart';

/// The panel clips its prose rather than growing, so the copy that does not
/// fit has to be reachable and has to look reachable.
///
/// Note `pauseTimer` and the absence of `pumpAndSettle`. GameCubit runs a
/// one-second periodic timer, and a widget test that settles against a live
/// cubit never returns — the tick emits, the tree rebuilds, and there is
/// always another frame scheduled. An earlier attempt at an end-to-end test
/// of this screen hung for exactly this reason and was thrown away.
void main() {
  late AppDatabase db;
  late Repositories repos;
  GameCubit? cubit;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  // Only the database. The cubit is closed inside each test body by
  // [finish] — see the note there.
  tearDown(() async => db.close());

  /// A panel showing a hint, in a box of [maxHeight] points.
  ///
  /// The height is the fixture, not the copy: whether any particular
  /// explanation happens to be two lines or five is the hint engine's
  /// business, and pinning a scroll test to it would make this fail every
  /// time somebody rewords a sentence.
  Future<void> openHint(WidgetTester tester, {required double maxHeight}) async {
    final c = GameCubit.newGame(
        repos: repos, difficulty: Difficulty.easy, seed: 42)
      ..pauseTimer();
    cubit = c;

    await tester.pumpWidget(MaterialApp(
      theme: appTheme(),
      home: Scaffold(
        body: BlocProvider.value(
          value: c,
          child: Align(
            alignment: Alignment.topCenter,
            child: HintPanel(maxHeight: maxHeight),
          ),
        ),
      ),
    ));
    await tester.pump();

    // Third rung: technique name, explanation and recognition cue — the
    // longest the copy ever gets.
    c.useHint();
    c.useHint();
    c.useHint();
    await tester.pump();
    // Past the panel's entry animation. flutter_animate starts its
    // controller from a zero-duration timer, so the first pump only arms it
    // and the fade and slide need two more frames after that.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  final scroller = find.descendant(
    of: find.byType(HintPanel),
    matching: find.byType(Scrollable),
  );

  final fade = find.byKey(hintFadeKey);
  final fadeTop = find.byKey(hintFadeTopKey);

  /// Closes the cubit while the test's fake clock is still running.
  ///
  /// `GameCubit.close` awaits the mastery writes a hint queued, and those are
  /// real database futures scheduled inside the test's fake-async zone. Do it
  /// from `tearDown` and the zone has already stopped pumping, so the future
  /// never completes and the whole test file hangs — with the body itself
  /// having passed, which makes it look like a framework problem rather than
  /// a teardown one.
  Future<void> finish() async {
    await cubit?.close();
    cubit = null;
  }

  ScrollPosition position(WidgetTester tester) =>
      tester.state<ScrollableState>(scroller).position;

  /// Drags inside the scroll region, away from its centre.
  ///
  /// The dismiss X sits over the middle of a short panel, and `drag` aims at
  /// the finder's centre — which hit-tests to the button, not the prose.
  Future<void> scrollBy(WidgetTester tester, double dy) async {
    final box = tester.getRect(scroller);
    await tester.dragFrom(Offset(box.left + 12, box.top + 6), Offset(0, dy));
    await tester.pump(const Duration(milliseconds: 400));
  }

  testWidgets('copy past the cap is scrollable, not lost', (tester) async {
    await openHint(tester, maxHeight: 110);

    expect(position(tester).maxScrollExtent, greaterThan(0),
        reason: 'the fixture must actually overflow, or this proves nothing');

    await scrollBy(tester, -30);

    expect(position(tester).pixels, greaterThan(0));
    await finish();
  });

  testWidgets('the bottom is faded while there is more below', (tester) async {
    await openHint(tester, maxHeight: 110);
    expect(fade, findsOneWidget);
    await finish();
  });

  testWidgets('and the fade goes once you have reached the bottom',
      (tester) async {
    await openHint(tester, maxHeight: 110);

    await scrollBy(tester, -600);
    await tester.pump(const Duration(milliseconds: 400));

    expect(position(tester).pixels, position(tester).maxScrollExtent);
    expect(fade, findsNothing);
    await finish();
  });

  testWidgets('the technique chip stays put while the prose scrolls',
      (tester) async {
    await openHint(tester, maxHeight: 110);

    // The chip is the label for everything below it, and it is the first
    // control in the panel — the dismiss X is the other one.
    final chip = find.descendant(
      of: find.byType(HintPanel),
      matching: find.byType(Tappable),
    ).first;
    final before = tester.getRect(chip);

    await scrollBy(tester, -600);

    expect(tester.getRect(chip), before,
        reason: 'the technique name must not scroll out from over its own '
            'explanation');
    await finish();
  });

  testWidgets('the top softens too, once you have scrolled past the start',
      (tester) async {
    await openHint(tester, maxHeight: 110);

    expect(fadeTop, findsNothing,
        reason: 'nothing above the first line to hint at');

    await scrollBy(tester, -20);

    expect(fadeTop, findsOneWidget);
    await finish();
  });

  testWidgets('a panel with room to spare is not faded at all',
      (tester) async {
    await openHint(tester, maxHeight: 500);

    expect(position(tester).maxScrollExtent, 0);
    expect(fade, findsNothing);
    expect(fadeTop, findsNothing);
    await finish();
  });
}
