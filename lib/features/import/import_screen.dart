import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/a11y/tappable.dart';
import '../../core/haptics.dart';
import '../../core/logger.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_back_button.dart';
import '../../engine/sudoku_solver.dart';
import 'import_cubit.dart';

/// Type or paste a puzzle from somewhere else and play it here.
///
/// An analysis tool rather than a scored mode: nothing here touches records,
/// streaks or stats, because a grid from a newspaper has no difficulty and so
/// no par time to grade against.
class ImportScreen extends StatelessWidget {
  const ImportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ImportCubit(),
      child: const _ImportView(),
    );
  }
}

class _ImportView extends StatelessWidget {
  const _ImportView();

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;

    return BlocBuilder<ImportCubit, ImportState>(
      builder: (context, state) {
        final cubit = context.read<ImportCubit>();

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
                  child: Row(
                    children: [
                      const AppBackButton(),
                      const Spacer(),
                      Tappable(
                        label: 'paste a puzzle',
                        hint: 'read 81 digits from the clipboard',
                        onTap: () => _paste(context, cubit),
                        child: _PillButton(label: 'paste', col: col),
                      ),
                      const SizedBox(width: 8),
                      Tappable(
                        label: 'clear the grid',
                        onTap: state.filled == 0
                            ? null
                            : () {
                                Haptics.select();
                                cubit.clearAll();
                              },
                        child: _PillButton(
                          label: 'clear',
                          col: col,
                          enabled: state.filled > 0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('import a puzzle.',
                          style:
                              AppTypography.heading.copyWith(color: col.ink)),
                      const SizedBox(height: 4),
                      Text(
                        'from a newspaper or another app. it will not count '
                        'towards your stats or streak.',
                        style: AppTypography.labelSmall
                            .copyWith(color: col.ink4, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md),
                      child: _EntryGrid(state: state),
                    ),
                  ),
                ),
                _Verdict(state: state),
                const SizedBox(height: 10),
                _Keypad(state: state),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _paste(BuildContext context, ImportCubit cubit) async {
    Haptics.select();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (!context.mounted) return;

    final ok = text != null && cubit.paste(text);
    if (!ok) {
      // Saying no is better than filling in a partial grid and letting the
      // player wonder what happened to the rest.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "that doesn't look like a puzzle. 81 digits, 0 or . for blanks.",
            style: AppTypography.labelSmall
                .copyWith(color: Colors.white, fontSize: 11),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

class _EntryGrid extends StatelessWidget {
  const _EntryGrid({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final cubit = context.read<ImportCubit>();
    final conflicts = state.conflicts;

    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: col.ink, width: 2),
          borderRadius: BorderRadius.circular(6),
          boxShadow: col.cardShadow,
          color: col.paper,
        ),
        child: Column(
          children: [
            for (int r = 0; r < 9; r++)
              Expanded(
                child: Row(
                  children: [
                    for (int c = 0; c < 9; c++)
                      Expanded(
                        child: _EntryCell(
                          index: r * 9 + c,
                          value: state.cells[r * 9 + c],
                          isSelected: state.selected == r * 9 + c,
                          isConflict: conflicts.contains(r * 9 + c),
                          col: col,
                          onTap: () {
                            Haptics.select();
                            cubit.select(r * 9 + c);
                          },
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

class _EntryCell extends StatelessWidget {
  const _EntryCell({
    required this.index,
    required this.value,
    required this.isSelected,
    required this.isConflict,
    required this.col,
    required this.onTap,
  });

  final int index;
  final int value;
  final bool isSelected;
  final bool isConflict;
  final AppThemeColors col;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = index ~/ 9;
    final column = index % 9;
    return Tappable(
      label: 'row ${row + 1}, column ${column + 1}, '
          '${value == 0 ? 'empty' : '$value'}'
          '${isConflict ? ', repeats in this row, column or box' : ''}',
      selected: isSelected,
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isConflict
              ? col.error.withValues(alpha: 0.22)
              : isSelected
                  ? col.accent
                  : (row ~/ 3 + column ~/ 3) % 2 == 0
                      ? col.paper
                      : col.background2,
          border: Border(
            right: BorderSide(
              color: col.ink.withValues(alpha: column % 3 == 2 ? 0.5 : 0.15),
              width: column % 3 == 2 && column != 8 ? 1.5 : 0.5,
            ),
            bottom: BorderSide(
              color: col.ink.withValues(alpha: row % 3 == 2 ? 0.5 : 0.15),
              width: row % 3 == 2 && row != 8 ? 1.5 : 0.5,
            ),
          ),
        ),
        child: Center(
          child: Text(
            value == 0 ? '' : '$value',
            style: AppTypography.number.copyWith(
              color: isSelected ? Colors.white : col.ink,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }
}

/// What the check said, or what is stopping it.
class _Verdict extends StatelessWidget {
  const _Verdict({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final cubit = context.read<ImportCubit>();
    final analysis = state.analysis;

    if (state.checking) {
      return _Bar(
        col: col,
        text: 'checking…',
        detail: 'counting the answers. this can take a moment on a sparse '
            'grid.',
      );
    }

    if (analysis == null) {
      final blocked = state.conflicts.isNotEmpty;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Tappable(
          label: 'check this puzzle',
          onTap: state.canCheck
              ? () {
                  Haptics.tap();
                  cubit.check();
                }
              : null,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: state.canCheck ? col.accent : col.background2,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                  color: state.canCheck ? col.ink : col.ink4, width: 2),
              boxShadow: state.canCheck ? col.cardShadow : null,
            ),
            child: Center(
              child: Text(
                blocked
                    ? 'fix the repeated digits first'
                    : state.filled == 0
                        ? 'enter or paste a puzzle'
                        : 'check this puzzle',
                style: AppTypography.button.copyWith(
                  color: state.canCheck ? Colors.white : col.ink4,
                ),
              ),
            ),
          ),
        ),
      );
    }

    if (analysis.isPlayable) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        child: Tappable(
          label: 'play this puzzle',
          onTap: () {
            Haptics.tap();
            Log.importPlayed(clues: state.filled);
            context.push('/game/import', extra: (
              puzzle: state.board,
              solution: analysis.solution!,
            ));
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: col.accent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.ink, width: 2),
              boxShadow: col.cardShadow,
            ),
            child: Center(
              child: Text('one answer. play it',
                  style: AppTypography.button.copyWith(color: Colors.white)),
            ),
          ),
        ),
      ).animate().fadeIn(duration: 160.ms);
    }

    return _Bar(
      col: col,
      text: switch (analysis.verdict) {
        ImportVerdict.unsolvable => 'no solution. check your entry.',
        ImportVerdict.manySolutions =>
          "more than one answer fits. this isn't a valid puzzle.",
        ImportVerdict.budgetExhausted => "couldn't finish checking this one.",
        ImportVerdict.contradictory => 'a digit repeats. fix it and try again.',
        ImportVerdict.empty => 'nothing entered yet.',
        ImportVerdict.unique => '',
      },
      detail: analysis.verdict == ImportVerdict.budgetExhausted
          ? 'it was taking too long to be sure. adding a clue or two usually '
              'settles it.'
          : null,
      isError: true,
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.col,
    required this.text,
    this.detail,
    this.isError = false,
  });

  final AppThemeColors col;
  final String text;
  final String? detail;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isError
              ? Color.alphaBlend(
                  col.error.withValues(alpha: 0.18), col.surface)
              : col.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(text,
                style: AppTypography.body
                    .copyWith(color: col.ink, fontSize: 13)),
            if (detail case final d?) ...[
              const SizedBox(height: 4),
              Text(d,
                  style: AppTypography.labelSmall
                      .copyWith(color: col.ink3, fontSize: 10, height: 1.35)),
            ],
          ],
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.state});

  final ImportState state;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final cubit = context.read<ImportCubit>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          for (int n = 1; n <= 9; n++)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Tappable(
                  label: '$n',
                  onTap: state.selected == null
                      ? null
                      : () {
                          Haptics.tap();
                          cubit.place(n);
                        },
                  child: _Key(text: '$n', col: col),
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Tappable(
                label: 'erase',
                onTap: state.selected == null
                    ? null
                    : () {
                        Haptics.erase();
                        cubit.erase();
                      },
                child: _Key(text: '×', col: col),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.text, required this.col});

  final String text;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: col.paper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.ink, width: 2),
      ),
      child: Center(
        child: Text(text,
            style: AppTypography.number
                .copyWith(color: col.ink, fontSize: 18)),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.label,
    required this.col,
    this.enabled = true,
  });

  final String label;
  final AppThemeColors col;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: enabled ? col.paper : col.background2,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: enabled ? col.ink : col.ink4, width: 2),
      ),
      child: Text(label,
          style: AppTypography.labelSmall.copyWith(
              color: enabled ? col.ink : col.ink4,
              fontSize: 11,
              fontWeight: FontWeight.w700)),
    );
  }
}
