import '../candidate_grid.dart';
import '../deduction.dart';
import '../technique_rule.dart';
import '../units.dart';

/// Three cells, two candidates each: a pivot {x,y} with one pincer {x,z} and
/// another {y,z}, both seeing the pivot.
///
/// The pivot is x or y, so one pincer or the other is forced to z. Either
/// way, anything that sees both pincers cannot be z.
class XyWingRule implements TechniqueRule {
  const XyWingRule();

  @override
  Technique get technique => Technique.xyWing;

  @override
  TechniqueTier get tier => TechniqueTier.chains;

  @override
  Deduction? find(CandidateGrid grid) {
    final bivalue = [
      for (final idx in grid.unsolvedCells)
        if (grid.candidateCount(idx) == 2) idx,
    ];

    for (final pivot in bivalue) {
      final pv = grid.candidatesOf(pivot).toList();
      final x = pv[0];
      final y = pv[1];

      final seen = [
        for (final idx in Units.peersOf[pivot])
          if (bivalue.contains(idx)) idx,
      ];

      for (final a in seen) {
        final am = grid.candidateMask(a);
        // Pincer A must be {x, z} — carries x, not y.
        if (am & Units.maskOf(x) == 0 || am & Units.maskOf(y) != 0) continue;
        final z = Units.digitsIn(am & ~Units.maskOf(x)).first;

        for (final b in seen) {
          if (b == a) continue;
          // Pincer B must be exactly {y, z}.
          if (grid.candidateMask(b) !=
              (Units.maskOf(y) | Units.maskOf(z))) {
            continue;
          }

          final targets = <(int, int)>[
            for (final idx in Units.peersOf[a])
              if (idx != pivot &&
                  idx != b &&
                  Units.peersOf[b].contains(idx) &&
                  grid.hasCandidate(idx, z))
                (idx, z),
          ];
          if (targets.isEmpty) continue;

          return Deduction(
            technique: technique,
            kind: DeductionKind.elimination,
            targets: targets,
            witnesses: [pivot, a, b],
          );
        }
      }
    }
    return null;
  }
}

/// An xy-wing whose pivot keeps the shared digit too.
///
/// The pivot holds x, y and z rather than just x and y, so it can itself be
/// z. That costs one thing: the eliminations have to see the pivot as well as
/// both pincers, which is why they are confined to the pivot's own box or
/// line rather than anywhere the two ends both reach.
class XyzWingRule implements TechniqueRule {
  const XyzWingRule();

  @override
  Technique get technique => Technique.xyzWing;

  @override
  TechniqueTier get tier => TechniqueTier.chains;

  @override
  Deduction? find(CandidateGrid grid) {
    for (final pivot in grid.unsolvedCells) {
      if (grid.candidateCount(pivot) != 3) continue;
      final pincers = [
        for (final idx in Units.peersOf[pivot])
          if (grid.candidateCount(idx) == 2 &&
              grid.candidateMask(idx) & ~grid.candidateMask(pivot) == 0)
            idx,
      ];

      for (int i = 0; i < pincers.length; i++) {
        for (int j = i + 1; j < pincers.length; j++) {
          final a = pincers[i];
          final b = pincers[j];
          final shared =
              grid.candidateMask(a) & grid.candidateMask(b);
          if (Units.popCount(shared) != 1) continue;
          // Between them the two pincers must cover all three of the pivot's
          // candidates, or the pivot is not forced into anything.
          if ((grid.candidateMask(a) | grid.candidateMask(b)) !=
              grid.candidateMask(pivot)) {
            continue;
          }
          final z = Units.digitsIn(shared).first;

          final targets = <(int, int)>[
            for (final idx in Units.peersOf[pivot])
              if (idx != a &&
                  idx != b &&
                  Units.peersOf[a].contains(idx) &&
                  Units.peersOf[b].contains(idx) &&
                  grid.hasCandidate(idx, z))
                (idx, z),
          ];
          if (targets.isEmpty) continue;

          return Deduction(
            technique: technique,
            kind: DeductionKind.elimination,
            targets: targets,
            witnesses: [pivot, a, b],
          );
        }
      }
    }
    return null;
  }
}

