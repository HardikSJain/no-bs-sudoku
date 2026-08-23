import 'dart:io';
import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../core/storage/repositories/repositories.dart';

/// Everything attached to a piece of feedback besides the words.
///
/// Two rules govern what is in here, and they are the reason the list is
/// shorter than it could be.
///
/// **Everything is already on this device.** Nothing is looked up, nothing is
/// asked of another app, and nothing identifies a person. No advertising id,
/// no location, no contacts, no account. A feedback form is not a licence to
/// take an inventory.
///
/// **The player sees all of it before it is sent.** The whole payload is
/// rendered on the screen above the send button. If a line would be
/// embarrassing to show someone, it does not belong in the payload — that
/// test is the entire policy.
///
/// What is here is what makes a sentence of feedback actionable: which build,
/// what it is running on, and how much sudoku the person saying it has
/// actually played. "The hints are patronising" means something different
/// from a player on their third puzzle than from one three hundred deep.
class FeedbackContext {
  const FeedbackContext({
    required this.installId,
    required this.version,
    required this.build,
    required this.platform,
    required this.osVersion,
    required this.device,
    required this.locale,
    required this.screen,
    required this.puzzlesSolved,
    required this.puzzlesStarted,
    required this.currentStreak,
    required this.longestStreak,
    required this.avgQuality,
    required this.preferredDifficulty,
    required this.techniquesMastered,
    required this.techniquesTotal,
  });

  /// A random string made once and kept on this device.
  ///
  /// It links one person's submissions to each other and to nothing else. It
  /// is not a device id, it is not derived from anything, it is not shared
  /// with any other app, and clearing the app's data throws it away — which
  /// is the point. Without it, three reports of the same bug from the same
  /// person read as three people.
  final String installId;

  final String version;
  final String build;
  final String platform;
  final String osVersion;
  final String device;
  final String locale;
  final String screen;

  final int puzzlesSolved;
  final int puzzlesStarted;
  final int currentStreak;
  final int longestStreak;
  final int avgQuality;
  final String preferredDifficulty;
  final int techniquesMastered;
  final int techniquesTotal;

  /// The map written to Firestore. Also, verbatim, what is shown on screen —
  /// there is deliberately no second, richer version.
  Map<String, Object?> toMap() => {
        'installId': installId,
        'version': version,
        'build': build,
        'platform': platform,
        'osVersion': osVersion,
        'device': device,
        'locale': locale,
        'screen': screen,
        'puzzlesSolved': puzzlesSolved,
        'puzzlesStarted': puzzlesStarted,
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'avgQuality': avgQuality,
        'preferredDifficulty': preferredDifficulty,
        'techniquesMastered': techniquesMastered,
        'techniquesTotal': techniquesTotal,
      };

  /// The same thing in the order a person would want to read it.
  List<(String, String)> get lines => [
        ('version', '$version ($build)'),
        ('device', '$device · $platform $osVersion'),
        ('screen', screen),
        ('language', locale),
        ('solved', '$puzzlesSolved of $puzzlesStarted started'),
        ('streak', '$currentStreak now, $longestStreak best'),
        ('average quality', '$avgQuality'),
        ('usual difficulty', preferredDifficulty),
        ('techniques', '$techniquesMastered of $techniquesTotal mastered'),
        ('anonymous id', installId),
      ];

  /// Gathers it. Every lookup is guarded — a feedback form that will not open
  /// because a device plugin misbehaved is worse than one missing a field.
  static Future<FeedbackContext> gather({
    required Repositories repos,
    required Size screenSize,
    required String locale,
  }) async {
    final installId = await repos.preferences.installId();

    var version = 'unknown';
    var build = '?';
    try {
      final info = await PackageInfo.fromPlatform();
      version = info.version;
      build = info.buildNumber;
    } catch (_) {}

    var platform = 'unknown';
    var osVersion = '';
    var device = 'unknown';
    try {
      final plugin = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await plugin.androidInfo;
        platform = 'android';
        osVersion = a.version.release;
        device = '${a.manufacturer} ${a.model}';
      } else if (Platform.isIOS) {
        final i = await plugin.iosInfo;
        platform = 'ios';
        osVersion = i.systemVersion;
        device = i.utsname.machine;
      }
    } catch (_) {}

    var solved = 0;
    var started = 0;
    var streak = 0;
    var longest = 0;
    var preferred = 'medium';
    var quality = 0;
    var mastered = 0;
    var total = 0;
    try {
      final profile = await repos.profiles.getProfile();
      solved = profile.totalSolved;
      started = profile.totalStarted;
      streak = profile.currentStreak;
      longest = profile.longestStreak;
      preferred = profile.preferredDifficulty;
      quality = (await repos.records.getAvgQualityScore()).round();
      final mastery = await repos.mastery.getProfile();
      mastered = mastery.masteredCount;
      total = mastery.drillableCount;
    } catch (_) {}

    return FeedbackContext(
      installId: installId,
      version: version,
      build: build,
      platform: platform,
      osVersion: osVersion,
      device: device,
      locale: locale,
      screen: '${screenSize.width.round()}x${screenSize.height.round()}',
      puzzlesSolved: solved,
      puzzlesStarted: started,
      currentStreak: streak,
      longestStreak: longest,
      avgQuality: quality,
      preferredDifficulty: preferred,
      techniquesMastered: mastered,
      techniquesTotal: total,
    );
  }

  /// Twelve characters of base32-ish. Long enough not to collide across an
  /// install base, short enough to read out in a bug report.
  static String newInstallId([Random? random]) {
    const alphabet = 'abcdefghijkmnpqrstuvwxyz23456789';
    final r = random ?? Random.secure();
    return List.generate(12, (_) => alphabet[r.nextInt(alphabet.length)])
        .join();
  }
}
