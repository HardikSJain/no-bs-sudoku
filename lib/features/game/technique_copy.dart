import '../../engine/deduction/deduction.dart';

/// How each technique is named to a player.
///
/// The engine deals in data, never prose — that keeps the voice rule in one
/// place and lets the ladder be tested without matching strings. This is that
/// one place.
extension TechniqueCopy on Technique {
  /// Plural, for describing a whole solve: "needed nothing past hidden
  /// singles."
  String get plural => switch (this) {
        Technique.nakedSingle => 'naked singles',
        Technique.hiddenSingle => 'hidden singles',
        Technique.nakedPair => 'naked pairs',
        Technique.hiddenPair => 'hidden pairs',
        Technique.nakedTriple => 'naked triples',
        Technique.hiddenTriple => 'hidden triples',
        Technique.pointingPair => 'pointing pairs',
        Technique.boxLineReduction => 'box-line reductions',
        Technique.xWing => 'x-wings',
        Technique.swordfish => 'swordfish',
        Technique.jellyfish => 'jellyfish',
        Technique.xyWing => 'xy-wings',
        Technique.xyzWing => 'xyz-wings',
        Technique.wWing => 'w-wings',
        Technique.simpleColoring => 'coloring',
      };

  /// Singular, for describing one step: "this is a pointing pair."
  String get singular => switch (this) {
        Technique.nakedSingle => 'naked single',
        Technique.hiddenSingle => 'hidden single',
        Technique.nakedPair => 'naked pair',
        Technique.hiddenPair => 'hidden pair',
        Technique.nakedTriple => 'naked triple',
        Technique.hiddenTriple => 'hidden triple',
        Technique.pointingPair => 'pointing pair',
        Technique.boxLineReduction => 'box-line reduction',
        Technique.xWing => 'x-wing',
        Technique.swordfish => 'swordfish',
        Technique.jellyfish => 'jellyfish',
        Technique.xyWing => 'xy-wing',
        Technique.xyzWing => 'xyz-wing',
        Technique.wWing => 'w-wing',
        Technique.simpleColoring => 'coloring',
      };
}

/// What a difficulty promises, stated as the ceiling it is.
///
/// "medium - pairs" would promise a puzzle that *needs* a pair, and
/// generation deliberately does not deliver that: the tier is a ceiling with
/// no floor, so a medium may well be all singles. Saying "never needs more
/// than" is the only honest phrasing.
extension TierCopy on TechniqueTier {
  /// The compact form, for the difficulty cards on home. Same promise as
  /// [ceilingLabel], short enough for a 9pt line.
  String get ceilingShort => switch (this) {
        TechniqueTier.singles => 'singles only',
        TechniqueTier.pairs => 'up to pairs',
        TechniqueTier.intersections => 'up to intersections',
        TechniqueTier.fish => 'needs a fish',
        TechniqueTier.chains => 'needs a chain',
      };

  String get ceilingLabel => switch (this) {
        TechniqueTier.singles => 'never needs more than singles',
        TechniqueTier.pairs => 'never needs more than pairs',
        TechniqueTier.intersections => 'never needs more than intersections',
        TechniqueTier.fish => 'needs a fish',
        TechniqueTier.chains => 'needs a chain',
      };
}
