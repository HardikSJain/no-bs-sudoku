import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/logger.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/core/update/forced_update.dart';
import 'package:no_bs_sudoku/features/update/update_required_screen.dart';

/// The lever that retires a build.
///
/// Nearly all of this is about the ways it must *not* fire. A force-update
/// check that goes off wrongly does not degrade the app, it removes it: every
/// install shows a wall and nobody can play. So the default blocks nobody,
/// every failure path blocks nobody, and only a deliberate console value
/// above the installed build does anything at all.
void main() {
  setUp(() {
    ForcedUpdate.instance.isRequired.value = false;
    ForcedUpdate.instance.message.value = ForcedUpdate.defaultMessage;
  });

  group('it refuses to fire by accident', () {
    test('the default of zero blocks nobody', () {
      // This is the value every install has before it ever reaches the
      // console, and the value it keeps if the console is never touched.
      for (var build = 0; build < 500; build++) {
        expect(ForcedUpdate.blocks(installedBuild: build, minimumBuild: 0),
            isFalse,
            reason: 'build $build');
      }
    });

    test('a negative or nonsense minimum blocks nobody', () {
      expect(ForcedUpdate.blocks(installedBuild: 9, minimumBuild: -1), isFalse);
      expect(ForcedUpdate.blocks(installedBuild: 9, minimumBuild: -999),
          isFalse);
    });

    test('an unreadable installed build blocks nobody', () {
      // `int.tryParse` of a malformed buildNumber yields 0. Treating "we do
      // not know what this is" as "retire it" would be the worst possible
      // reading.
      expect(ForcedUpdate.blocks(installedBuild: 0, minimumBuild: 99), isFalse);
    });

    test('the minimum itself is allowed to run', () {
      // Strictly below. Setting the minimum to the build you just shipped
      // must not retire the build you just shipped.
      expect(ForcedUpdate.blocks(installedBuild: 9, minimumBuild: 9), isFalse);
      expect(ForcedUpdate.blocks(installedBuild: 10, minimumBuild: 9), isFalse);
    });
  });

  group('and it does fire when it is meant to', () {
    test('a build below the minimum is retired', () {
      expect(ForcedUpdate.blocks(installedBuild: 8, minimumBuild: 9), isTrue);
      expect(ForcedUpdate.blocks(installedBuild: 1, minimumBuild: 9), isTrue);
    });

    test('applying a value raises the flag and reports it once', () {
      final events = <String>[];
      Log.testSink = events.add;
      addTearDown(() => Log.testSink = null);

      ForcedUpdate.instance.apply(installedBuild: 8, minimumBuild: 9);
      expect(ForcedUpdate.instance.isRequired.value, isTrue);

      // The cached value is applied, then the fetched one. Both say the same
      // thing, and that is one retirement, not two.
      ForcedUpdate.instance.apply(installedBuild: 8, minimumBuild: 9);
      expect(events.where((e) => e == 'update_forced').length, 1);
    });

    test('and a later value can lower the wall again', () {
      // Rolling the console value back has to actually let people back in,
      // or a mistake is unrecoverable without a new build.
      ForcedUpdate.instance.apply(installedBuild: 8, minimumBuild: 9);
      expect(ForcedUpdate.instance.isRequired.value, isTrue);

      ForcedUpdate.instance.apply(installedBuild: 8, minimumBuild: 0);
      expect(ForcedUpdate.instance.isRequired.value, isFalse);
    });
  });

  group('the message', () {
    test('falls back to the shipped one when the console is empty', () {
      ForcedUpdate.instance.apply(installedBuild: 8, minimumBuild: 9, text: '');
      expect(ForcedUpdate.instance.message.value, ForcedUpdate.defaultMessage);

      ForcedUpdate.instance
          .apply(installedBuild: 8, minimumBuild: 9, text: '   ');
      expect(ForcedUpdate.instance.message.value, ForcedUpdate.defaultMessage);
    });

    test('and can be replaced from the console', () {
      ForcedUpdate.instance.apply(
          installedBuild: 8, minimumBuild: 9, text: 'the daily changed shape.');
      expect(ForcedUpdate.instance.message.value, 'the daily changed shape.');
    });
  });

  group('start()', () {
    test('a fetcher that throws leaves the app running', () async {
      await ForcedUpdate.instance.start(
        fetcher: (_, _) async => throw StateError('no network'),
      );
      expect(ForcedUpdate.instance.isRequired.value, isFalse);
    });

    test('not knowing which build this is leaves the app running', () async {
      // There is no platform channel in a test, so this is also what happens
      // on a device where PackageInfo fails. "We do not know what build this
      // is" must never be read as "retire it".
      var fetched = false;
      await ForcedUpdate.instance.start(
        fetcher: (_, _) async => fetched = true,
      );
      expect(fetched, isFalse, reason: 'it never got as far as the fetcher');
      expect(ForcedUpdate.instance.isRequired.value, isFalse);
    });

    test('a working build reader reaches the fetcher and applies it',
        () async {
      await ForcedUpdate.instance.start(
        installedBuild: () async => 8,
        fetcher: (self, build) async =>
            self.apply(installedBuild: build, minimumBuild: 9),
      );
      expect(ForcedUpdate.instance.isRequired.value, isTrue);
    });

    test('and a build reader that throws still leaves it running', () async {
      await ForcedUpdate.instance.start(
        installedBuild: () async => throw StateError('no channel'),
        fetcher: (self, build) async =>
            self.apply(installedBuild: build, minimumBuild: 9999),
      );
      expect(ForcedUpdate.instance.isRequired.value, isFalse);
    });
  });

  group('the wall', () {
    Future<void> pump(WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: appTheme(),
        home: const UpdateGate(child: Scaffold(body: Text('the board'))),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('is not there until it is needed', (tester) async {
      await pump(tester);
      expect(find.text('the board'), findsOneWidget);
      expect(find.text('update needed.'), findsNothing);
    });

    testWidgets('goes up the moment the answer arrives, mid-session',
        (tester) async {
      await pump(tester);
      expect(find.text('the board'), findsOneWidget);

      ForcedUpdate.instance.apply(installedBuild: 8, minimumBuild: 9);
      await tester.pumpAndSettle();

      expect(find.text('update needed.'), findsOneWidget);
      expect(find.text('the board'), findsNothing);
    });

    testWidgets('says that nothing local is lost', (tester) async {
      // The first fear on seeing a screen like this is that updating will
      // take your progress with it.
      ForcedUpdate.instance.apply(installedBuild: 8, minimumBuild: 9);
      await pump(tester);
      expect(find.textContaining('safe on this device'), findsOneWidget);
    });

    testWidgets('shows the console message when there is one', (tester) async {
      ForcedUpdate.instance.apply(
          installedBuild: 8, minimumBuild: 9, text: 'the save format changed.');
      await pump(tester);
      expect(find.text('the save format changed.'), findsOneWidget);
    });

    testWidgets('has no way out of it', (tester) async {
      // A wall you can walk around is a notice. There is exactly one control.
      ForcedUpdate.instance.apply(installedBuild: 8, minimumBuild: 9);
      await pump(tester);

      expect(find.text('UPDATE'), findsOneWidget);
      expect(find.byType(BackButton), findsNothing);
      expect(find.text('later'), findsNothing);
      expect(find.text('not now'), findsNothing);
    });

    testWidgets('and does not overflow a narrow phone', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 500 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      ForcedUpdate.instance.apply(
        installedBuild: 8,
        minimumBuild: 9,
        text: 'a much longer explanation than the default one, written in '
            'the console by somebody who had a lot to say about why this '
            'particular build had to be retired today.',
      );
      await pump(tester);
      expect(tester.takeException(), isNull);
    });
  });
}
