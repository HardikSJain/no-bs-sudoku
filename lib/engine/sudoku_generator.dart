import 'dart:math';

import 'deduction/candidate_grid.dart';
import 'deduction/deduction.dart';
import 'deduction/deduction_engine.dart';
import 'sudoku_board.dart';
import 'sudoku_solver.dart';

/// Decides whether a partially dug board is still an acceptable puzzle.
typedef _RemovalGate = bool Function(SudokuBoard puzzle);

class SudokuGenerator {
  final SudokuSolver _solver = SudokuSolver();
  final DeductionEngine _engine = const DeductionEngine();

  /// The first date whose daily is dug with the technique ladder.
  ///
  /// Grading generation against the ladder changes which removals are kept,
  /// so the same seed yields a different puzzle than it did before. For an
  /// ordinary game nobody can tell. For the daily it would break the one
  /// promise the daily makes — that everyone, everywhere, is solving the same
  /// grid today — because a player who has not updated would be on a
  /// different puzzle from one who has.
  ///
  /// So the daily keeps the old dig until this date, by which point the
  /// update has had time to reach people. It must stay at or beyond
  /// **release + 3 days**, never release day itself: starting a daily deletes
  /// the save and regenerates, so on the cutover day the two populations
  /// would diverge in exactly the way this exists to prevent.
  ///
  /// **Move this forward if the release slips past 2026-09-12.** Once shipped
  /// it must never move backward, and once it is safely in the past the old
  /// dig below can be deleted outright.
  static final DateTime dailyAlgorithmV2Cutover = DateTime.utc(2026, 9, 15);

  /// Generates a puzzle with the given difficulty.
  /// Uses [seed] for deterministic generation (e.g., daily puzzles).
  ({SudokuBoard puzzle, SudokuBoard solution}) generate({
    Difficulty difficulty = Difficulty.medium,
    int? seed,
    bool useLadderGate = true,
  }) {
    if (difficulty.isDeep) {
      final deep = generateDeep(difficulty, seed: seed);
      if (deep != null) return deep;
      // Falling back to expert would hand someone who asked for a fish a
      // puzzle without one. The caller has to decide what to say instead.
      throw StateError(
        'could not build a ${difficulty.name} puzzle within the attempt budget',
      );
    }
    final random = seed != null ? Random(seed) : Random();
    final (_, maxClues) = difficulty.clueRange;

    SudokuBoard? bestPuzzle;
    SudokuBoard? bestSolution;
    int bestClues = 81;

    // Retry with fresh boards if we can't reach the target clue count.
    // Each attempt uses the same Random sequence, so results are deterministic.
    for (int attempt = 0; attempt < 10; attempt++) {
      final solution = _generateSolvedBoard(random);
      final puzzle = _digHoles(solution, difficulty, random, useLadderGate);
      if (puzzle.clueCount <= maxClues) {
        return (puzzle: puzzle, solution: solution);
      }
      if (puzzle.clueCount < bestClues) {
        bestPuzzle = puzzle;
        bestSolution = solution;
        bestClues = puzzle.clueCount;
      }
    }

    // Return the attempt that got closest to the target range
    return (puzzle: bestPuzzle!, solution: bestSolution!);
  }

  /// A puzzle whose crux is [technique].
  ///
  /// Rejection sampling with a *floor*, which is the opposite of what the
  /// four legacy labels get. A ceiling promises "never harder than"; this
  /// promises "you will have to do this". That is only safe on new content:
  /// imposing a floor on `medium` would change what medium means to someone
  /// who has played it for months, whereas nobody has a history with a
  /// technique drill.
  ///
  /// The crux test is two-sided. The technique must appear in the solve, and
  /// the puzzle must *not* be solvable with that rule removed from the
  /// ladder. Without the second half a "swordfish puzzle" could be one where
  /// a swordfish happened to be available and three singles would have done
  /// just as well.
  ///
  /// Returns null when [attempts] runs out. The caller says so plainly rather
  /// than shipping a drill that lacks its own lesson — yield varies sharply
  /// by technique and a swordfish crux is genuinely rare.
  ({SudokuBoard puzzle, SudokuBoard solution})? generateTargeting(
    Technique technique, {
    int? seed,
    int attempts = 60,
  }) {
    final random = seed != null ? Random(seed) : Random();
    final reduced = _engine.without(technique);

    for (int attempt = 0; attempt < attempts; attempt++) {
      final solution = _generateSolvedBoard(random);
      // Dig as deep as the guard rails allow, not to the tier's usual clue
      // range. A puzzle dug to medium's 30 clues under a pairs ceiling is
      // almost always solvable by singles alone, so the crux test rejects it
      // and the yield is zero — measured. Depth is what forces a technique to
      // be needed; the ceiling is what keeps it from needing a harder one.
      final puzzle = _dig(
        solution,
        Difficulty.expert,
        random,
        _tierGate(solution, technique.tier),
      );

      final path = _engine.solve(
        CandidateGrid.fromBoard(puzzle),
        maxTier: technique.tier,
      );
      if (!path.complete) continue;
      if (!path.steps.any((s) => s.technique == technique)) continue;

      // The crux test, asked within the technique's own tier. Against the
      // whole ladder it is the wrong question: a puzzle that genuinely needs
      // a naked pair can usually be finished with a pointing pair instead, so
      // every mid-tier drill was rejected — measured at zero yield. Reaching
      // for a harder rule to dodge the lesson is not what a drill is for.
      if (reduced
          .solve(CandidateGrid.fromBoard(puzzle), maxTier: technique.tier)
          .complete) {
        continue;
      }

      if (!_solver.hasUniqueSolution(puzzle)) continue;
      return (puzzle: puzzle, solution: solution);
    }
    return null;
  }