/// Two cells with the same two candidates, joined by a strong link.
///
/// Take two bi-value cells that both hold exactly {x, y} and do not see each
/// other. Find a unit where x has exactly two homes, one seen by the first
/// cell and one seen by the second. Whichever of those two homes takes x, one
/// of the pair is denied x and has to be y — so at least one of them is y,
/// and nothing that sees both can be.
///
/// It is the same shape of argument as an xy-wing with the pivot replaced by
/// a link, which is why it lives in the same tier. It is also the cheapest
/// rule that reaches across the grid rather than through one cell: the two
/// ends can be anywhere at all.
class WWingRule implements TechniqueRule {
  const WWingRule();

  @override
  Technique get technique => Technique.wWing;

  @override
  TechniqueTier get tier => TechniqueTier.chains;

  @override
  Deduction? find(CandidateGrid grid) {
    final bivalue = [
      for (final idx in grid.unsolvedCells)
        if (grid.candidateCount(idx) == 2) idx,
    ];
    if (bivalue.length < 2) return null;

    for (int i = 0; i < bivalue.length; i++) {
      final a = bivalue[i];
      final mask = grid.candidateMask(a);

      for (int j = i + 1; j < bivalue.length; j++) {
        final b = bivalue[j];
        if (grid.candidateMask(b) != mask) continue;
        // Two cells that see each other and share a pair are a naked pair,
        // which is four tiers cheaper and already found. Calling that a
        // w-wing would explain a simple thing with a complicated name.
        if (Units.peersOf[a].contains(b)) continue;

        final digits = Units.digitsIn(mask);
        for (final link in digits) {
          // The link carries one digit; the other is what gets eliminated.
          final removed = digits.first == link ? digits.last : digits.first;

          final targets = _targets(grid, a, b, removed);
          if (targets.isEmpty) continue;

          final ends = _strongLink(grid, a, b, link);
          if (ends == null) continue;

          // No unit, deliberately. The link sits in one, but the two ends
          // and the eliminations can be anywhere on the grid, so naming that
          // unit at the locate rung would send a player to look at a row
          // holding nothing they can act on. The witnesses carry the proof
          // instead, and locate says what is true: spread across the board.
          return Deduction(
            technique: technique,
            kind: DeductionKind.elimination,
            targets: targets,
            witnesses: [a, b, ends.$1, ends.$2],
          );
        }
      }
    }
    return null;
  }

  /// The two homes of [link] in some unit, one seen by [a] and the other by
  /// [b]. Null when no such unit exists.
  (int, int)? _strongLink(CandidateGrid grid, int a, int b, int link) {
    for (int unitId = 0; unitId < Units.unitCount; unitId++) {
      final homes = [
        for (final idx in Units.unitCells[unitId])
          if (grid.hasCandidate(idx, link)) idx,
      ];
      if (homes.length != 2) continue;

      final p = homes[0];
      final q = homes[1];
      // The link has to be somewhere else. A link through one of the ends
      // says nothing: that end already holds the digit as a candidate.
      if (p == a || p == b || q == a || q == b) continue;

      if (Units.peersOf[a].contains(p) && Units.peersOf[b].contains(q)) {
        return (p, q);
      }
      if (Units.peersOf[a].contains(q) && Units.peersOf[b].contains(p)) {
        return (q, p);
      }
    }
    return null;
  }

  /// Cells that see both ends and still carry the digit one of them must be.
  List<(int, int)> _targets(
      CandidateGrid grid, int a, int b, int removed) {
    return [
      for (final idx in Units.peersOf[a])
        if (idx != b &&
            Units.peersOf[b].contains(idx) &&
            grid.hasCandidate(idx, removed))
          (idx, removed),
    ];
  }
}

