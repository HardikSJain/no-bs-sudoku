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

  test('cubits never reach for a platform channel', () {
    // A cubit that calls Haptics cannot be tested without a Flutter binding,
    // and feedback is a presentation concern anyway — the state already says
    // what happened. This has been fixed twice now, once for hints and once
    // for group completion, so it is worth a guard.
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('_cubit.dart')) continue;
      final source = entity.readAsStringSync();
      if (source.contains('Haptics.') ||
          source.contains('HapticFeedback.') ||
          source.contains('Clipboard.')) {
        offenders.add(entity.path);
      }
    }
    expect(offenders, isEmpty,
        reason: 'move the platform call to the widget that observes the '
            'state change:\n  ${offenders.join('\n  ')}');
  });

  test('Tappable is the only place a tap target is built', () {
    // Keeps the primitive the single point of change: if the semantics
    // contract needs to grow — a new role, a live region — it should be one
    // edit rather than forty.
    final tappable = File('lib/core/a11y/tappable.dart').readAsStringSync();
    expect(tappable.contains('Semantics('), isTrue);
    expect(tappable.contains('button: true'), isTrue);
  });

  test('the app root applies the content text-scale policy', () {
    // The clamp only protects anything if MaterialApp is handed it. It was
    // written, tested as a constant, and never wired for a while.
    final source = File('lib/app.dart').readAsStringSync();
    expect(
      source.contains('builder: TextScale.applyContentPolicy'),
      isTrue,
      reason: 'lib/app.dart must pass TextScale.applyContentPolicy as the '
          'MaterialApp builder, or every screen scales without a ceiling.',
    );
  });
}
