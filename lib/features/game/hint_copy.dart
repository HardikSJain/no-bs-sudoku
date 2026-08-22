import '../../engine/deduction/deduction.dart';
import '../../engine/deduction/units.dart';
import 'hint_engine.dart';
import 'technique_copy.dart';

/// Every string the hint system can say.
///
/// All of it lives here so the voice rule lives in one place: lowercase, dry,
/// calm, no exclamation points. The engine deals in data and never in prose,
/// which is also what lets the ladder be tested without matching text.
class HintCopy {
  const HintCopy._();

  /// The line shown for [result] at [rung].
  static String forResult(HintResult result, HintRung rung) =>
      switch (result) {
        HintWrongDigit(cells: final cells) => _wrongDigit(cells, rung),
        HintStep(deduction: final d, honoursSelection: final honoured) =>
          _step(d, rung, honoured),
        HintNothing() => 'nothing to go on from here.',
      };

  // ── something is wrong ──────────────────────────────────────────────

  static String _wrongDigit(List<int> cells, HintRung rung) {
    // No technique can run against a contradictory board, so this escalates
    // toward finding the mistake rather than toward a deduction.
    final n = cells.length;
    return switch (rung) {
      HintRung.locate => n == 1
          ? 'something you\'ve placed is wrong.'
          : '$n of the digits you\'ve placed are wrong.',
      HintRung.narrow =>
        'it\'s in ${_unitName(cells.first)}. check that one again.',
      HintRung.explain || HintRung.apply => 'this one: ${_cellName(cells.first)}.',
    };
  }

  // ── a real step ─────────────────────────────────────────────────────

  static String _step(Deduction d, HintRung rung, bool honoured) {
    final lead = honoured ? '' : 'nothing provable there yet. ';
    return lead + switch (rung) {
          HintRung.locate => _locate(d),
          HintRung.narrow => _narrow(d),
          HintRung.explain => _explain(d),
          HintRung.apply => _apply(d),
        };
  }

  static String _locate(Deduction d) {
    final unit = d.unit;
    if (unit != null) return 'there\'s something in $unit.';

    // A naked single is not *about* a unit — its proof is the filled peers —
    // so it carries none. It is still very much in one place, and telling a
    // player it is "spread across the board" would send them looking
    // everywhere for a cell sitting in one box.
    final boxes = {for (final idx in d.cells) Units.boxOf[idx]};
    if (boxes.length == 1) {
      return 'there\'s something in box ${boxes.first + 1}.';
    }

    // Fish and chains genuinely do span the grid.
    return 'there\'s something to find, spread across the board.';
  }

  static String _narrow(Deduction d) => switch (d.kind) {
        DeductionKind.placement => 'this cell can be settled.',
        DeductionKind.elimination => d.targets.length == 1
            ? 'one candidate here can go.'
            : '${d.targets.length} candidates can go.',
      };

  static String _explain(Deduction d) => switch (d.kind) {
        DeductionKind.placement => _explainPlacement(d),
        DeductionKind.elimination => _explainElimination(d),
      };

  static String _explainPlacement(Deduction d) => switch (d.technique) {
        Technique.nakedSingle =>
          'only one digit still fits here. everything else is taken by a '
              'row, column or box it can see.',
        Technique.hiddenSingle =>
          'this is the only cell in ${d.unit} where that digit can still go.',
        _ => 'a ${d.technique.singular} settles this cell.',
      };

  static String _explainElimination(Deduction d) {
    final digits = _list(d.digits.map((n) => '$n').toList());
    return switch (d.technique) {
      Technique.nakedPair || Technique.nakedTriple =>
        'the highlighted cells hold $digits between them, whatever the order. '
            'so nothing else in ${d.unit} can take those.',
      Technique.hiddenPair || Technique.hiddenTriple =>
        'those digits have nowhere else to go in ${d.unit}, so the '
            'highlighted cells are spoken for. the rest can go.',
      Technique.pointingPair =>
        'inside ${d.unit} that digit only fits on one line. so it is on that '
            'line somewhere, and cannot be anywhere else along it.',
      Technique.boxLineReduction =>
        'along ${d.unit} that digit only fits inside one box. so it is in '
            'that box, and cannot be elsewhere in it.',
      Technique.xWing =>
        'two rows, two columns, four corners. the digit takes one corner on '
            'each row, so those columns are used up.',
      Technique.swordfish =>
        'three lines, three columns, and the digit has to take one on each. '
            'that uses up all three columns.',
      Technique.xyWing =>
        'the middle cell is one of two digits. either way, one of the two '
            'ends is forced — so anything seeing both ends cannot be $digits.',
      Technique.simpleColoring =>
        'following that digit through the board, the highlighted cells '
            'alternate between must-be and cannot-be. that settles it.',
      _ => 'a ${d.technique.singular} rules $digits out here.',
    };
  }

  static String _apply(Deduction d) => switch (d.kind) {
        DeductionKind.placement =>
          '${d.targets.first.$2} goes in ${_cellName(d.targets.first.$1)}.',
        DeductionKind.elimination => d.targets.length == 1
            ? 'removed ${d.digits.first} from ${_cellName(d.targets.first.$1)}.'
            : 'removed ${d.targets.length} candidates.',
      };

  /// The technique, named. Shown as a label beside the explanation so the
  /// name is learnable on its own.
  static String? techniqueLabel(HintResult result, HintRung rung) {
    if (result is! HintStep) return null;
    if (rung.index < HintRung.explain.index) return null;
    return result.deduction.technique.singular;
  }

  // ── helpers ─────────────────────────────────────────────────────────

  static String _cellName(int idx) => 'r${idx ~/ 9 + 1}c${idx % 9 + 1}';

  static String _unitName(int idx) => 'box ${Units.boxOf[idx] + 1}';

  static String _list(List<String> parts) => switch (parts.length) {
        0 => '',
        1 => parts.first,
        2 => '${parts[0]} and ${parts[1]}',
        _ => '${parts.sublist(0, parts.length - 1).join(', ')} '
            'and ${parts.last}',
      };
}
