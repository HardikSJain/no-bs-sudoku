import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
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
    Future.delayed(const Duration(milliseconds: 1600), () {
      if (mounted) context.go('/home');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'no bs sudoku',
              style: AppTypography.wordmark.copyWith(
                color: AppColors.textPrimary,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, curve: Curves.easeOut),
            const SizedBox(height: 8),
            Text(
              'just sudoku.',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.accent,
              ),
            )
                .animate()
                .fadeIn(delay: 400.ms, duration: 500.ms, curve: Curves.easeOut),
          ],
        ),
      ),
    );
  }
}
