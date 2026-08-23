import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/features/feedback/feedback_context.dart';
import 'package:no_bs_sudoku/features/feedback/feedback_repository.dart';
import 'package:no_bs_sudoku/features/feedback/feedback_screen.dart';

/// The only channel that is not a public one-star review.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  const sample = FeedbackContext(
    installId: 'abc123def456',
    version: '1.2.0',
    build: '9',
    platform: 'android',
    osVersion: '14',
    locale: 'en-IN',
    screen: '402x874',
    puzzlesSolved: 12,
    puzzlesStarted: 20,
    currentStreak: 3,
    longestStreak: 9,
    avgQuality: 71,
    preferredDifficulty: 'hard',
    techniquesMastered: 2,
    techniquesTotal: 13,
  );

  group('the anonymous id', () {
    test('is minted once and then kept', () async {
      final first = await repos.preferences.installId();
      final second = await repos.preferences.installId();

      expect(first, second);
      expect(first.length, 12);
    });

    test('is not minted for somebody who never writes in', () async {
      // Lazy on purpose. A player who never opens the form never gets one.
      expect((await repos.preferences.getPreferences()).installId, isNull);
    });

    test('and two installs do not collide', () {
      final ids = {for (var i = 0; i < 2000; i++) FeedbackContext.newInstallId()};
      expect(ids.length, 2000);
    });

    test('avoids the characters people misread aloud', () {
      // These get read out in bug reports.
      for (var i = 0; i < 200; i++) {
        final id = FeedbackContext.newInstallId();
        expect(id, isNot(contains('l')));
        expect(id, isNot(contains('o')));
        expect(id, isNot(contains('0')));
        expect(id, isNot(contains('1')));
      }
    });
  });

  group('the payload', () {
    test('carries nothing that is not shown on screen', () {
      // The panel above the send button renders `lines`. Anything in the map
      // that is not also on screen would be collected quietly, which is the
      // one thing this design exists to prevent.
      final shown = sample.lines.map((l) => l.$2).join(' ');
      for (final value in sample.toMap().values) {
        expect(shown, contains('$value'),
            reason: '$value is sent but never shown');
      }
    });

    test('and nothing that identifies a person', () {
      final keys = sample.toMap().keys.toSet();
      for (final banned in const [
        'email',
        'name',
        'displayName',
        'phone',
        'latitude',
        'longitude',
        'advertisingId',
        'deviceId',
        'imei',
        'contacts',
      ]) {
        expect(keys, isNot(contains(banned)));
      }
    });
  });

  group('the firestore document', () {
    Map<String, Object?> fieldsOf(Map<String, Object?> doc) =>
        (doc['fields'] as Map).cast<String, Object?>();

    test('sends integers as strings, which is what REST wants', () {
      // A number sent as a number is silently stored as a double, and every
      // query against it then has to know that.
      final doc = FeedbackRepository.document(
        message: 'hello',
        kind: FeedbackKind.bug,
        context: sample,
        at: DateTime.utc(2026, 8, 23),
      );
      final ctx = ((fieldsOf(doc)['context'] as Map)['mapValue']
          as Map)['fields'] as Map;
      expect(ctx['puzzlesSolved'], {'integerValue': '12'});
      expect(ctx['preferredDifficulty'], {'stringValue': 'hard'});
    });

    test('omits the reply address entirely when there is none', () {
      // Absent, not empty. An empty string is still a field somebody has to
      // wonder about.
      final doc = FeedbackRepository.document(
        message: 'hello',
        kind: FeedbackKind.idea,
        context: sample,
        at: DateTime.utc(2026, 8, 23),
      );
      expect(fieldsOf(doc).containsKey('replyTo'), isFalse);

      final withReply = FeedbackRepository.document(
        message: 'hello',
        kind: FeedbackKind.idea,
        context: sample,
        at: DateTime.utc(2026, 8, 23),
        replyTo: '  someone@example.com ',
      );
      expect(fieldsOf(withReply)['replyTo'],
          {'stringValue': 'someone@example.com'});
    });

    test('caps a message before the write rather than after', () {
      // Firestore would reject it, but only after the player spent five
      // minutes writing.
      final doc = FeedbackRepository.document(
        message: 'x' * 9000,
        kind: FeedbackKind.other,
        context: sample,
        at: DateTime.utc(2026, 8, 23),
      );
      final message =
          (fieldsOf(doc)['message'] as Map)['stringValue'] as String;
      expect(message.length, FeedbackRepository.maxMessageLength);
    });

    test('and the kind is one the rules allow', () {
      // firestore.rules pins `kind in ['bug', 'idea', 'other']`.
      expect(FeedbackKind.values.map((k) => k.name).toSet(),
          {'bug', 'idea', 'other'});
    });
  });

  group('sending', () {
    test('a 200 is a send', () async {
      late String body;
      final client = MockClient((request) async {
        body = request.body;
        return http.Response('{"name":"projects/x/documents/feedback/y"}', 200);
      });

      final result = await FeedbackRepository(client: client).send(
        message: 'the hints are too chatty',
        kind: FeedbackKind.idea,
        context: sample,
      );

      expect(result, isA<FeedbackSent>());
      expect(jsonDecode(body), isA<Map<String, dynamic>>());
    });

    test('a rejection is reported in words, not a status code', () async {
      final client =
          MockClient((_) async => http.Response('{"error":{}}', 403));

      final result = await FeedbackRepository(client: client).send(
        message: 'hello',
        kind: FeedbackKind.bug,
        context: sample,
      );

      expect(result, isA<FeedbackFailed>());
      expect((result as FeedbackFailed).reason, isNot(contains('403')));
    });

    test('no network says so plainly and loses nothing', () async {
      final client = MockClient((_) async => throw const SocketishError());

      final result = await FeedbackRepository(client: client).send(
        message: 'hello',
        kind: FeedbackKind.bug,
        context: sample,
      );

      expect(result, isA<FeedbackFailed>());
      expect((result as FeedbackFailed).reason, contains('internet'));
    });

    test('an empty message never reaches the network', () async {
      var called = false;
      final client = MockClient((_) async {
        called = true;
        return http.Response('{}', 200);
      });

      final result = await FeedbackRepository(client: client)
          .send(message: '   ', kind: FeedbackKind.bug, context: sample);

      expect(result, isA<FeedbackFailed>());
      expect(called, isFalse);
    });
  });

  group('the screen', () {
    Future<void> pump(WidgetTester tester, FeedbackRepository repo) async {
      tester.view.physicalSize = const Size(320 * 3, 2200 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: repos.records),
          RepositoryProvider.value(value: repos.profiles),
          RepositoryProvider.value(value: repos.preferences),
          RepositoryProvider.value(value: repos.mastery),
          RepositoryProvider.value(value: repos),
        ],
        child: MaterialApp(
          theme: appTheme(),
          home: FeedbackScreen(repository: repo, attached: sample),
        ),
      ));
      await tester.pumpAndSettle();
    }

    testWidgets('shows every attached field before anything is sent',
        (tester) async {
      await pump(tester, const FeedbackRepository());

      expect(find.text('SENT WITH IT'), findsOneWidget);
      expect(find.textContaining('no location'), findsOneWidget);
      expect(find.textContaining('12 of 20 started'), findsOneWidget);
      expect(find.text('abc123def456'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('will not send an empty message', (tester) async {
      var called = false;
      await pump(
          tester,
          FeedbackRepository(client: MockClient((_) async {
            called = true;
            return http.Response('{}', 200);
          })));

      await tester.tap(find.text('SEND'));
      await tester.pumpAndSettle();

      expect(called, isFalse);
      expect(find.text('write something first.'), findsOneWidget);
    });

    testWidgets('sends what was typed and then says thanks', (tester) async {
      String? sent;
      await pump(
          tester,
          FeedbackRepository(client: MockClient((request) async {
            sent = request.body;
            return http.Response('{}', 200);
          })));

      await tester.enterText(
          find.byType(TextField).first, 'the daily is too hard on sundays');
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEND'));
      await tester.pumpAndSettle();

      expect(sent, contains('too hard on sundays'));
      expect(find.text('thanks.'), findsOneWidget);
      expect(find.text('SEND'), findsNothing);
    });

    testWidgets('and a failure keeps what was typed', (tester) async {
      await pump(
          tester,
          FeedbackRepository(
              client: MockClient((_) async => http.Response('{}', 500))));

      await tester.enterText(find.byType(TextField).first, 'five minutes of typing');
      await tester.pumpAndSettle();
      await tester.tap(find.text('SEND'));
      await tester.pumpAndSettle();

      expect(find.text('five minutes of typing'), findsOneWidget,
          reason: 'losing the message on a failed send is unforgivable');
      expect(find.textContaining('did not go through'), findsOneWidget);
    });
  });
}

/// Stands in for a network error without importing dart:io into a test that
/// otherwise has no need of it.
class SocketishError implements Exception {
  const SocketishError();
}
