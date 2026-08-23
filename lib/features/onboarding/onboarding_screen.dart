import 'package:flutter/material.dart';

import '../../core/a11y/tappable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/repositories/repositories.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _pages = [_Page1(), _Page2(), _Page3()];

  void _next() {
    HapticFeedback.lightImpact();
    if (_page < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    await context.read<PreferencesRepository>().markOnboardingSeen();
    if (mounted) context.go('/home');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Scaffold(
      backgroundColor: col.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _page = i),
                children: _pages,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_pages.length, (i) {
                      final active = i == _page;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: active ? 20 : 7,
                        height: 7,
                        decoration: BoxDecoration(
                          color: active ? col.ink : col.ink4,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 20),
                  Tappable(
                    label: _page < _pages.length - 1 ? 'next' : "let's go",
                    hint: _page < _pages.length - 1
                        ? 'page ${_page + 1} of ${_pages.length}'
                        : 'start playing',
                    onTap: _next,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: col.accent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: col.ink, width: 2),
                        boxShadow: col.cardShadow,
                      ),
                      child: Center(
                        child: Text(
                          _page < _pages.length - 1 ? 'next →' : "let's go →",
                          style: AppTypography.button.copyWith(color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pages ──────────────────────────────────────────────────────────────

class _Page1 extends StatelessWidget {
  const _Page1();

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return _PageLayout(
      col: col,
      illustration: _CellInputIllustration(col: col),
      title: 'how to play.',
      body: 'tap a cell, then tap a number to place it.\n\n'
          'use × to erase. toggle notes mode to pencil in candidates without committing.',
    );
  }
}

class _Page2 extends StatelessWidget {
  const _Page2();

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return _PageLayout(
      col: col,
      illustration: _QualityIllustration(col: col),
      title: 'quality score.',
      body: 'every solve gets a score based on speed, mistakes, and hints used.\n\n'
          'a clean solve — no hints, no mistakes — scores highest. aim for solid or clean.',
    );
  }
}

class _Page3 extends StatelessWidget {
  const _Page3();

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return _PageLayout(
      col: col,
      illustration: _DailyIllustration(col: col),
      title: 'daily puzzle.',
      body: 'a new puzzle drops every day. the same puzzle, for everyone, globally.\n\n'
          'solve daily to build your streak. one day grace if you miss.',
    );
  }
}

// ── Shared layout ──────────────────────────────────────────────────────

class _PageLayout extends StatelessWidget {
  final AppThemeColors col;
  final Widget illustration;
  final String title;
  final String body;

  const _PageLayout({
    required this.col,
    required this.illustration,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: illustration)
              .animate()
              .fadeIn(duration: 300.ms)
              .scale(begin: const Offset(0.92, 0.92), duration: 300.ms, curve: Curves.easeOut),
          const SizedBox(height: 40),
          Text(
            title,
            style: AppTypography.number.copyWith(
              color: col.ink,
              fontSize: 40,
              fontWeight: FontWeight.w700,
              letterSpacing: -1.2,
              height: 1,
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 250.ms),
          const SizedBox(height: 14),
          Text(
            body,
            style: AppTypography.label.copyWith(
              color: col.ink3,
              height: 1.55,
            ),
          ).animate().fadeIn(delay: 160.ms, duration: 250.ms),
        ],
      ),
    );
  }
}

// ── Illustrations ──────────────────────────────────────────────────────

class _CellInputIllustration extends StatelessWidget {
  final AppThemeColors col;
  const _CellInputIllustration({required this.col});

  @override
  Widget build(BuildContext context) {
    const cellSize = 52.0;
    const gap = 6.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // 3×3 mini grid — center cell selected (mint)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (r) {
            return Padding(
              padding: EdgeInsets.only(bottom: r < 2 ? gap : 0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (c) {
                  final selected = r == 1 && c == 1;
                  final hasNumber = (r == 0 && c == 0) || (r == 2 && c == 2);
                  return Padding(
                    padding: EdgeInsets.only(right: c < 2 ? gap : 0),
                    child: Container(
                      width: cellSize,
                      height: cellSize,
                      decoration: BoxDecoration(
                        color: selected ? col.mint.withValues(alpha: 0.5) : col.paper,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: selected ? col.ink : col.ink4,
                          width: selected ? 2.5 : 1.5,
                        ),
                        boxShadow: selected
                            ? [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)]
                            : null,
                      ),
                      child: hasNumber
                          ? Center(
                              child: Text(
                                r == 0 ? '3' : '7',
                                style: AppTypography.number.copyWith(
                                  color: col.ink3,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w500,
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
        ),
        const SizedBox(width: 16),
        // Number pad strip (3 keys)
        Column(
          mainAxisSize: MainAxisSize.min,
          children: ['5', '6', '7'].map((n) {
            final isActive = n == '6';
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isActive ? col.accent : col.paper,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: col.ink, width: 2),
                  boxShadow: [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)],
                ),
                child: Center(
                  child: Text(
                    n,
                    style: AppTypography.number.copyWith(
                      color: isActive ? Colors.white : col.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _QualityIllustration extends StatelessWidget {
  final AppThemeColors col;
  const _QualityIllustration({required this.col});

  @override
  Widget build(BuildContext context) {
    const tiers = ['chaos', 'rough', 'decent', 'solid', 'clean'];
    const activeIndex = 3; // "solid"

    return Container(
      width: 280,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: col.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'QUALITY SCORE',
                style: AppTypography.labelSmall.copyWith(
                  color: col.ink3,
                  fontSize: 10,
                  letterSpacing: 1.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                '82',
                style: AppTypography.number.copyWith(
                  color: col.accent,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 5),
              Text(
                'SOLID',
                style: AppTypography.labelSmall.copyWith(
                  color: col.accent,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: col.ink4.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: col.ink, width: 1.5),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: 0.82,
                child: Container(
                  decoration: BoxDecoration(
                    color: col.accent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(tiers.length, (i) {
              final active = i == activeIndex;
              return Text(
                tiers[i],
                style: AppTypography.labelSmall.copyWith(
                  color: active ? col.accent : col.ink4,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _DailyIllustration extends StatelessWidget {
  final AppThemeColors col;
  const _DailyIllustration({required this.col});

  @override
  Widget build(BuildContext context) {
    final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    // M-F solved, S=today (active), S=future
    final solved = [true, true, true, true, true, false, false];
    final today = 5;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(days.length, (i) {
            final isSolved = solved[i];
            final isToday = i == today;
            return Padding(
              padding: EdgeInsets.only(right: i < days.length - 1 ? 8 : 0),
              child: Column(
                children: [
                  Text(
                    days[i],
                    style: AppTypography.labelSmall.copyWith(
                      color: col.ink4,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isToday
                          ? col.accent
                          : isSolved
                              ? col.mint.withValues(alpha: 0.6)
                              : col.paper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isToday ? col.ink : isSolved ? col.ink3 : col.ink4,
                        width: isToday ? 2 : 1.5,
                      ),
                      boxShadow: isToday
                          ? [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)]
                          : null,
                    ),
                    child: Center(
                      child: isSolved && !isToday
                          ? Text('✓',
                              style: AppTypography.labelSmall.copyWith(
                                color: col.ink,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ))
                          : isToday
                              ? Text('★',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ))
                              : null,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: col.accent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: col.ink, width: 2),
            boxShadow: col.cardShadow,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🔥', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                '5 day streak',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
