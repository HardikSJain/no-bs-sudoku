import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/home/widgets/daily_puzzle_card.dart';

/// The card at the top of the home screen, in its three states.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(
      theme: appTheme(),
      home: Scaffold(body: Padding(padding: const EdgeInsets.all(16), child: child)),
    ));
    await tester.pumpAndSettle();
  }

  /// A board with [filled] of its 81 cells given, and [placed] more entered.
  SavedGame savedGame({required int givens, required int placed}) {
    final puzzle = List.filled(81, 0);
    final board = List.filled(81, 0);
    for (var i = 0; i < givens; i++) {
      puzzle[i] = 1;
      board[i] = 1;
    }
    for (var i = givens; i < givens + placed; i++) {
      board[i] = 2;
    }
    return SavedGame(
      id: 1,
      puzzleId: '2026-08-23',
      difficulty: 'expert',
      isDaily: true,
      givenCells: puzzle.join(','),
      solutionCells: board.join(','),
      boardCells: board.join(','),
      notes: '',
      elapsedSeconds: 300,
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
  }

  /// The 8dp track. There is exactly one in the card when it is drawn.
  final progressTrack = find.byWidgetPredicate(
      (w) => w is Container && w.constraints?.maxHeight == 8);

  testWidgets('an unplayed daily draws no progress track', (tester) async {
    await pump(
      tester,
      const DailyPuzzleCard(
        completed: false,
        difficulty: Difficulty.expert,
        puzzleNum: 1,
      ),
    );

    expect(find.text('not played yet'), findsOneWidget);
    // A zero-width fill inside a translucent track renders as a hairline at
    // the card's left edge and says nothing the sentence below does not.
    expect(progressTrack, findsNothing);
  });

  testWidgets('a daily in progress draws one, with the time', (tester) async {
    await pump(
      tester,
      DailyPuzzleCard(
        completed: false,
        difficulty: Difficulty.expert,
        puzzleNum: 1,
        inProgressGame: savedGame(givens: 30, placed: 17),
      ),
    );

    expect(progressTrack, findsOneWidget);
    expect(find.text('05:00'), findsOneWidget);
    expect(find.textContaining('% there'), findsOneWidget);
    expect(find.text('RESUME'), findsOneWidget);
  });

  testWidgets('a finished daily draws a full one', (tester) async {
    await pump(
      tester,
      const DailyPuzzleCard(
        completed: true,
        timeSeconds: 3725,
        difficulty: Difficulty.expert,
        puzzleNum: 1,
      ),
    );

    expect(progressTrack, findsOneWidget);
    // Past an hour the clock grows a field rather than counting to 299
    // minutes.
    expect(find.text('1:02:05'), findsOneWidget);
    expect(find.text('done'), findsOneWidget);
  });
}
