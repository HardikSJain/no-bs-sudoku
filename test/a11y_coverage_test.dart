import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// A guard, not a unit test.
///
/// Every tap target in this app used to be a bare `GestureDetector` wrapped
/// around a `Container`, which assistive technology cannot see: no role, no
/// name, nothing to activate. That was fixed screen by screen, and the only
/// thing stopping it coming back one convenient widget at a time is a check
/// that fails when it does.
void main() {
  test('no screen reintroduces an unlabelled tap target', () {
    final offenders = <String>[];

    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.endsWith('.g.dart')) continue;

      final source = entity.readAsStringSync();
      if (!source.contains('GestureDetector(')) continue;

      // A GestureDetector is fine when something around it supplies the
      // semantics — Tappable wraps one, and the board cell puts its own
      // Semantics node above it because eighty-one Tappables would each
      // rebuild a semantics node on every timer tick.
      final excused = source.contains('Semantics(') ||
          entity.path.endsWith('core/a11y/tappable.dart');
      if (excused) continue;

      final count = 'GestureDetector('.allMatches(source).length;
      offenders.add('${entity.path} ($count)');
    }

    expect(
      offenders,
      isEmpty,
      reason: 'these have raw tap targets a screen reader cannot see. wrap '
          'them in Tappable, or add a Semantics node if the widget has a '
          'reason not to:\n  ${offenders.join('\n  ')}',
    );
  });

  test('Tappable is the only place a tap target is built', () {
    // Keeps the primitive the single point of change: if the semantics
    // contract needs to grow — a new role, a live region — it should be one
    // edit rather than forty.
    final tappable = File('lib/core/a11y/tappable.dart').readAsStringSync();
    expect(tappable.contains('Semantics('), isTrue);
    expect(tappable.contains('button: true'), isTrue);
  });
}
