import '../../engine/deduction/deduction.dart';

/// What a technique is, in words a player can act on.
///
/// Named techniques are the vocabulary of sudoku, and an app that shows a
/// player a "swordfish" without ever saying what one is has taught them
/// nothing — it has only made them feel behind. Every entry answers two
/// questions: what is this, and how do I spot it.
class TechniqueGuide {
  const TechniqueGuide({
    required this.oneLine,
    required this.how,
    required this.lookFor,
  });

  /// One sentence, no jargon. Shown next to the name everywhere.
  final String oneLine;

  /// Why it works. Two or three sentences.
  final String how;

  /// The recognition cue — what to actually run your eye over. This is the
  /// part that turns knowing the name into being able to use it.
  final String lookFor;

  static const Map<Technique, TechniqueGuide> _guides = {
    Technique.nakedSingle: TechniqueGuide(
      oneLine: 'a cell with only one digit left.',
      how: 'the cell can see a row, a column and a box. between them they '
          'rule out eight of the nine digits, and whatever survives has to go '
          'there.',
      lookFor: 'the busiest empty cells. the more filled neighbours a cell '
          'has, the fewer options it can still hold.',
    ),
    Technique.hiddenSingle: TechniqueGuide(
      oneLine: 'a digit with only one home left in a row, column or box.',
      how: 'the cell may still have several candidates of its own, which is '
          'what makes it hidden. that does not matter — the digit has to go '
          'somewhere in the unit, and only one cell can take it.',
      lookFor: 'pick a digit, pick a box, and cross off every cell already '
          'blocked by that digit in a crossing row or column. if one cell is '
          'left standing, it is that digit.',
    ),
    Technique.nakedPair: TechniqueGuide(
      oneLine: 'two cells in one unit holding the same two digits.',
      how: 'between them those two cells use up both digits, whichever way '
          'round they fall. so nothing else in that row, column or box can '
          'take either one.',
      lookFor: 'two cells in the same unit showing an identical pair of '
          'pencil marks.',
    ),
    Technique.hiddenPair: TechniqueGuide(
      oneLine: 'two digits that can only go in the same two cells.',
      how: 'those two cells are spoken for by those two digits, so every '
          'other candidate in them can go — even though the cells may look '
          'crowded.',
      lookFor: 'count where each digit can still go in a unit. two digits '
          'that both land on the same two cells are a hidden pair.',
    ),
    Technique.nakedTriple: TechniqueGuide(
      oneLine: 'three cells holding three digits between them.',
      how: 'the same argument as a naked pair, one size up. no cell needs all '
          'three candidates — only the three digits, across the three cells.',
      lookFor: 'three cells in a unit whose pencil marks, pooled together, '
          'come to exactly three digits.',
    ),
    Technique.hiddenTriple: TechniqueGuide(
      oneLine: 'three digits confined to the same three cells.',
      how: 'those three cells must take those three digits, so anything else '
          'pencilled into them is wrong and can be rubbed out.',
      lookFor: 'three digits in a unit whose possible homes, pooled together, '
          'come to exactly three cells.',
    ),
    Technique.pointingPair: TechniqueGuide(
      oneLine: 'inside one box, a digit only fits along a single line.',
      how: 'the digit has to appear somewhere in that box, and every place it '
          'could go sits on one row or column. so it is on that line — and '
          'therefore nowhere else along it, outside the box.',
      lookFor: 'a digit that only appears two or three times in a box, all in '
          'the same row or the same column.',
    ),
    Technique.boxLineReduction: TechniqueGuide(
      oneLine: 'along one line, a digit only fits inside a single box.',
      how: 'the reverse of a pointing pair. the digit has to appear on that '
          'line, and every place it could go sits in one box — so it is in '
          'that box, and can go from the rest of it.',
      lookFor: 'a digit whose remaining homes on a row or column all fall '
          'inside the same three-by-three block.',
    ),
    Technique.xWing: TechniqueGuide(
      oneLine: 'the same digit, in the same two columns, on two rows.',
      how: 'each of those rows must place the digit in one of the two '
          'columns. between them they take both columns, whichever way it '
          'falls — so the digit cannot appear in those columns on any other '
          'row.',
      lookFor: 'two rows where a digit has exactly two homes, and both rows '
          'use the same pair of columns. it works with rows and columns '
          'swapped too.',
    ),
    Technique.swordfish: TechniqueGuide(
      oneLine: 'an x-wing one size larger: three rows, three columns.',
      how: 'three rows, and between them the digit only fits in three '
          'columns. the three rows use up all three columns, so the digit '
          'goes from those columns everywhere else.',
      lookFor: 'three rows where a digit has two or three homes each, and all '
          'of them fall inside the same three columns. the rows do not each '
          'need all three.',
    ),
    Technique.xyWing: TechniqueGuide(
      oneLine: 'three two-candidate cells hinged together.',
      how: 'a pivot holding x and y sees one cell holding x and z, and '
          'another holding y and z. whichever way the pivot falls, one of the '
          'two ends is forced to z — so anything that sees both ends cannot '
          'be z.',
      lookFor: 'a cell with exactly two candidates that sees two more '
          'two-candidate cells, all three sharing digits in a chain.',
    ),
    Technique.simpleColoring: TechniqueGuide(
      oneLine: 'follow one digit through the units where it has two homes.',
      how: 'if a unit has exactly two places for a digit, one is true and the '
          'other is false. chaining those pairs together colours the grid in '
          'two alternating groups, and exactly one group is the true one. any '
          'cell seeing both colours cannot hold the digit.',
      lookFor: 'a digit with exactly two homes in several units that link up '
          'cell to cell.',
    ),
  };

  static TechniqueGuide of(Technique technique) => _guides[technique]!;

  /// Every technique has an entry. Asserted by test, because a missing one
  /// would show a blank card at the exact moment someone is trying to learn.
  static bool get isComplete => _guides.length == Technique.values.length;
}

/// What the two deep tiers actually ask of you.
///
/// "needs a fish" is a promise to someone who already knows the word and a
/// closed door to everyone else. Naming the techniques opens it.
extension TierGuide on TechniqueTier {
  String get plainName => switch (this) {
        TechniqueTier.singles => 'singles',
        TechniqueTier.pairs => 'pairs and triples',
        TechniqueTier.intersections => 'box and line logic',
        TechniqueTier.fish => 'fish',
        TechniqueTier.chains => 'chains',
      };

  /// The techniques this tier is made of, named.
  String get contains => switch (this) {
        TechniqueTier.singles => 'naked and hidden singles',
        TechniqueTier.pairs => 'naked and hidden pairs and triples',
        TechniqueTier.intersections => 'pointing pairs, box-line reduction',
        TechniqueTier.fish => 'x-wing, swordfish',
        TechniqueTier.chains => 'xy-wing, coloring',
      };

  String get blurb => switch (this) {
        TechniqueTier.singles =>
          'one cell, one digit. scanning and elimination.',
        TechniqueTier.pairs =>
          'cells that share candidates, and the digits that share cells.',
        TechniqueTier.intersections =>
          'where a box and a line overlap, and what that forces.',
        TechniqueTier.fish =>
          'the same digit lining up across several rows and columns at once.',
        TechniqueTier.chains =>
          'following one digit through the grid until it contradicts itself.',
      };
}
