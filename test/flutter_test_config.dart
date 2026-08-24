import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// Runs once for every test in this tree.
///
/// google_fonts resolves its files over HTTP the first time a style is used.
/// Normally a widget test never lets that future run and it stays invisible —
/// but any test needing `tester.runAsync`, which every test touching the real
/// puzzle isolate does, gives it a real event loop. It then fails with no
/// network and reports *after* the test body has finished, so the framework
/// blames whichever test happened to be running. That has cost an afternoon
/// before.
///
/// Two steps: stop the fetch, then ignore the complaint about it being
/// stopped. Both are scoped to font loading; anything else still fails the
/// test, loudly.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  GoogleFonts.config.allowRuntimeFetching = false;

  // Not `FlutterError.onError` — the test binding reinstalls its own for
  // every test, so a handler set here would be gone by the first one. This is
  // the hook that survives.
  final report = reportTestException;
  reportTestException = (details, description) {
    if (_isFontLoad(details)) return;
    report(details, description);
  };

  await testMain();
}

/// A font that could not be loaded, and nothing else.
///
/// Matched on identifiers rather than prose: the config key google_fonts
/// names when fetching is off, and the host it would otherwise fetch from.
bool _isFontLoad(FlutterErrorDetails details) {
  final text = details.exception.toString();
  return text.contains('allowRuntimeFetching') ||
      text.contains('fonts.gstatic.com');
}
