import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/duration_format.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';

/// A puzzle left open is not a puzzle being solved.
///
/// Backgrounding already stopped the clock, but a phone face-up on a desk is
/// not backgrounded — and the clock ran anyway. A session left open for an
/// afternoon recorded the afternoon, which made the time meaningless and fed
/// straight into personal bests, the quality score's time term, and the
/// inter-placement deltas the stuck nudge builds its threshold from.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  GameCubit game() =>
      GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 9);

  void runClock(GameCubit cubit, Duration d) {
    for (int i = 0; i < d.inSeconds; i++) {
      cubit.tickForTesting();
    }
  }

  group('the clock stops when nobody is there', () {
    test('it runs while the player is thinking', () async {
      final cubit = game();
      addTearDown(cubit.close);

      // Nine minutes of silence is a hard grid, not an abandoned one.
      runClock(cubit, const Duration(minutes: 9));
      expect(cubit.state.elapsed, const Duration(minutes: 9));
      expect(cubit.isIdle, isFalse);
    });

    test('and stops once the silence stops being plausible', () async {
      final cubit = game();
      addTearDown(cubit.close);

      runClock(cubit, const Duration(minutes: 30));
      expect(cubit.state.elapsed, const Duration(minutes: 10),
          reason: 'twenty further minutes of nothing should not be counted');
      expect(cubit.isIdle, isTrue);
    });

    test('and picks up again the moment anything is touched', () async {
      final cubit = game();
      addTearDown(cubit.close);

      runClock(cubit, const Duration(minutes: 30));
      final parked = cubit.state.elapsed;

      cubit.selectCell(0, 0);
      expect(cubit.isIdle, isFalse);

      runClock(cubit, const Duration(minutes: 2));
      expect(cubit.state.elapsed, parked + const Duration(minutes: 2));
      await cubit.close();
    });

    test('coming back to the app counts as being present', () async {
      final cubit = game();
      addTearDown(cubit.close);

      runClock(cubit, const Duration(minutes: 30));
      expect(cubit.isIdle, isTrue);

      cubit.pauseTimer();
      cubit.resumeTimer();
      expect(cubit.isIdle, isFalse,
          reason: 'returning to a parked puzzle must not read as still away');
    });
  });

  group('clock formatting rolls over into hours', () {
    test('a long session reads as hours, not as three hundred minutes', () {
      // This is what put the bug on screen: 299:09 instead of 4:59:09.
      expect(clockTime(299 * 60 + 9), '4:59:09');
      expect(clockTime(3600), '1:00:00');
      expect(clockTime(3599), '59:59');
      expect(clockTime(61), '01:01');
      expect(clockTime(0), '00:00');
      expect(clockTime(-5), '00:00');
    });

    test('and spoken durations do too', () {
      expect(spokenDuration(3661), '1 hour 1 minute');
      expect(spokenDuration(252), '4 minutes 12 seconds');
      expect(spokenDuration(0), 'no time yet');
    });

    test('a difference keeps its sign and rolls over as well', () {
      // Positive is faster, and faster prints as a minus.
      expect(deltaTime(125), '\u22122m 05s');
      expect(deltaTime(-125), '+2m 05s');
      expect(deltaTime(9), '\u22129s');
      expect(deltaTime(0), '\u22120s');
      expect(deltaTime(3600 + 12 * 60), '\u22121h 12m');
    });

    test('no screen rolls its own', () {
      // Ten copies of `mm:ss` is how one of them ends up without the hour
      // case. There is one implementation now, and this keeps it that way.
      final offenders = <String>[];
      for (final e in Directory('lib').listSync(recursive: true)) {
        if (e is! File || !e.path.endsWith('.dart')) continue;
        if (e.path.endsWith('.g.dart')) continue;
        if (e.path.endsWith('core/duration_format.dart')) continue;
        final src = e.readAsStringSync();
        if (src.contains('% 60') && src.contains("padLeft(2")) {
          offenders.add(e.path);
        }
      }
      expect(offenders, isEmpty,
          reason: 'these format a duration by hand. use clockTime, '
              'deltaTime or spokenDuration:\n  ${offenders.join('\n  ')}');
    });
  });
}
