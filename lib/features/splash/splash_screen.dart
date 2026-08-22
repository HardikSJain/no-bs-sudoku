import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/repositories/repositories.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    final prefs = await context.read<PreferencesRepository>().getPreferences();
    if (!mounted) return;
    context.go(prefs.hasSeenOnboarding ? '/home' : '/onboarding');
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Scaffold(
      backgroundColor: col.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(painter: _DotTexturePainter(col.ink4)),
          ),
          // NO ADS — cherry, top-left
          Positioned(
            top: 130,
            left: 32,
            child: _Sticker(
              text: 'NO ADS',
              color: col.error,
              col: col,
              angle: -0.10,
              delay: 600,
            ),
          ),
          // OFFLINE — mint, top-right
          Positioned(
            top: 220,
            right: 20,
            child: _Sticker(
              text: 'OFFLINE',
              color: col.mint,
              col: col,
              angle: 0.07,
              delay: 750,
            ),
          ),
          // NO PAYWALL — lilac, bottom-left
          Positioned(
            bottom: 240,
            left: 44,
            child: _Sticker(
              text: 'NO PAYWALL',
              color: col.lilac,
              col: col,
              angle: -0.06,
              delay: 900,
            ),
          ),
          // center: grid + wordmark
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniGrid(col: col)
                    .animate()
                    .fadeIn(duration: 350.ms)
                    .scale(
                      begin: const Offset(0.88, 0.88),
                      end: const Offset(1, 1),
                      duration: 350.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 28),
                Text(
                  'no  bs  sudoku',
                  style: AppTypography.wordmark.copyWith(
                    color: col.ink,
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0,
                  ),
                ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
                const SizedBox(height: 8),
                Text(
                  'just sudoku.',
                  style: AppTypography.labelSmall.copyWith(
                    color: col.ink3,
                    fontSize: 13,
                    letterSpacing: 0.2,
                  ),
                ).animate().fadeIn(delay: 400.ms, duration: 350.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// 3×3 grid with individual cell cards
class _MiniGrid extends StatelessWidget {
  final AppThemeColors col;
  const _MiniGrid({required this.col});

  // row=0..2, col=0..2 → label and bg color (null = empty)
  (String?, Color?) _cell(int r, int c) {
    if (r == 1 && c == 1) return ('9', null); // cobalt (accent)
    if (r == 2 && c == 1) return ('4', null); // sun
    return (null, null);
  }

  @override
  Widget build(BuildContext context) {
    const cellSize = 48.0;
    const gap = 6.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (r) {
        return Padding(
          padding: EdgeInsets.only(bottom: r < 2 ? gap : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (c) {
              final (label, _) = _cell(r, c);
              final isAccent = r == 1 && c == 1;
              final isSun = r == 2 && c == 1;
              final bgColor = isAccent
                  ? col.accent
                  : isSun
                  ? col.sun
                  : col.paper;

              return Padding(
                padding: EdgeInsets.only(right: c < 2 ? gap : 0),
                child: Container(
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: col.ink, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: col.ink,
                        offset: const Offset(2, 2),
                        blurRadius: 0,
                      ),
                    ],
                  ),
                  child: label != null
                      ? Center(
                          child: Text(
                            label,
                            style: AppTypography.number.copyWith(
                              color: isAccent ? Colors.white : col.ink,
                              fontSize: 22,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : null,
                ),
              );
            }),
          ),
        );
      }),
    );
  }
}

class _Sticker extends StatelessWidget {
  final String text;
  final Color color;
  final AppThemeColors col;
  final double angle;
  final int delay;

  const _Sticker({
    required this.text,
    required this.color,
    required this.col,
    required this.angle,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
          angle: angle,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: col.ink, width: 2),
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: col.ink,
                  offset: const Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Text(
              text,
              style: AppTypography.labelSmall.copyWith(
                color: col.ink,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: delay),
          duration: 300.ms,
        )
        .slideY(
          begin: 0.25,
          end: 0,
          delay: Duration(milliseconds: delay),
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

class _DotTexturePainter extends CustomPainter {
  final Color color;
  _DotTexturePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color.withValues(alpha: 0.3);
    const spacing = 14.0;
    const radius = 0.8;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotTexturePainter old) => old.color != color;
}
