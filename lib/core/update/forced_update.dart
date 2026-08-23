import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../logger.dart';

/// Whether this build is old enough that it must not keep running.
///
/// The app has irreversible database migrations — there is no `onDowngrade`
/// and Play cannot lower a `versionCode` — so a build that writes a schema a
/// later build cannot read is a build that has to be retired rather than
/// tolerated. This is the lever for doing that without shipping anything.
///
/// It is deliberately hard to fire by accident. The default minimum is zero,
/// which blocks nobody, and it is only ever raised from the console. Every
/// failure path — no network, no Firebase, a malformed value, a platform
/// without config — leaves the app running. An offline-first sudoku app that
/// refuses to open because it could not reach a server would be a worse bug
/// than anything this prevents.
class ForcedUpdate {
  ForcedUpdate._();

  static final ForcedUpdate instance = ForcedUpdate._();

  /// Read by the widget that puts the wall up. Never set true by a failure.
  final ValueNotifier<bool> isRequired = ValueNotifier(false);

  /// What the wall says. Overridable from the console so the reason for a
  /// particular retirement can be given without shipping a build to explain
  /// why the last build had to go.
  final ValueNotifier<String> message = ValueNotifier(defaultMessage);

  static const String defaultMessage =
      'this version is too old to run correctly. your puzzles and stats are '
      'safe on this device — updating keeps them.';

  /// Console keys. `minimum_build` is a build number, not a version string:
  /// `1.2.0+9` is build 9, and an integer compare has no edge cases.
  static const String minimumBuildKey = 'minimum_build';
  static const String messageKey = 'update_message';

  /// The pure decision, so the fail-open rules can be tested without a
  /// network, a plugin, or a Firebase project.
  ///
  /// Strictly below: a build equal to the minimum is the minimum, and is
  /// allowed. Zero and anything negative block nobody — that is what makes a
  /// missing or mistyped console value harmless rather than fatal.
  @visibleForTesting
  static bool blocks({required int installedBuild, required int minimumBuild}) {
    if (minimumBuild <= 0) return false;
    if (installedBuild <= 0) return false;
    return installedBuild < minimumBuild;
  }

  /// Applies the cached value now and refreshes in the background.
  ///
  /// Two stages on purpose. The cached value needs no network, so somebody
  /// who has been told to update stays told even on a plane. The refresh is
  /// not awaited, so a slow or absent network never delays the first frame —
  /// the wall simply goes up a moment later if the answer says it should.
  Future<void> start({
    RemoteConfigFetcher? fetcher,
    InstalledBuildReader? installedBuild,
  }) async {
    final fetch = fetcher ?? _firebase;
    final read = installedBuild ?? _packageInfo;
    try {
      await fetch(this, await read());
    } catch (e) {
      // Any failure at all leaves the app running. That includes failing to
      // find out what build this is: "we do not know" must never be read as
      // "retire it".
      Log.warn('forced update check skipped: $e', tag: 'update');
    }
  }

  Future<int> _packageInfo() async {
    final info = await PackageInfo.fromPlatform();
    return int.tryParse(info.buildNumber) ?? 0;
  }

  /// Called by the fetcher once it has a value to apply.
  @visibleForTesting
  void apply({required int installedBuild, required int minimumBuild, String? text}) {
    if (text != null && text.trim().isNotEmpty) message.value = text.trim();
    final blocked = blocks(
      installedBuild: installedBuild,
      minimumBuild: minimumBuild,
    );
    if (blocked && !isRequired.value) {
      Log.updateForced(installed: installedBuild, minimum: minimumBuild);
    }
    isRequired.value = blocked;
  }

  Future<void> _firebase(ForcedUpdate self, int installed) async {
    final config = FirebaseRemoteConfig.instance;

    // Defaults first, so a value is always available before any fetch — and
    // so the value that is always available blocks nobody.
    await config.setDefaults(const {
      minimumBuildKey: 0,
      messageKey: '',
    });
    await config.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(seconds: 10),
      // An hour, not a minute. A retirement is not an emergency measured in
      // seconds, and polling on every cold start would spend a player's data
      // to learn nothing almost every time.
      minimumFetchInterval: const Duration(hours: 1),
    ));

    // Whatever was last fetched, applied without touching the network.
    await config.activate();
    self.apply(
      installedBuild: installed,
      minimumBuild: config.getInt(minimumBuildKey),
      text: config.getString(messageKey),
    );

    // Then go and look for a newer answer, without holding anything up.
    unawaited(() async {
      try {
        await config.fetchAndActivate();
        self.apply(
          installedBuild: installed,
          minimumBuild: config.getInt(minimumBuildKey),
          text: config.getString(messageKey),
        );
      } catch (e) {
        Log.warn('remote config fetch failed: $e', tag: 'update');
      }
    }());
  }
}

/// How the minimum is obtained. Swapped in tests for something that does not
/// need a Firebase project.
typedef RemoteConfigFetcher = Future<void> Function(
    ForcedUpdate self, int installedBuild);

/// Which build this is. Swapped in tests, where there is no platform channel
/// to ask.
typedef InstalledBuildReader = Future<int> Function();
