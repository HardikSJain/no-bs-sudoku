import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/daily_key.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/core/widgets/discard_confirmation.dart';

/// The sheet that stands between a mistap and a lost puzzle.
void main() {
  SavedGame saved({
    required String puzzleId,
    required bool isDaily,
    String difficulty = 'hard',
  }) =>
      SavedGame(
        id: 1,
        puzzleId: puzzleId,
        difficulty: difficulty,
        isDaily: isDaily,
        givenCells: '',
        solutionCells: '',
        boardCells: '',
        notes: '',
        elapsedSeconds: 100,
        hintsRemaining: 0,
        hintsUsed: 0,
        hintDepthTotal: 0,
        mistakeCount: 0,
        isNotesMode: false,
        savedAt: DateTime.now(),
        history: '',
        placementDeltas: '',
        mistakeCells: '',
        undoCount: 0,
        usedNotes: false,
        longestPauseSeconds: 0,
        techniques: '',
      );

  Future<void> open(WidgetTester tester, SavedGame game) async {
    await tester.pumpWidget(MaterialApp(
      theme: appTheme(),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => confirmDiscard(context, game),
              child: const Text('go'),
            ),
          ),
        ),
      ),
    ));
    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
  }

  testWidgets('an expert puzzle gets the right article', (tester) async {
    // "a expert puzzle" shipped for a while.
    await open(tester, saved(puzzleId: 'q1', isDaily: false, difficulty: 'expert'));
    expect(find.text('you have an expert puzzle in progress.'), findsOneWidget);
  });

  testWidgets('and a hard one keeps its own', (tester) async {
    await open(tester, saved(puzzleId: 'q1', isDaily: false));
    expect(find.text('you have a hard puzzle in progress.'), findsOneWidget);
  });

  testWidgets("today's daily is named as the daily, not by its tier",
      (tester) async {
    // The tier is the least surprising thing about it, and "an expert puzzle"
    // sounds like the one you started from the grid below.
    await open(tester,
        saved(puzzleId: dailyPuzzleId(), isDaily: true, difficulty: 'expert'));
    expect(find.text("you have today's daily in progress."), findsOneWidget);
  });

  testWidgets('and one from the archive is named by its date', (tester) async {
    final past = DateTime.utc(2026, 8, 12);
    await open(tester,
        saved(puzzleId: dailyPuzzleId(past), isDaily: true));
    expect(find.text('you have the daily from 12 august in progress.'),
        findsOneWidget);
  });
}
