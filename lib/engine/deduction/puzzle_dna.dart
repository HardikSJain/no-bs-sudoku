import 'deduction.dart';
import 'solve_path_analysis.dart';

/// A puzzle's fingerprint: which techniques its solve needed, and how many
/// times each.
///
/// The point of a fingerprint is that two people can compare one. That only
/// works if the same grid produces the same string everywhere, and the DNA is
/// a *function of the path `solve()` happens to pick* — so anything that
/// changes the ladder changes the fingerprint.
///
/// Two rules keep it comparable:
///
/// 1. **Canonical ordering.** Counts are emitted in [Technique] declaration
///    order, never in discovery order and never sorted by count. Adding a
///    technique to the enum must append it, never insert it.
/// 2. **[version] bumps whenever the ladder changes** — a new rule, a
///    reordered ladder, or a changed rule that alters which step gets picked
///    first. Comparing across versions is meaningless and the prefix is what
///    makes that visible instead of silent.
class PuzzleDna {
  const PuzzleDna(this.counts);

  factory PuzzleDna.of(SolvePathAnalysis analysis) => PuzzleDna({
        for (final use in analysis.uses) use.technique: use.count,
      });

  /// Bump on any change to the technique ladder — its membership, its order,
  /// or the behaviour of a rule in a way that changes which step is found
  /// first. Two builds that disagree here are not comparable, and saying so
  /// is the whole job of this number.
  static const int version = 2;

  final Map<Technique, int> counts;

  /// Compact and comparable: `v1:12.4.0.0.1.0.0.0.0.0.2.0`.
  ///
  /// Every technique gets a slot whether or not it was used, so the string
  /// keeps its shape as the enum grows and a reader can diff two of them
  /// position by position.
  String get fingerprint {
    final slots = [
      for (final t in Technique.values) (counts[t] ?? 0).toString(),
    ];
    return 'v$version:${slots.join('.')}';
  }

  /// The techniques actually used, hardest first — what a share card shows,
  /// as opposed to what a machine compares.
  List<MapEntry<Technique, int>> get spectrum {
    final used = [
      for (final entry in counts.entries)
        if (entry.value > 0) entry,
    ]..sort((a, b) => b.key.rank.compareTo(a.key.rank));
    return used;
  }

  int get totalSteps => counts.values.fold(0, (n, c) => n + c);

  /// True when both were produced by the same ladder, and so can be compared
  /// at all.
  static bool comparable(String a, String b) =>
      a.split(':').first == b.split(':').first;

  @override
  String toString() => fingerprint;
}
