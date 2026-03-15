import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildHeader(),
              const SizedBox(height: 40),
              _buildDifficultySection(context),
              const Spacer(),
              _buildFooter(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Text(
      'no bs sudoku',
      style: AppTypography.wordmark.copyWith(
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildDifficultySection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'new game',
          style: AppTypography.label.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _DifficultyTile(
          label: 'easy',
          description: 'good for warming up',
          onTap: () => _startGame(context, 'easy'),
        ),
        _DifficultyTile(
          label: 'medium',
          description: 'the sweet spot',
          onTap: () => _startGame(context, 'medium'),
        ),
        _DifficultyTile(
          label: 'hard',
          description: 'bring some focus',
          onTap: () => _startGame(context, 'hard'),
        ),
        _DifficultyTile(
          label: 'expert',
          description: 'no hand-holding',
          onTap: () => _startGame(context, 'expert'),
        ),
      ],
    );
  }

  void _startGame(BuildContext context, String difficulty) {
    HapticFeedback.lightImpact();
    context.push('/game/$difficulty');
  }

  Widget _buildFooter() {
    return Text(
      'just sudoku.',
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textDisabled,
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  final String label;
  final String description;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.label,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.body.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.textDisabled,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }
}
