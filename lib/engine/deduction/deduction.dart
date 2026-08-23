import 'units.dart';

/// Ordered easiest-first. The ladder always tries lower tiers before higher
/// ones, so a hint never explains an x-wing when a naked single was sitting
/// there.
enum TechniqueTier { singles, pairs, intersections, fish, chains }

/// Every technique the engine can see and explain.
///
/// Order within a tier is the order the ladder tries them, so cheaper rules
/// come first.
enum Technique {
  nakedSingle(TechniqueTier.singles),
  hiddenSingle(TechniqueTier.singles),
  nakedPair(TechniqueTier.pairs),
  hiddenPair(TechniqueTier.pairs),
  nakedTriple(TechniqueTier.pairs),
  hiddenTriple(TechniqueTier.pairs),
  pointingPair(TechniqueTier.intersections),
  boxLineReduction(TechniqueTier.intersections),
  xWing(TechniqueTier.fish),
  swordfish(TechniqueTier.fish),
  xyWing(TechniqueTier.chains),
  simpleColoring(TechniqueTier.chains),

  // Appended, never inserted — see [rank]. Declaration order is the DNA
  // fingerprint's slot order and must never shift; difficulty ordering comes
  // from the tier instead, so these sit in the right place regardless.
  jellyfish(TechniqueTier.fish),
  xyzWing(TechniqueTier.chains);

  const Technique(this.tier);

  final TechniqueTier tier;

  /// How hard this is, for ordering.
  ///
  /// Not the enum index, and the distinction matters. The DNA fingerprint
  /// emits one slot per technique in declaration order, so a new technique
  /// must be *appended* — inserting one shifts the meaning of every
  /// fingerprint ever shared. But appending puts a jellyfish after coloring
  /// in the enum, and a jellyfish is not harder than a chain.
  ///
  /// So difficulty comes from the tier first, and only then from declaration
  /// order within that tier. Anything comparing "which of these is harder"
  /// uses this; only the fingerprint uses the raw index.
  int get rank => tier.index * 100 + _positionInTier;

  int get _positionInTier {
    int n = 0;
    for (final t in Technique.values) {
      if (t == this) return n;
      if (t.tier == tier) n++;
    }
    return n;
  }

  /// Whether a puzzle can realistically be built whose *crux* is this
  /// technique — one that cannot be finished without it, working inside its
  /// own tier.
  ///
  /// Every technique but one clears roughly 25-75% of attempts. `nakedTriple`
  /// measured at zero over 1600 attempts, and that is a fact about sudoku
  /// rather than a gap in the generator: three cells holding three digits
  /// almost always contain a naked or hidden pair that reaches the same
  /// eliminations first, so the triple is available but never *required*.
  /// Offering a drill that reliably fails to generate would be worse than
  /// not offering it.
  bool get isDrillable => this != Technique.nakedTriple;
}

enum DeductionKind {
  /// [Deduction.targets] are digits to write in.
  placement,

  /// [Deduction.targets] are candidates to rub out.
  elimination,
}

/// One logical step, as data rather than prose.
///
/// Copy is generated in the presentation layer. Keeping strings out of the
/// engine keeps the voice rule in one place and lets the ladder be tested
/// without matching text.
///
/// This is a value type, and four features depend on that: hint pinning
/// compares the previous deduction against the current one, hint invalidation
/// is literally an equality test against a freshly-found deduction, the JSON
/// round-trip must survive a restore, and mastery dedup needs it later.
/// [targets] and [witnesses] are sorted on construction so two deductions that
/// say the same thing compare equal regardless of the order the rule happened
/// to find the cells in.
class Deduction {
  Deduction({
    required this.technique,
    required this.kind,
    required List<(int, int)> targets,
    List<int> witnesses = const [],
    this.unit,
  })  : targets = List.unmodifiable(
          [...targets]..sort((a, b) => a.$1 != b.$1
              ? a.$1.compareTo(b.$1)
              : a.$2.compareTo(b.$2)),
        ),
        witnesses = List.unmodifiable([...witnesses]..sort());

  final Technique technique;
  final DeductionKind kind;

  /// `(cellIndex, digit)` pairs — to write in, or to rub out.
  final List<(int, int)> targets;

  /// The cells that prove it. The UI highlights these.
  final List<int> witnesses;

  /// Where to look, for the "look here" nudge. Null when the deduction is not
  /// anchored to one unit.
  final UnitRef? unit;

  /// The digits this step is about, ascending — used for copy and for the
  /// number-pad highlight.
  List<int> get digits => (targets.map((t) => t.$2).toSet().toList())..sort();

  /// The cells this step acts on, ascending.
  List<int> get cells => (targets.map((t) => t.$1).toSet().toList())..sort();

  @override
  bool operator ==(Object other) =>
      other is Deduction &&
      other.technique == technique &&
      other.kind == kind &&
      other.unit == unit &&
      _sameTargets(other.targets, targets) &&
      _sameInts(other.witnesses, witnesses);

  @override
  int get hashCode => Object.hash(
        technique,
        kind,
        unit,
        Object.hashAll(targets.map((t) => Object.hash(t.$1, t.$2))),
        Object.hashAll(witnesses),
      );

  @override
  String toString() => '${technique.name}(${kind.name} '
      '${targets.map((t) => 'r${t.$1 ~/ 9 + 1}c${t.$1 % 9 + 1}=${t.$2}').join(', ')})';

  static bool _sameTargets(List<(int, int)> a, List<(int, int)> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].$1 != b[i].$1 || a[i].$2 != b[i].$2) return false;
    }
    return true;
  }

  static bool _sameInts(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
