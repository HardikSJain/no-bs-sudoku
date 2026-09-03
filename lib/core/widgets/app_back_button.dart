import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../a11y/tappable.dart';
import '../haptics.dart';
import '../theme/app_theme_colors.dart';

/// The one way back.
///
/// Three screens had the boxed 36pt version and two newer ones had a bare
/// chevron at almost twice the size, which reads as two different apps. The
/// pattern is a single widget now so a new screen gets it right by default
/// rather than by copying whichever neighbour it happened to look at.
///
/// The card is 36pt because that is what the design wants; the *target* is
/// 44, which is the smallest thing a thumb reliably hits and what the rest
/// of this app already uses. Those were the same number until people started
/// reporting that the top-left of the screen sometimes ignored them — a
/// press that lands 4pt outside a 36pt box is an ordinary press, and it was
/// being dropped. The gap is padding inside the tap target, so the button
/// still *looks* 36.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onTap, this.label = 'back'});

  /// Defaults to popping the route.
  final VoidCallback? onTap;

  /// What a screen reader calls it. Worth overriding when back means
  /// something more specific, like leaving a puzzle in progress.
  final String label;

  /// What you see.
  static const double _card = 36;

  /// What you can hit.
  static const double _target = 44;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Tappable(
      label: label,
      // The haptic used to live inside the default `onTap`, so it fired on
      // the screens that took the default and stayed silent on the ones that
      // passed their own — which is every screen where going back does
      // something first, including leaving a puzzle. Same button, same feel,
      // wherever it is.
      onTap: () {
        Haptics.select();
        (onTap ?? () => context.pop())();
      },
      child: SizedBox(
        width: _target,
        height: _target,
        child: Center(
          child: Container(
            width: _card,
            height: _card,
            decoration: BoxDecoration(
              color: col.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.ink, width: 2),
              boxShadow: col.cardShadow,
            ),
            child: Center(
              child: Icon(Icons.arrow_back_ios_new, color: col.ink, size: 14),
            ),
          ),
        ),
      ),
    );
  }
}
