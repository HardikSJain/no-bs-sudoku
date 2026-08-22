import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/deduction/solve_path_analysis.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/complete/widgets/solve_path_card.dart';
import 'package:no_bs_sudoku/features/game/technique_copy.dart';

void main() {
  const engine = DeductionEngine();
  final generator = SudokuGenerator();

  Future<void> pumpCard(WidgetTester tester, SolvePathAnalysis analysis) {
    return tester.pumpWidget(MaterialApp(
      theme: appTheme(theme: 'paper'),
      home: Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SolvePathCard(analysis: analysis),
          ),
        ),
      ),
    ));
  }

  SolvePathAnalysis analyse(Difficulty d, {int seed = 1}) {
    final g = generator.generate(difficulty: d, seed: seed);
    return SolvePathAnalysis.of(
        engine.solve(CandidateGrid.fromBoard(g.puzzle)));
  }

  group('it lays out without overflowing', () {
    // The tier band puts one Expanded per step in a single Row. A fifty-step
    // solve is the normal case and a long one has many more; if that ever
    // overflows it does so silently in release and loudly here.
    for (final difficulty in Difficulty.classic) {
      testWidgets('for a ${difficulty.name} solve', (tester) async {
        await pumpCard(tester, analyse(difficulty));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('on a narrow phone', (tester) async {
      tester.view.physicalSize = const Size(320 * 3, 640 * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      await pumpCard(tester, analyse(Difficulty.expert));
      expect(tester.takeException(), isNull);
    });
  });

  group('it says something useful', () {
    testWidgets('it names the hardest technique and the step count',
        (tester) async {
      final analysis = analyse(Difficulty.hard, seed: 3);
      await pumpCard(tester, analysis);

      expect(find.text('HOW IT WAS BUILT'), findsOneWidget);
      expect(find.textContaining('${analysis.totalSteps} steps'), findsOneWidget);
      // Every technique the solve used is listed with its count.
      for (final use in analysis.uses) {
        expect(find.text(use.technique.plural), findsOneWidget,
            reason: '${use.technique.name} missing from the breakdown');
      }
    });

    testWidgets('an empty analysis renders nothing at all', (tester) async {
      await pumpCard(
        tester,
        const SolvePathAnalysis(
          totalSteps: 0,
          uses: [],
          tierByStep: [],
          hardest: null,
          complete: false,
        ),
      );
      expect(find.text('HOW IT WAS BUILT'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