/// Follow a digit through the units where it has exactly two homes.
///
/// Those two cells are a conjugate pair: exactly one of them is the digit.
/// Chaining pairs together two-colours a cluster, and one colour is entirely
/// true while the other is entirely false. Two conclusions follow:
///
/// - if one colour appears twice in a unit, that colour is false outright, so
///   the digit goes from every cell wearing it;
/// - any cell outside the cluster that sees both colours cannot be the digit,
///   because one of the two colours is true.
class SimpleColoringRule implements TechniqueRule {
  const SimpleColoringRule();

  @override
  Technique get technique => Technique.simpleColoring;

  @override
  TechniqueTier get tier => TechniqueTier.chains;

  @override
  Deduction? find(CandidateGrid grid) {
    for (int digit = 1; digit <= 9; digit++) {
      final links = _conjugateLinks(grid, digit);
      if (links.isEmpty) continue;

      final colour = <int, int>{};
      for (final start in links.keys) {
        if (colour.containsKey(start)) continue;
        final cluster = _twoColour(links, start, colour);
        if (cluster.length < 4) continue;

        final found = _contradiction(cluster, colour, digit) ??
            _seesBothColours(grid, cluster, colour, digit);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Cells joined when a unit has exactly two homes left for the digit.
  Map<int, Set<int>> _conjugateLinks(CandidateGrid grid, int digit) {
    final links = <int, Set<int>>{};
    for (int unitId = 0; unitId < Units.unitCount; unitId++) {
      final spots = grid.cellsWithCandidate(unitId, digit);
      if (spots.length != 2) continue;
      links.putIfAbsent(spots[0], () => <int>{}).add(spots[1]);
      links.putIfAbsent(spots[1], () => <int>{}).add(spots[0]);
    }
    return links;
  }

  /// Breadth-first alternate colouring from [start]. Writes into [colour] and
  /// returns the cells reached.
  List<int> _twoColour(
    Map<int, Set<int>> links,
    int start,
    Map<int, int> colour,
  ) {
    final cluster = <int>[start];
    colour[start] = 0;
    final queue = <int>[start];
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      for (final next in links[cell]!) {
        if (colour.containsKey(next)) continue;
        colour[next] = 1 - colour[cell]!;
        cluster.add(next);
        queue.add(next);
      }
    }
    return cluster;
  }

  /// One colour twice in a unit — that colour is false everywhere.
  Deduction? _contradiction(
    List<int> cluster,
    Map<int, int> colour,
    int digit,
  ) {
    for (int i = 0; i < cluster.length; i++) {
      for (int j = i + 1; j < cluster.length; j++) {
        final a = cluster[i];
        final b = cluster[j];
        if (colour[a] != colour[b]) continue;
        if (!Units.peersOf[a].contains(b)) continue;

        final doomed = colour[a]!;
        return Deduction(
          technique: Technique.simpleColoring,
          kind: DeductionKind.elimination,
          targets: [
            for (final idx in cluster)
              if (colour[idx] == doomed) (idx, digit),
          ],
          witnesses: [a, b],
        );
      }
    }
    return null;
  }

  /// A cell outside the cluster seeing both colours cannot hold the digit.
  Deduction? _seesBothColours(
    CandidateGrid grid,
    List<int> cluster,
    Map<int, int> colour,
    int digit,
  ) {
    final zero = [for (final idx in cluster) if (colour[idx] == 0) idx];
    final one = [for (final idx in cluster) if (colour[idx] == 1) idx];
    if (zero.isEmpty || one.isEmpty) return null;

    final targets = <(int, int)>[];
    final witnesses = <int>{};
    for (final idx in grid.unsolvedCells) {
      if (cluster.contains(idx)) continue;
      if (!grid.hasCandidate(idx, digit)) continue;
      final peers = Units.peersOf[idx];
      final a = zero.where(peers.contains).firstOrNull;
      final b = one.where(peers.contains).firstOrNull;
      if (a == null || b == null) continue;
      targets.add((idx, digit));
      witnesses..add(a)..add(b);
    }
    if (targets.isEmpty) return null;

    return Deduction(
      technique: Technique.simpleColoring,
      kind: DeductionKind.elimination,
      targets: targets,
      witnesses: witnesses.toList(),
    );
  }
}
