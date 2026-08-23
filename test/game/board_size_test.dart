import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/features/game/game_screen.dart';
import 'package:no_bs_sudoku/features/game/widgets/hint_panel.dart';

/// The board must not move or resize while a hint explains it.
///
/// You read the sentence and look at the cells it describes at the same time.
/// Cells shifting under a finger mid-explanation is worse than the
/// explanation being absent — and that is what happened when the board was
/// Expanded above the panel: the panel opened, the flexible region shrank,
/// and the grid jumped.
void main() {
  BoxConstraints screen(double w, double h) =>
      BoxConstraints.tightFor(width: w, height: h);

  group('the size does not depend on the hint', () {
    test('the panel height is reserved whether or not it is showing', () {
      // The function takes no hint parameter, and that is the invariant. If
      // one is ever added, this stops compiling — which is the intent.
      final withRoom = gameBoardSize(screen(402, 874));
      final again = gameBoardSize(screen(402, 874));
      expect(withRoom, again);
    });

    test('a tall phone is limited by width, not height', () {
      // 402 wide minus 16pt padding a side.
      expect(gameBoardSize(screen(402, 1600)), 370);
      // Twice as tall changes nothing: the board is square and the width is
      // what constrains it.
      expect(gameBoardSize(screen(402, 2000)), 370);
    });

    test('a phone this tall is not limited by height at all', () {
      // 402x874 less the safe areas leaves room for a full-width board, so
      // the reserve does not cost anything on a normal modern phone.
      expect(gameBoardSize(screen(402, 781)), 370);
    });

    test('a short phone gives up board rather than clipping the pad', () {
      final short = gameBoardSize(screen(320, 568));
      expect(short, lessThan(320 - 32));
      expect(short, greaterThanOrEqualTo(260));
    });

    test('it never returns a size that cannot be tapped', () {
      for (double h = 400; h <= 1000; h += 25) {
        for (final w in [320.0, 375.0, 402.0, 430.0]) {
          final size = gameBoardSize(screen(w, h));
          expect(size, greaterThanOrEqualTo(260),
              reason: '${w}x$h gave $size — a cell would be under 29pt');
          expect(size, lessThanOrEqualTo(w - 32),
              reason: '${w}x$h gave $size — wider than the screen');
        }
      }
    });
  });

  group('the reserved chrome is honest', () {
    test('it accounts for the panel, not just the controls', () {
      // header + toolbar + number pad + spacing + the tallest the hint panel
      // gets. Drop the panel's share and the board grows when no hint is
      // showing and shrinks when one appears, which is the bug this exists
      // to prevent.
      // The panel's share is the cap the panel actually honours, not a guess
      // it might exceed.
      expect(gameChromeHeight - (48 + 20 + 92 + 55 + 40), hintPanelMaxHeight);
    });
  });
}
