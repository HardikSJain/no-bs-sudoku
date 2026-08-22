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
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onTap, this.label = 'back'});

  /// Defaults to popping the route.
  final VoidCallback? onTap;

  /// What a screen reader calls it. Worth overriding when back means
  /// something more specific, like leaving a puzzle in progress.
  final String label;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Tappable(
      label: label,
      onTap: onTap ??
          () {
            Haptics.select();
            context.pop();
          },
      child: Container(
        width: 36,
        height: 36,
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
    );
  }
}
