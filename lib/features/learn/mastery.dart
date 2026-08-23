import '../../engine/deduction/deduction.dart';

/// How well a player knows one technique.
///
/// Five steps rather than a score out of a hundred. A percentage implies a
/// precision this data does not have — six drills cannot distinguish 71 from
/// 78 — and it invites grinding a number instead of learning a pattern. A
/// level says the true thing: where you are, and what the next step is.
enum MasteryLevel {
  /// Never met it.
  unseen,

  /// It has turned up in a puzzle, but you have never drilled it.
  seen,

  /// Drilled, but still leaning on hints.
  learning,

  /// Spotting it unaided, most of the time.
  practised,

  /// Reliable and quick.
  mastered;

  String get label => switch (this) {
        MasteryLevel.unseen => 'not met yet',
        MasteryLevel.seen => 'seen in play',
        MasteryLevel.learning => 'learning',
        MasteryLevel.practised => 'practised',
        MasteryLevel.mastered => 'mastered',
      };
}

/// One technique's record.
///
/// The clean signal is drills, and that is deliberate. In ordinary play
/// "spotted it unaided" is not observable for any elimination technique: the
/// hint writes pencil marks, note actions carry no attribution, and a wrong
/// digit left on the board makes every later step unreadable. A drill has
/// none of that — one known technique, one move, one outcome. So drills
/// decide the level, and play contributes context.
class TechniqueMastery {
  const TechniqueMastery({
    required this.technique,
    this.drillsAttempted = 0,
    this.drillsUnaided = 0,
    this.encountered = 0,
    this.assisted = 0,
    this.bestSeconds,
    this.lastPractisedAt,
  });

  final Technique technique;

  /// Drills started.
  final int drillsAttempted;

  /// Drills finished without taking a hint. The headline number.
  final int drillsUnaided;

  /// Times the technique appeared in a puzzle you completed. Honest but
  /// weak — it says the puzzle needed it, not that you saw it.
  final int encountered;

  /// Times a hint explained this technique to you.
  final int assisted;

  final int? bestSeconds;
  final DateTime? lastPractisedAt;

  /// Unaided rate, or null below the point where it means anything.
  ///
  /// Two drills can read 100% or 0% on luck alone. Showing that as a score
  /// would be inventing confidence the data has not earned.
  double? get accuracy =>
      drillsAttempted >= _minimumForRate ? drillsUnaided / drillsAttempted : null;

  static const int _minimumForRate = 3;

  MasteryLevel get level {
    if (drillsAttempted == 0) {
      return encountered > 0 ? MasteryLevel.seen : MasteryLevel.unseen;
    }
    if (drillsUnaided >= 6 && (accuracy ?? 0) >= 0.8) {
      return MasteryLevel.mastered;
    }
    if (drillsUnaided >= 3 && (accuracy ?? 0) >= 0.6) {
      return MasteryLevel.practised;
    }
    return MasteryLevel.learning;
  }

  /// Progress toward the next level, 0..1. Null once mastered.
  ///
  /// Drives the only bar shown, so a player can see that another two clean
  /// drills would move them rather than guessing.
  double? get progressToNext => switch (level) {
        MasteryLevel.mastered => null,
        MasteryLevel.unseen => 0,
        MasteryLevel.seen => 0,
        MasteryLevel.learning => (drillsUnaided / 3).clamp(0.0, 1.0),
        MasteryLevel.practised => (drillsUnaided / 6).clamp(0.0, 1.0),
      };

  /// What would move this on, said plainly. Null once mastered.
  String? get nextStep => switch (level) {
        MasteryLevel.mastered => null,
        MasteryLevel.unseen => 'try a drill.',
        MasteryLevel.seen => 'you have met this. drill it to find out if it '
            'stuck.',
        MasteryLevel.learning => () {
            final togo = 3 - drillsUnaided;
            return togo <= 0
                ? 'keep going — accuracy needs to come up.'
                : 'spot it unaided $togo more time${togo == 1 ? '' : 's'}.';
          }(),
        MasteryLevel.practised => () {
            final togo = 6 - drillsUnaided;
            return togo <= 0
                ? 'nearly there — keep the accuracy up.'
                : '$togo more clean spot${togo == 1 ? '' : 's'} to master it.';
          }(),
      };

  TechniqueMastery copyWith({
    int? drillsAttempted,
    int? drillsUnaided,
    int? encountered,
    int? assisted,
    int? bestSeconds,
    DateTime? lastPractisedAt,
  }) =>
      TechniqueMastery(
        technique: technique,
        drillsAttempted: drillsAttempted ?? this.drillsAttempted,
        drillsUnaided: drillsUnaided ?? this.drillsUnaided,
        encountered: encountered ?? this.encountered,
        assisted: assisted ?? this.assisted,
        bestSeconds: bestSeconds ?? this.bestSeconds,
        lastPractisedAt: lastPractisedAt ?? this.lastPractisedAt,
      );
}

/// The whole profile, and what to suggest next.
class MasteryProfile {
  const MasteryProfile(this.byTechnique);

  final Map<Technique, TechniqueMastery> byTechnique;

  TechniqueMastery operator [](Technique t) =>
      byTechnique[t] ?? TechniqueMastery(technique: t);

  /// The technique to learn next.
  ///
  /// Easiest-first, and never skips ahead: there is no point suggesting a
  /// swordfish to somebody who has not got hidden singles down, because the
  /// swordfish drill will be unreadable to them. Nothing is *locked* — the
  /// whole library stays open, because gating content behind progress is a
  /// dark pattern and this app does not have those. This is a suggestion.
  Technique? get suggested {
    // By difficulty, not declaration order — a technique appended to the enum
    // later still gets suggested in the right place.
    final byDifficulty = [...Technique.values]
      ..sort((a, b) => a.rank.compareTo(b.rank));
    for (final t in byDifficulty) {
      if (!t.isDrillable) continue;
      if (this[t].level.index < MasteryLevel.practised.index) return t;
    }
    return null;
  }

  int get masteredCount => byTechnique.values
      .where((m) => m.level == MasteryLevel.mastered)
      .length;

  int get drillableCount =>
      Technique.values.where((t) => t.isDrillable).length;
}
