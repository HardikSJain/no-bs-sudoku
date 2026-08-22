import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/data_reset_service.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/features/learn/mastery.dart';
import 'package:no_bs_sudoku/features/learn/technique_guide.dart';

void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  Future<void> drills(Technique t, int n, {required bool unaided}) async {
    for (int i = 0; i < n; i++) {
      await repos.mastery.recordDrill(t,
          unaided: unaided, seconds: 20 + i, at: DateTime.utc(2026, 8, 22));
    }
  }

  group('the level tells the truth about the data', () {
    test('never met means never met', () async {
      final p = await repos.mastery.getProfile();
      expect(p[Technique.xyWing].level, MasteryLevel.unseen);
    });

    test('seen in play is not the same as practised', () async {
      // The distinction the whole design turns on: a puzzle needing a
      // technique says nothing about whether the player recognised it.
      await repos.mastery.recordEncountered([Technique.pointingPair]);
      final p = await repos.mastery.getProfile();
      expect(p[Technique.pointingPair].level, MasteryLevel.seen);
      expect(p[Technique.pointingPair].drillsAttempted, 0);
    });

    test('hinted drills never reach practised', () async {
      // Being shown the answer six times is not evidence of anything.
      await drills(Technique.nakedPair, 6, unaided: false);
      final p = await repos.mastery.getProfile();
      expect(p[Technique.nakedPair].level, MasteryLevel.learning);
      expect(p[Technique.nakedPair].drillsUnaided, 0);
    });

    test('clean drills climb the ladder', () async {
      await drills(Technique.hiddenSingle, 3, unaided: true);
      var p = await repos.mastery.getProfile();
      expect(p[Technique.hiddenSingle].level, MasteryLevel.practised);

      await drills(Technique.hiddenSingle, 3, unaided: true);
      p = await repos.mastery.getProfile();
      expect(p[Technique.hiddenSingle].level, MasteryLevel.mastered);
    });

    test('mastery needs accuracy, not just volume', () async {
      // Six clean spots buried in twenty hinted attempts is not mastery.
      await drills(Technique.xWing, 6, unaided: true);
      await drills(Technique.xWing, 14, unaided: false);
      final p = await repos.mastery.getProfile();
      expect(p[Technique.xWing].level, isNot(MasteryLevel.mastered));
    });
  });

  group('it does not invent precision', () {
    test('no accuracy figure below three attempts', () async {
      await drills(Technique.swordfish, 2, unaided: true);
      final p = await repos.mastery.getProfile();
      // Two drills can read 100% on luck. Showing that as a score would be
      // confidence the data has not earned.
      expect(p[Technique.swordfish].accuracy, isNull);

      await drills(Technique.swordfish, 1, unaided: true);
      final p2 = await repos.mastery.getProfile();
      expect(p2[Technique.swordfish].accuracy, 1.0);
    });

    test('a best time is only set by a clean solve', () async {
      await repos.mastery.recordDrill(Technique.nakedPair,
          unaided: false, seconds: 5, at: DateTime.utc(2026));
      var p = await repos.mastery.getProfile();
      expect(p[Technique.nakedPair].bestSeconds, isNull,
          reason: 'a hinted drill is not a time');

      await repos.mastery.recordDrill(Technique.nakedPair,
          unaided: true, seconds: 40, at: DateTime.utc(2026));
      p = await repos.mastery.getProfile();
      expect(p[Technique.nakedPair].bestSeconds, 40);
    });
  });

  group('what to do next', () {
    test('it suggests the easiest thing not yet practised', () async {
      final p = await repos.mastery.getProfile();
      expect(p.suggested, Technique.nakedSingle);

      await drills(Technique.nakedSingle, 3, unaided: true);
      final p2 = await repos.mastery.getProfile();
      expect(p2.suggested, Technique.hiddenSingle,
          reason: 'suggesting a swordfish to someone still on singles gives '
              'them a drill they cannot read');
    });

    test('it never suggests the undrillable one', () async {
      for (final t in Technique.values) {
        if (t == Technique.nakedTriple) continue;
        await drills(t, 6, unaided: true);
      }
      final p = await repos.mastery.getProfile();
      expect(p.suggested, isNull);
    });

    test('nothing is ever locked', () async {
      // Gating content behind progress is a dark pattern and this app does
      // not have those. The suggestion is only a suggestion.
      final p = await repos.mastery.getProfile();
      for (final t in Technique.values.where((t) => t.isDrillable)) {
        expect(p[t].level, MasteryLevel.unseen);
      }
      expect(p.drillableCount, Technique.values.length - 1);
    });
  });

  group('the guide is complete', () {
    test('every technique has an explanation and a cue', () {
      expect(TechniqueGuide.isComplete, isTrue);
      for (final t in Technique.values) {
        final g = TechniqueGuide.of(t);
        expect(g.oneLine.trim(), isNotEmpty, reason: t.name);
        expect(g.how.trim(), isNotEmpty, reason: t.name);
        expect(g.lookFor.trim(), isNotEmpty, reason: t.name);
      }
    });

    test('the guide keeps the voice rule', () {
      for (final t in Technique.values) {
        final g = TechniqueGuide.of(t);
        for (final line in [g.oneLine, g.how, g.lookFor]) {
          expect(line, isNot(contains('!')), reason: t.name);
          expect(line, equals(line.toLowerCase()), reason: '${t.name}: $line');
        }
      }
    });

    test('every tier names the techniques it contains', () {
      for (final tier in TechniqueTier.values) {
        expect(tier.contains.trim(), isNotEmpty);
        expect(tier.blurb.trim(), isNotEmpty);
        expect(tier.plainName.trim(), isNotEmpty);
      }
    });
  });

  group('a factory reset really deletes it', () {
    test('mastery does not survive', () async {
      await drills(Technique.hiddenSingle, 4, unaided: true);
      final reset = DataResetService(
        records: repos.records,
        savedGames: repos.savedGames,
        profiles: repos.profiles,
        mastery: repos.mastery,
      );
      await reset.resetAll();

      final p = await repos.mastery.getProfile();
      expect(p[Technique.hiddenSingle].level, MasteryLevel.unseen);
    });
  });
}
