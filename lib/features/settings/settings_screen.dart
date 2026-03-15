import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/storage/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_cubit.dart';
import 'settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => SettingsCubit(StorageService.instance),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (!state.loaded) return const SizedBox.shrink();
            final cubit = context.read<SettingsCubit>();

            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  _sectionLabel('game'),
                  _toggleRow('auto-remove notes', state.autoRemoveNotes,
                      cubit.setAutoRemoveNotes),
                  _toggleRow('highlight numbers', state.highlightMatching,
                      cubit.setHighlightMatching),
                  _toggleRow(
                      'show timer', state.showTimer, cubit.setShowTimer),
                  _segmentedRow(
                    'mistake limit',
                    ['off', '3'],
                    state.mistakeLimit == 0 ? 'off' : '3',
                    (v) => cubit.setMistakeLimit(v == 'off' ? 0 : 3),
                  ),
                  _sectionLabel('appearance'),
                  _segmentedRow(
                    'theme',
                    ['dark', 'amoled'],
                    state.theme,
                    (v) {
                      cubit.setTheme(v);
                      context.read<ThemeCubit>().setTheme(v);
                    },
                  ),
                  _sectionLabel('profile'),
                  _nameRow(context, state.displayName, cubit),
                  _sectionLabel('data'),
                  _actionRow('export my data', () => _exportData(context)),
                  SizedBox(height: AppSpacing.md),
                  _actionRow(
                    'reset all data',
                    () => _confirmReset(context, cubit),
                    isDestructive: true,
                  ),
                  _sectionLabel('about'),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md),
                    child: Text(
                      'version 1.0.0',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Padding(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      right: AppSpacing.md,
                      bottom: AppSpacing.xl,
                    ),
                    child: Text(
                      'built with no bs',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textDisabled),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.sm, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      child: GestureDetector(
        onTap: () => context.pop(),
        behavior: HitTestBehavior.opaque,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.textSecondary,
            size: 18,
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 11,
          letterSpacing: 0.5,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body
                      .copyWith(fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              SizedBox(
                height: 24,
                child: Switch.adaptive(
                  value: value,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    onChanged(v);
                  },
                  activeThumbColor: AppColors.accent,
                  activeTrackColor: AppColors.accentDim,
                  inactiveTrackColor: AppColors.border,
                  inactiveThumbColor: AppColors.textDisabled,
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: AppColors.borderSubtle,
          indent: AppSpacing.md,
        ),
      ],
    );
  }

  Widget _segmentedRow(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.body
                      .copyWith(fontSize: 15, color: AppColors.textPrimary),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border, width: 0.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: options.map((opt) {
                    final isSelected = opt == selected;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        onChanged(opt);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 6),
                        color: isSelected
                            ? AppColors.accent
                            : Colors.transparent,
                        child: Text(
                          opt,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.background
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        Divider(
          height: 1,
          color: AppColors.borderSubtle,
          indent: AppSpacing.md,
        ),
      ],
    );
  }

  Widget _nameRow(
      BuildContext context, String displayName, SettingsCubit cubit) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showNameSheet(context, displayName, cubit),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'display name',
                    style: AppTypography.body.copyWith(
                        fontSize: 15, color: AppColors.textPrimary),
                  ),
                ),
                Text(
                  displayName.isEmpty ? 'anon' : displayName,
                  style: AppTypography.body.copyWith(
                    fontSize: 15,
                    color: displayName.isEmpty
                        ? AppColors.textDisabled
                        : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 12,
                  color: AppColors.textDisabled,
                ),
              ],
            ),
          ),
        ),
        Divider(
          height: 1,
          color: AppColors.borderSubtle,
          indent: AppSpacing.md,
        ),
      ],
    );
  }

  void _showNameSheet(
      BuildContext context, String displayName, SettingsCubit cubit) {
    final controller = TextEditingController(text: displayName);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 16,
          style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'anon',
            hintStyle:
                AppTypography.body.copyWith(color: AppColors.textDisabled),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: AppColors.accent),
            ),
          ),
          onSubmitted: (value) {
            cubit.setDisplayName(value);
            Navigator.pop(ctx);
          },
        ),
      ),
    );
  }

  Widget _actionRow(String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  fontSize: 15,
                  color:
                      isDestructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: isDestructive
                  ? AppColors.error.withValues(alpha: 0.5)
                  : AppColors.textDisabled,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    final records = await StorageService.instance.getAllRecords();
    final data = {
      'exported_at': DateTime.now().toIso8601String(),
      'total_records': records.length,
      'records': records
          .map((r) => {
                'puzzle_id': r.puzzleId,
                'difficulty': r.difficulty,
                'is_daily': r.isDaily,
                'time_seconds': r.timeSeconds,
                'hints_used': r.hintsUsed,
                'mistakes': r.mistakes,
                'quality_score': r.qualityScore,
                'completed_at': r.completedAt.toIso8601String(),
                'undos_used': r.undosUsed,
                'used_notes': r.usedNotes,
              })
          .toList(),
    };

    final json = const JsonEncoder.withIndent('  ').convert(data);
    final dir = await getTemporaryDirectory();
    final now = DateTime.now();
    final fileName =
        'no_bs_sudoku_export_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}.json';
    final file = File('${dir.path}/$fileName');
    await file.writeAsString(json);

    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
    ));
  }

  void _confirmReset(BuildContext context, SettingsCubit cubit) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'this will delete all your puzzles, stats, and streak.',
              style:
                  AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              'this cannot be undone.',
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: AppColors.border, width: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'cancel',
                          style: AppTypography.button
                              .copyWith(color: AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(ctx);
                      cubit.resetAllData();
                      context.go('/home');
                    },
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.error,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'reset everything',
                          style: AppTypography.button
                              .copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
