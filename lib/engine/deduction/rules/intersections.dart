import '../candidate_grid.dart';
import '../deduction.dart';
import '../technique_rule.dart';
import '../units.dart';

/// Box → line. Every spot for a digit inside one box sits in the same row or
/// column, so the digit is somewhere on that line inside the box — and
/// therefore nowhere else along the line.
class PointingPairRule implements TechniqueRule {
  const PointingPairRule();

  @override
  Technique get technique => Technique.pointingPair;

  @override
  TechniqueTier get tier => TechniqueTier.intersections;

  @override
  Deduction? find(CandidateGrid grid) {
    for (int box = 0; box < 9; box++) {
      final boxUnit = 18 + box;
      for (int digit = 1; digit <= 9; digit++) {
        final spots = grid.cellsWithCandidate(boxUnit, digit);
        if (spots.length < 2) continue;

        for (final lineUnit in _sharedLine(spots)) {
          final targets = <(int, int)>[
            for (final idx in Units.unitCells[lineUnit])
              if (Units.boxOf[idx] != box && grid.hasCandidate(idx, digit))
                (idx, digit),
          ];
          if (targets.isEmpty) continue;
          return Deduction(
            technique: technique,
            kind: DeductionKind.elimination,
            targets: targets,
            witnesses: spots,
            unit: UnitRef.fromId(boxUnit),
          );
        }
      }
    }
    return null;
  }
}

/// Line → box. Every spot for a digit along one row or column sits in the
/// same box, so the digit is in that box on that line — and therefore nowhere
/// else in the box.
class BoxLineReductionRule implements TechniqueRule {
  const BoxLineReductionRule();

  @override
  Technique get technique => Technique.boxLineReduction;

  @override
  TechniqueTier get tier => TechniqueTier.intersections;

  @override
  Deduction? find(CandidateGrid grid) {
    // Rows are units 0-8, columns 9-17.
    for (int lineUnit = 0; lineUnit < 18; lineUnit++) {
      for (int digit = 1; digit <= 9; digit++) {
        final spots = grid.cellsWithCandidate(lineUnit, digit);
        if (spots.length < 2) continue;

        final box = Units.boxOf[spots.first];
        if (spots.any((idx) => Units.boxOf[idx] != box)) continue;

        final targets = <(int, int)>[
          for (final idx in Units.unitCells[18 + box])
            if (!spots.contains(idx) && grid.hasCandidate(idx, digit))
              (idx, digit),
        ];
        if (targets.isEmpty) continue;

        return Deduction(
          technique: technique,
          kind: DeductionKind.elimination,
          targets: targets,
          witnesses: spots,
          unit: UnitRef.fromId(lineUnit),
        );
      }
    }
    return null;
  }
}

/// The row and column units that contain every one of [cells], if any.
Iterable<int> _sharedLine(List<int> cells) sync* {
  final row = Units.rowOf[cells.first];
  if (cells.every((idx) => Units.rowOf[idx] == row)) yield row;
  final col = Units.colOf[cells.first];
  if (cells.every((idx) => Units.colOf[idx] == col)) yield 9 + col;
}
