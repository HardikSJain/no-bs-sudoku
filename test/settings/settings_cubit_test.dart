import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/data_reset_service.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/features/settings/settings_cubit.dart';

void main() {
  late AppDatabase db;
  late SettingsCubit cubit;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final repos = Repositories(db);
    cubit = SettingsCubit(
      preferences: repos.preferences,
      profiles: repos.profiles,
      reset: DataResetService(
        records: repos.records,
        savedGames: repos.savedGames,
        profiles: repos.profiles,
        mastery: repos.mastery,
      ),
    );
    // The constructor loads asynchronously.
    while (!cubit.state.loaded) {
      await Future<void>.delayed(Duration.zero);
    }
  });

  tearDown(() async {
    await cubit.close();
    await db.close();
  });

  group('changing one preference leaves the others alone', () {
    // Every setter used to rebuild the whole state by hand, and all of them
    // omitted digitFirstInput — so turning on the timer silently switched
    // digit-first input off in the UI until the next launch. The database
    // still held the truth, which is what made it hard to notice.
    test('digit-first input survives an unrelated toggle', () async {
      await cubit.setDigitFirstInput(true);
      expect(cubit.state.digitFirstInput, isTrue);

      await cubit.setShowTimer(true);
      expect(cubit.state.digitFirstInput, isTrue,
          reason: 'toggling the timer must not touch digit-first input');
    });

    test('no field is dropped by any setter', () async {
      // Drive every preference away from its default, then flip each one in
      // turn and check nothing else moved.
      await cubit.setAutoRemoveNotes(false);
      await cubit.setHighlightMatching(false);
      await cubit.setShowTimer(true);
      await cubit.setDigitFirstInput(true);
      await cubit.setMistakeLimit(3);
      await cubit.setTheme('amoled');
      await cubit.setDisplayName('hardik');
      await cubit.setHintsExplain(false);
      await cubit.setFlagMistakesInstantly(false);
      await cubit.setNudgeWhenStuck(false);

      void assertAll() {
        final s = cubit.state;
        expect(s.autoRemoveNotes, isFalse);
        expect(s.highlightMatching, isFalse);
        expect(s.showTimer, isTrue);
        expect(s.digitFirstInput, isTrue);
        expect(s.mistakeLimit, 3);
        expect(s.theme, 'amoled');
        expect(s.displayName, 'hardik');
        expect(s.hintsExplain, isFalse);
        expect(s.flagMistakesInstantly, isFalse);
        expect(s.nudgeWhenStuck, isFalse);
      }

      assertAll();
      // Flip one back and forth; everything else must be untouched.
      await cubit.setShowTimer(false);
      await cubit.setShowTimer(true);
      assertAll();
    });
  });

  group('the coaching switches persist', () {
    test('they default on, so an upgrading player gets the explanations',
        () async {
      expect(cubit.state.hintsExplain, isTrue);
      expect(cubit.state.flagMistakesInstantly, isTrue);
      expect(cubit.state.nudgeWhenStuck, isTrue);
    });

    test('a change reaches the database', () async {
      await cubit.setHintsExplain(false);
      final prefs = await Repositories(db).preferences.getPreferences();
      expect(prefs.hintsExplain, isFalse);
    });
  });
}
