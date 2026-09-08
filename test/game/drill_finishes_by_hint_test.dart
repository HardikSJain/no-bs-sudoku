import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/game_state.dart';

/// A drill finished by the hint is still a finished drill.
///
/// `_checkDrillComplete` ran on the input paths only, so pushing a hint to
/// its last rung made the drill's one move and then left the player sitting
/// on a completed drill: no record written, no acknowledgement, nothing to do
/// but press back. Found by doing exactly that on a device.
///
/// It is the elimination case that matters most — for everything above the
/// singles a drill's move *is* an elimination, so this is the ordinary way to
/// finish one with help.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  for (final technique in [Technique.nakedSingle, Technique.hiddenSingle]) {
    test('${technique.name}: taking the hint to the end completes the drill',
        () async {
      final cubit = await GameCubit.trainerAsync(
        repos: repos,
        technique: technique,
      );
      if (cubit == null) {
        markTestSkipped('no ${technique.name} drill available');
        return;
      }

      expect(cubit.state.isDrill, isTrue);
      expect(cubit.state.status, GameStatus.playing);

      // Ask, escalate, escalate, apply.
      for (var i = 0; i < 4; i++) {
        cubit.useHint();
      }
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, GameStatus.complete,
          reason: 'the drill move was made — the drill is over, and the '
              'screen has nothing to navigate on unless the status says so');
      await cubit.close();
    });
  }
}
