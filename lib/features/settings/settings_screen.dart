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
import '../../core/theme/app_typography.dart';
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<SettingsCubit, SettingsState>(
          builder: (context, state) {
            if (!state.loaded) return const SizedBox.shrink();
            final cubit = context.read<SettingsCubit>();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  _sectionLabel('game'),
                  _toggleRow('auto-remove notes', state.autoRemoveNotes,
                      cubit.setAutoRemoveNotes),
                  _toggleRow('highlight numbers', state.highlightMatching,
                      cubit.setHighlightMatching),
                  _toggleRow('show timer', state.showTimer, cubit.setShowTimer),
                  _segmentedRow(
                    'mistake limit',
                    ['off', '3'],
                    state.mistakeLimit == 0 ? 'off' : '3',
                    (v) => cubit.setMistakeLimit(v == 'off' ? 0 : 3),
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('appearance'),
                  _segmentedRow(
                    'theme',
                    ['dark', 'amoled'],
                    state.theme,
                    cubit.setTheme,
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('profile'),
                  _nameField(context, state.displayName, cubit),
                  const SizedBox(height: 24),
                  _sectionLabel('data'),
                  _actionRow('export my data', () => _exportData(context)),
                  _actionRow(
                    'reset all data',
                    () => _confirmReset(context, cubit),
                    isDestructive: true,
                  ),
                  const SizedBox(height: 24),
                  _sectionLabel('about'),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      'version 1.0.0',
                      style: AppTypography.labelSmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 32),
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
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'settings',
          style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: AppTypography.label.copyWith(color: AppColors.textSecondary),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
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
    );
  }

  Widget _segmentedRow(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTypography.body.copyWith(color: AppColors.textPrimary),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: options.map((opt) {
              final isSelected = opt == selected;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onChanged(opt);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color:
                        isSelected ? AppColors.accent : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: isSelected
                        ? null
                        : Border.all(color: AppColors.border, width: 0.5),
                  ),
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
        ],
      ),
    );
  }

  Widget _nameField(
      BuildContext context, String displayName, SettingsCubit cubit) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Text(
            'display name',
            style: AppTypography.body.copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              initialValue: displayName,
              maxLength: 16,
              style:
                  AppTypography.body.copyWith(color: AppColors.textPrimary),
              decoration: InputDecoration(
                counterText: '',
                border: InputBorder.none,
                hintText: 'anon',
                hintStyle: AppTypography.body
                    .copyWith(color: AppColors.textDisabled),
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              textAlign: TextAlign.right,
              onFieldSubmitted: cubit.setDisplayName,
              onTapOutside: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionRow(String label, VoidCallback onTap,
      {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.border, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  color: isDestructive ? AppColors.error : AppColors.textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDestructive ? AppColors.error : AppColors.textDisabled,
              size: 14,
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
