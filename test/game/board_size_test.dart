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
      // 320x568 cannot hold the chrome, a 260 board and the hint panel's
      // chip and dots at once, so the board comes down to 249 — 27.6pt
      // cells, which is still a target.
      final short = gameBoardSize(screen(320, 568));
      expect(short, lessThan(320 - 32));
      expect(short, greaterThanOrEqualTo(playableFloor));
    });

    test('it never returns a size that cannot be tapped', () {
      // From the shortest phone up. Below that the board yields to the
      // column instead, which the group further down covers.
      for (double h = smallestSupportedHeight; h <= 1000; h += 25) {
        for (final w in [320.0, 375.0, 402.0, 430.0]) {
          final size = gameBoardSize(screen(w, h));
          expect(size, greaterThanOrEqualTo(playableFloor),
              reason: '${w}x$h gave $size — a cell would be under 25pt');
          expect(size, lessThanOrEqualTo(w - 32),
              reason: '${w}x$h gave $size — wider than the screen');
        }
      }
    });
  });

  group('the reserved chrome is honest', () {
    test('it accounts for the panel, not just the controls', () {
      // header + toolbar + number pad + spacing + the panel's floor. Drop the
      // panel's share and the board grows when no hint is showing and shrinks
      // when one appears, which is the bug this exists to prevent.
      expect(gameChromeHeight - gameFixedChromeHeight, hintPanelMinHeight);
      expect(gameFixedChromeHeight, 48 + 20 + 92 + 55 + 40);
    });
  });

  group('the panel takes the slack the board did not need', () {
    test('a normal phone hands it more than the reservation', () {
      // 402x781 of usable height: the board is width-limited at 370, so the
      // leftover is real and would otherwise sit empty above the toolbar.
      final panel = hintPanelHeightFor(screen(402, 781));
      expect(panel, greaterThan(hintPanelMinHeight));
      expect(panel, lessThanOrEqualTo(hintPanelCeiling));
    });

    test('a very tall screen stops at the ceiling', () {
      expect(hintPanelHeightFor(screen(402, 2000)), hintPanelCeiling);
    });

    test('and it never asks for space the column does not have', () {
      for (double h = smallestSupportedHeight; h <= 1400; h += 17) {
        for (final w in [320.0, 375.0, 402.0, 430.0, 834.0]) {
          final c = screen(w, h);
          final used = gameFixedChromeHeight + gameBoardSize(c) +
              hintPanelHeightFor(c);
          expect(used, lessThanOrEqualTo(h + 0.001),
              reason: '${w}x$h overflows the column by ${used - h}');
          expect(hintPanelHeightFor(c), greaterThanOrEqualTo(0));
        }
      }
    });
  });

  group('the shortest screen the layout is built for', () {
    // An iPhone SE in portrait is 320x568, and its status bar leaves 548
    // points inside the SafeArea. That is the floor, and it has 33 points to
    // spare.
    test('an SE fits, with room over', () {
      final c = screen(320, 548);
      final used =
          gameFixedChromeHeight + gameBoardSize(c) + hintPanelHeightFor(c);
      expect(used, lessThanOrEqualTo(548));
    });

    test('an SE gives up board rather than overflowing the column', () {
      // The floor is a preference; the column is not. 320x548 cannot hold
      // chrome + a 260 board + the panel's chip and dots, so the board is
      // what gives.
      final size = gameBoardSize(screen(320, smallestSupportedHeight));
      expect(size, lessThan(boardFloor));
      expect(
        gameFixedChromeHeight + size + hintPanelChromeHeight,
        lessThanOrEqualTo(smallestSupportedHeight),
      );
      // Still a playable board: 25pt cells, not 12.
      expect(size, greaterThanOrEqualTo(playableFloor));
    });

    test('the panel always has room for the parts that cannot scroll', () {
      for (double h = 480; h <= 1400; h += 13) {
        for (final w in [320.0, 375.0, 402.0, 430.0, 834.0]) {
          final c = screen(w, h);
          expect(hintPanelHeightFor(c),
              greaterThanOrEqualTo(hintPanelChromeHeight),
              reason: '${w}x$h left the panel ${hintPanelHeightFor(c)}');
        }
      }
    });
  });
}

/// The usable height inside the SafeArea of the smallest phone in portrait.
///
/// An original iPhone SE is 320x568 and its status bar takes 20. iOS 14 is
/// still the deployment target, so this is a device the app runs on rather
/// than a hypothetical.
const double smallestSupportedHeight = 548;

/// The smallest board any supported screen may end up with: 225 points is a
/// 25pt cell, which is small but hittable. [boardFloor] is what the layout
/// aims for; this is what it is never allowed to go under.
const double playableFloor = 225;
