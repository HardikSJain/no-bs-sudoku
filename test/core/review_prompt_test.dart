import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_review/in_app_review.dart';

import 'package:no_bs_sudoku/core/review_prompt.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';

/// Never touches a real store.
class _FakeReview implements InAppReview {
  _FakeReview({this.available = true});

  final bool available;
  int requests = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<void> requestReview() async => requests++;

  @override
  Future<void> openStoreListing({
    String? appStoreId,
    String? microsoftStoreId,
  }) async {}
}

void main() {
  late AppDatabase db;
  late Repositories repos;
  late _FakeReview review;

  final now = DateTime.utc(2026, 8, 23);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
    review = _FakeReview();
  });

  tearDown(() async => db.close());

  ReviewPrompt prompt() => ReviewPrompt.forTesting(repos.preferences, review);

  Future<bool> ask({
    int totalSolved = 20,
    bool goodMoment = true,
    DateTime? at,
  }) =>
      prompt().maybeAskAfter(
        totalSolved: totalSolved,
        goodMoment: goodMoment,
        now: at ?? now,
      );

  group('it only asks after something went well', () {
    test('a good solve by an experienced player asks', () async {
      expect(await ask(), isTrue);
      expect(review.requests, 1);
    });

    test('a bad moment never asks', () async {
      expect(await ask(goodMoment: false), isFalse);
      expect(review.requests, 0);
    });

    test('a new player is not asked', () async {
      // Asking after the first puzzle rates the install, not the app.
      expect(await ask(totalSolved: 1), isFalse);
      expect(review.requests, 0);
    });
  });

  group('what counts as a good moment', () {
    test('a strong solve or a personal best', () {
      expect(
        ReviewPrompt.isGoodMoment(
            completed: true, qualityScore: 80, isPersonalBest: false),
        isTrue,
      );
      expect(
        ReviewPrompt.isGoodMoment(
            completed: true, qualityScore: 20, isPersonalBest: true),
        isTrue,
      );
    });

    test('never a scrappy solve, and never an unfinished one', () {
      // Finishing after six full reveals is a completion. It is not a moment
      // to ask someone what they think of the app.
      expect(
        ReviewPrompt.isGoodMoment(
            completed: true, qualityScore: 30, isPersonalBest: false),
        isFalse,
      );
      expect(
        ReviewPrompt.isGoodMoment(
            completed: false, qualityScore: 95, isPersonalBest: true),
        isFalse,
      );
    });
  });

  group('it does not pester', () {
    test('not twice inside the gap', () async {
      expect(await ask(), isTrue);
      expect(await ask(at: now.add(const Duration(days: 30))), isFalse);
      expect(review.requests, 1);
    });

    test('but again well afterwards', () async {
      expect(await ask(), isTrue);
      expect(await ask(at: now.add(const Duration(days: 120))), isTrue);
      expect(review.requests, 2);
    });

    test('the timestamp is written even though the store may show nothing',
        () async {
      // Neither store reports whether the prompt appeared. Treating "not
      // shown" as "not asked" would ask again on the very next good solve,
      // and every one after that.
      await ask();
      final prefs = await repos.preferences.getPreferences();
      // Compared as an instant: drift round-trips through unix seconds and
      // hands back a local DateTime, which is the same moment written
      // differently.
      expect(prefs.lastReviewRequestAt!.isAtSameMomentAs(now), isTrue);
    });
  });

  group('it fails quietly', () {
    test('an unavailable store is a no-op, not a crash', () async {
      review = _FakeReview(available: false);
      expect(await ask(), isFalse);

      // And it must not have burned the window either.
      final prefs = await repos.preferences.getPreferences();
      expect(prefs.lastReviewRequestAt, isNull);
    });
  });

  group('there is no way to trigger it directly', () {
    test('the only entry point decides for itself', () {
      // Both stores forbid a control wired straight to the review API, so
      // there is deliberately no public ask() to wire one to.
      expect(prompt().maybeAskAfter, isA<Function>());
      expect(ReviewPrompt.minimumSolves, greaterThan(1));
      expect(ReviewPrompt.minimumGap.inDays, greaterThanOrEqualTo(90));
    });
  });
}
