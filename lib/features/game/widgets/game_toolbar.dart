import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/haptics.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../game_cubit.dart';
import '../game_state.dart';

class GameToolbar extends StatelessWidget {
  const GameToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.history.length != curr.history.length ||
          prev.isNotesMode != curr.isNotesMode ||
          prev.hintsRemaining != curr.hintsRemaining,
      builder: (context, state) {
        final cubit = context.read<GameCubit>();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _ToolButton(
              icon: Icons.undo_rounded,
              label: 'undo',
              onTap: state.history.isEmpty
                  ? null
                  : () {
                      Haptics.undo();
                      cubit.undo();
                    },
              isActive: false,
            ),
            _ToolButton(
              icon: Icons.backspace_outlined,
              label: 'erase',
              onTap: () {
                Haptics.erase();
                cubit.erase();
              },
              isActive: false,
            ),
            _ToolButton(
              icon: Icons.edit_outlined,
              label: 'notes',
              onTap: () {
                Haptics.select();
                cubit.toggleNotesMode();
              },
              isActive: state.isNotesMode,
            ),
            _ToolButton(
              icon: Icons.lightbulb_outline_rounded,
              label: state.hintsRemaining > 0
                  ? 'hint (${state.hintsRemaining})'
                  : 'hint',
              onTap: state.hintsRemaining > 0
                  ? () {
                      Haptics.hint();
                      cubit.useHint();
                    }
                  : null,
              isActive: false,
            ),
          ],
        );
      },
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool isActive;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final color = isActive
        ? AppColors.accent
        : enabled
            ? AppColors.textSecondary
            : AppColors.textDisabled;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 64,
        height: 56,
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
