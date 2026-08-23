import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/a11y/tappable.dart';
import '../../core/haptics.dart';
import '../../core/logger.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/update/forced_update.dart';

/// Shown instead of the app when the installed build has been retired.
///
/// No dismiss, and that is the point — a wall you can walk around is a
/// notice, and this exists for the case where carrying on would write data a
/// later build cannot read. It is also why the bar for putting it up is so
/// high on the other side of the console.
///
/// It says what it costs and what it does not: nothing local is lost. The
/// most common fear on seeing a screen like this is that the update will
/// take your progress with it.
class UpdateRequiredScreen extends StatelessWidget {
  const UpdateRequiredScreen({super.key, this.storeUrl = _play});

  /// Play only for now — iOS has no Firebase configured, so this screen
  /// cannot be triggered there at all.
  static const String _play =
      'https://play.google.com/store/apps/details?id=com.nobssudoku.no_bs_sudoku';

  final String storeUrl;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;

    return Scaffold(
      backgroundColor: col.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'update needed.',
                  style: AppTypography.wordmark.copyWith(
                    color: col.ink,
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                ValueListenableBuilder<String>(
                  valueListenable: ForcedUpdate.instance.message,
                  builder: (_, message, _) => Text(
                    message,
                    style: AppTypography.body.copyWith(
                      color: col.ink3,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Tappable(
                  label: 'update',
                  hint: 'opens the play store',
                  onTap: () => _openStore(context),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: col.accent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: col.ink, width: 2),
                      boxShadow: col.cardShadow,
                    ),
                    child: Center(
                      child: Text(
                        'UPDATE',
                        style: AppTypography.button.copyWith(
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context) async {
    Haptics.select();
    try {
      await launchUrl(
        Uri.parse(storeUrl),
        mode: LaunchMode.externalApplication,
      );
    } catch (e) {
      Log.warn('could not open the store: $e', tag: 'update');
    }
  }
}

/// Puts [UpdateRequiredScreen] over the app when the build has been retired.
///
/// Wrapped around the router's output rather than pushed as a route, because
/// a route can be popped and this cannot, and because the answer can arrive
/// at any moment — including while somebody is mid-puzzle.
class UpdateGate extends StatelessWidget {
  const UpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: ForcedUpdate.instance.isRequired,
      builder: (_, required, _) =>
          required ? const UpdateRequiredScreen() : child,
    );
  }
}