  _RemovalGate _tierGate(SudokuBoard solution, TechniqueTier maxTier) {
    return (puzzle) {
      final path =
          _engine.solve(CandidateGrid.fromBoard(puzzle), maxTier: maxTier);
      return path.complete && path.board == solution;
    };
  }

  /// A puzzle for one of the deep tiers.
  ///
  /// The floor here is the *tier*, not a named technique: "needs a fish"
  /// means intersections-level reasoning cannot finish it, which is exactly
  /// what the label promises a player. Insisting instead that one specific
  /// fish be individually indispensable asks a much rarer question — an
  /// x-wing crux clears about a quarter of 400 attempts, and requiring a
  /// named one made the tier fail more often than it succeeded.
  ///
  /// Returns null when the budget runs out. There is no falling back to
  /// expert: handing someone who asked for a fish a puzzle without one gives
  /// up the only thing this tier is for.
  ({SudokuBoard puzzle, SudokuBoard solution})? generateDeep(
    Difficulty difficulty, {
    int? seed,
    /// Measured: at 400 the fish tier clears 7 of 8 seeds; at 1200 it clears
    /// 8 of 8 with a 2.1s median and a 13s tail. Chains is reliable either
    /// way at under 200ms. The tail is why this belongs on an isolate behind
    /// a real loading state, not on the main thread.
    int attempts = 1200,
  }) {
    if (!difficulty.isDeep) return null;
    final tier = difficulty.maxTier;
    final below = TechniqueTier.values[tier.index - 1];
    final random = seed != null ? Random(seed) : Random();

    // One solved board feeds several digs. The dig order is reshuffled from
    // the same Random each time, so the attempts stay independent, and
    // building a fresh solved grid — the most expensive part of an attempt —
    // stops dominating a search that mostly fails.
    const digsPerSolution = 6;
    SudokuBoard? solution;

    for (int attempt = 0; attempt < attempts; attempt++) {
      if (attempt % digsPerSolution == 0) {
        solution = _generateSolvedBoard(random);
      }
      final puzzle = _dig(
        solution!,
        Difficulty.expert,
        random,
        _tierGate(solution, tier),
      );

      final path =
          _engine.solve(CandidateGrid.fromBoard(puzzle), maxTier: tier);
      if (!path.complete || path.board != solution) continue;

      // The floor: the tier below must not be enough.
      if (_engine
          .solve(CandidateGrid.fromBoard(puzzle), maxTier: below)
          .complete) {
        continue;
      }

      if (!_solver.hasUniqueSolution(puzzle)) continue;
      return (puzzle: puzzle, solution: solution);
    }
    return null;
  }

  /// Difficulty rotation by day of week.
  /// Mon/Tue: easy, Wed/Thu: medium, Fri/Sat: hard, Sun: expert.
  static Difficulty dailyDifficulty(DateTime date) {
    return switch (date.weekday) {
      DateTime.monday || DateTime.tuesday => Difficulty.easy,
      DateTime.wednesday || DateTime.thursday => Difficulty.medium,
      DateTime.friday || DateTime.saturday => Difficulty.hard,
      _ => Difficulty.expert, // Sunday
    };
  }

  /// Generates a daily puzzle for the given date.
  /// Same date always produces the same puzzle.
  /// Difficulty rotates by day of week.
  ({SudokuBoard puzzle, SudokuBoard solution, Difficulty difficulty}) generateDaily({
    required DateTime date,
  }) {
    final difficulty = dailyDifficulty(date);
    final seed = date.year * 10000 + date.month * 100 + date.day;
    final result = generate(
      difficulty: difficulty,
      seed: seed,
      useLadderGate: !date.toUtc().isBefore(dailyAlgorithmV2Cutover),
    );
    return (puzzle: result.puzzle, solution: result.solution, difficulty: difficulty);
  }

  /// Generates a fully solved board using backtracking with random ordering.
  SudokuBoard _generateSolvedBoard(Random random) {
    final board = SudokuBoard.empty();

    bool fill(int index) {
      if (index == 81) return true;

      final r = index ~/ 9;
      final c = index % 9;

      final candidates = board.candidates(r, c).toList()..shuffle(random);

      for (final val in candidates) {
        board.set(r, c, val);
        if (fill(index + 1)) return true;
        board.set(r, c, 0);
      }

      return false;
    }

    fill(0);
    return board;
  }

