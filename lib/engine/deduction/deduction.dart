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
  simpleColoring(TechniqueTier.chains);

  const Technique(this.tier);

  final TechniqueTier tier;
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
