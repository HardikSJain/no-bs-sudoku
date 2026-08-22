import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

import 'logger.dart';
import 'storage/repositories/repositories.dart';

/// Asks for a store rating, at a moment that has earned it.
///
/// Both stores put hard rules on this and both are easy to breach by
/// accident:
///
/// - it must never be triggered by a control the player pressed. Apple
///   rejects "rate us" buttons wired to this API, and Play forbids them
///   outright. So there is no public "ask now" — only [maybeAskAfter], which
///   decides for itself.
/// - it must never be gated on sentiment. "Enjoying the app? Leave a review"
///   is against both sets of guidelines, and it is a dark pattern besides,
///   which this app does not do.
/// - the system may silently show nothing. Apple allows three prompts a year
///   and Play enforces its own quota, so a request that appears to succeed
///   often did nothing at all. That is why the app keeps its own record of
///   when it last asked rather than assuming a prompt was seen.
class ReviewPrompt {
  ReviewPrompt(this._preferences, {InAppReview? review})
      : _review = review ?? InAppReview.instance;

  final PreferencesRepository _preferences;
  final InAppReview _review;

  /// Enough solves that the player has an opinion worth asking for. Asking
  /// after the first puzzle gets a rating of the install, not the app.
  static const int minimumSolves = 5;

  /// Well beyond either store's quota. If a prompt was suppressed we do not
  /// want to keep burning attempts on it, and someone who has already been
  /// asked this quarter should be left alone.
  static const Duration minimumGap = Duration(days: 90);

  /// A moment good enough to ask on.
  ///
  /// Deliberately narrow. Losing to the mistake limit, abandoning, or
  /// finishing a puzzle after six full reveals are all completions, and none
  /// of them is a good time to ask what someone thinks of the app.
  static bool isGoodMoment({
    required bool completed,
    required double qualityScore,
    required bool isPersonalBest,
  }) =>
      completed && (isPersonalBest || qualityScore >= 75);

  /// Considers asking. Returns true only when a request was actually sent.
  ///
  /// Every guard is checked before the store is called, and the timestamp is
  /// written whether or not the system chose to show anything — because it
  /// will not tell us, and an unwritten timestamp means asking again next
  /// time and every time after.
  Future<bool> maybeAskAfter({
    required int totalSolved,
    required bool goodMoment,
    required DateTime now,
  }) async {
    if (!goodMoment) return false;
    if (totalSolved < minimumSolves) return false;

    final prefs = await _preferences.getPreferences();
    final last = prefs.lastReviewRequestAt;
    if (last != null && now.difference(last) < minimumGap) return false;

    // Simulators and devices without a store return false here, and calling
    // anyway would throw on some platforms.
    if (!await _review.isAvailable()) return false;

    await _preferences.setLastReviewRequestAt(now);
    try {
      await _review.requestReview();
      Log.reviewRequested();
      return true;
    } catch (e) {
      // Never let a store SDK take down the complete screen.
      Log.warn('review request failed: $e', tag: 'review');
      return false;
    }
  }

  /// For tests, which must never touch a real store.
  @visibleForTesting
  static ReviewPrompt forTesting(
    PreferencesRepository preferences,
    InAppReview review,
  ) =>
      ReviewPrompt(preferences, review: review);
}