  /// Removes clues from a solved board to create a puzzle.
  ///
  /// Uses 180-degree rotational symmetry in pass 1, then single-cell in pass 2.
  ///
  /// Every removal is checked against the technique ladder rather than
  /// against solution counting: keep the removal only if the puzzle can still
  /// be reasoned to the end within the difficulty's ceiling. That is both
  /// ~140x cheaper than `hasUniqueSolution` on expert and a stronger property
  /// — it is what guarantees no puzzle we ship needs a guess.
  ///
  /// It is not, however, a substitute for the uniqueness oracle. The ladder's
  /// proof of uniqueness holds only if all twelve rules are sound, and the
  /// failure it cannot see is the dangerous one: a rule that over-eliminates,
  /// pruning the branch holding a second solution while leaving the intended
  /// one reachable. The gate would pass and a multi-solution puzzle would
  /// ship — where a player filling in the *other* valid answer watches
  /// correct digits redden and hits the mistake limit on a puzzle they solved.
  /// So the oracle still runs, once, on the finished board.
  SudokuBoard _digHoles(
    SudokuBoard solution,
    Difficulty difficulty,
    Random random,
    bool useLadderGate,
  ) {
    if (!useLadderGate) {
      return _dig(solution, difficulty, random, _solver.hasUniqueSolution);
    }
    final dug = _dig(solution, difficulty, random, _ladderGate(solution, difficulty));
    if (_solver.hasUniqueSolution(dug)) return dug;

    // Unreachable unless a rule is unsound. Falling back to solution counting
    // costs one slow dig in a path that should never run, and cannot ship a
    // board with two answers.
    return _dig(solution, difficulty, random, _solver.hasUniqueSolution);
  }

  /// Accepts a removal when the ladder still solves the puzzle outright,
  /// within [difficulty]'s ceiling, and lands on the known solution.
  _RemovalGate _ladderGate(SudokuBoard solution, Difficulty difficulty) =>
      _tierGate(solution, difficulty.maxTier);

  SudokuBoard _dig(
    SudokuBoard solution,
    Difficulty difficulty,
    Random random,
    _RemovalGate gate,
  ) {
    final puzzle = solution.copy();
    final (minClues, _) = difficulty.clueRange;
    final targetClues = minClues;

    // Build list of symmetric cell pairs to try removing
    final pairs = <List<(int, int)>>[];
    final visited = <int>{};

    // Create shuffled order for cell removal
    final indices = List.generate(81, (i) => i)..shuffle(random);

    for (final idx in indices) {
      if (visited.contains(idx)) continue;

      final r = idx ~/ 9;
      final c = idx % 9;
      final symR = 8 - r;
      final symC = 8 - c;
      final symIdx = symR * 9 + symC;

      visited.add(idx);
      visited.add(symIdx);

      if (idx == symIdx) {
        pairs.add([(r, c)]);
      } else {
        pairs.add([(r, c), (symR, symC)]);
      }
    }

    // Pass 1: symmetric pair removal
    for (final pair in pairs) {
      if (puzzle.clueCount <= targetClues) break;

      // Skip pairs where cells are already empty
      final filledCells =
          pair.where((p) => puzzle.get(p.$1, p.$2) != 0).toList();
      if (filledCells.isEmpty) continue;

      final removingCount = filledCells.length;

      // Don't go below minimum clues
      if (puzzle.clueCount - removingCount < minClues) continue;

      // Save values
      final saved =
          filledCells.map((p) => (p, puzzle.get(p.$1, p.$2))).toList();

      // Remove cells
      for (final (r, c) in filledCells) {
        puzzle.set(r, c, 0);
      }

      // Still an acceptable puzzle?
      if (!gate(puzzle)) {
        // Restore
        for (final (pos, val) in saved) {
          puzzle.set(pos.$1, pos.$2, val);
        }
      }
    }

    // Pass 2: symmetric pair removal with individual uniqueness fallback
    if (puzzle.clueCount > targetClues) {
      final pass2Indices = List.generate(81, (i) => i)..shuffle(random);
      final visited2 = <int>{};

      for (final idx in pass2Indices) {
        if (puzzle.clueCount <= targetClues) break;
        if (visited2.contains(idx)) continue;

        final r = idx ~/ 9;
        final c = idx % 9;
        final symR = 8 - r;
        final symC = 8 - c;
        final symIdx = symR * 9 + symC;

        visited2.add(idx);
        visited2.add(symIdx);

        // Collect filled cells in the symmetric pair
        final pair = <(int, int)>[];
        if (puzzle.get(r, c) != 0) pair.add((r, c));
        if (idx != symIdx && puzzle.get(symR, symC) != 0) pair.add((symR, symC));
        if (pair.isEmpty) continue;
        if (puzzle.clueCount - pair.length < minClues) continue;

        final saved = pair.map((p) => (p, puzzle.get(p.$1, p.$2))).toList();
        for (final (pr, pc) in pair) {
          puzzle.set(pr, pc, 0);
        }
        if (!gate(puzzle)) {
          for (final (pos, val) in saved) {
            puzzle.set(pos.$1, pos.$2, val);
          }
        }
      }
    }

    return puzzle;
  }
}
