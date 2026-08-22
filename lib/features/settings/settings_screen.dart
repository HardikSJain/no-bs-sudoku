import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/logger.dart';
import '../../core/share_origin.dart';
import '../../core/storage/data_reset_service.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/theme_cubit.dart';
import 'settings_cubit.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => SettingsCubit(
        preferences: ctx.read<PreferencesRepository>(),
        profiles: ctx.read<ProfileRepository>(),
        reset: DataResetService(
          records: ctx.read<PuzzleRecordRepository>(),
          savedGames: ctx.read<SavedGameRepository>(),
          profiles: ctx.read<ProfileRepository>(),
        ),
      ),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
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
                  _buildHeader(context, col),
                  _sectionLabel('game', col),
                  _toggleRow('auto-remove notes', state.autoRemoveNotes, cubit.setAutoRemoveNotes, col),
                  _toggleRow('highlight numbers', state.highlightMatching, cubit.setHighlightMatching, col),
                  _toggleRow('show timer', state.showTimer, cubit.setShowTimer, col),
                  _toggleRow('digit-first input', state.digitFirstInput, cubit.setDigitFirstInput, col),
                  _segmentedRow(
                    'mistake limit',
                    ['off', '3'],
                    state.mistakeLimit == 0 ? 'off' : '3',
                    (v) => cubit.setMistakeLimit(v == 'off' ? 0 : 3),
                    col,
                  ),
                  // Escalation self-adjusts — an expert taps once, a
                  // beginner taps four times — so there are three switches
                  // and no presets.
                  _sectionLabel('coaching', col),
                  _toggleRow('hints explain', state.hintsExplain,
                      cubit.setHintsExplain, col),
                  _toggleRow('flag mistakes instantly',
                      state.flagMistakesInstantly,
                      cubit.setFlagMistakesInstantly, col),
                  _toggleRow('nudge when i\'m stuck', state.nudgeWhenStuck,
                      cubit.setNudgeWhenStuck, col),
                  _sectionLabel('appearance', col),
                  _segmentedRow(
                    'theme',
                    ['paper', 'dark', 'amoled'],
                    state.theme,
                    (v) {
                      cubit.setTheme(v);
                      context.read<ThemeCubit>().setTheme(v);
                    },
                    col,
                  ),
                  _sectionLabel('profile', col),
                  _nameRow(context, state.displayName, cubit, col),
                  _sectionLabel('data', col),
                  _actionRow('export my data', () => _exportData(context), col),
                  const SizedBox(height: AppSpacing.md),
                  _actionRow('reset all data', () => _confirmReset(context, cubit), col, isDestructive: true),
                  _sectionLabel('about', col),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    child: Text(
                      'version 1.0.1',
                      style: AppTypography.labelSmall.copyWith(color: col.ink3),
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
                      style: AppTypography.labelSmall.copyWith(color: col.ink4),
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

  Widget _buildHeader(BuildContext context, AppThemeColors col) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.lg),
      child: GestureDetector(
        onTap: () => context.pop(),
        behavior: HitTestBehavior.opaque,
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
      ),
    );
  }

  Widget _sectionLabel(String text, AppThemeColors col) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.xl, AppSpacing.md, AppSpacing.sm),
      child: Text(
        text,
        style: AppTypography.labelSmall.copyWith(
          fontSize: 11,
          letterSpacing: 0.5,
          color: col.ink3,
        ),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged, AppThemeColors col) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: AppTypography.body.copyWith(fontSize: 15, color: col.ink)),
              ),
              SizedBox(
                height: 24,
                child: Switch.adaptive(
                  value: value,
                  onChanged: (v) {
                    HapticFeedback.lightImpact();
                    onChanged(v);
                  },
                  activeTrackColor: col.accent,
                  activeThumbColor: col.paper,
                  inactiveTrackColor: col.ink4.withValues(alpha: 0.4),
                  inactiveThumbColor: col.paper,
                ),
              ),
            ],
          ),
        ),
        Divider(height: 1, color: col.ink4.withValues(alpha: 0.3), indent: AppSpacing.md),
      ],
    );
  }

  Widget _segmentedRow(
    String label,
    List<String> options,
    String selected,
    ValueChanged<String> onChanged,
    AppThemeColors col,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Text(label, style: AppTypography.body.copyWith(fontSize: 15, color: col.ink)),
              ),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: col.ink, width: 2),
                  boxShadow: [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)],
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
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        color: isSelected ? col.accent : col.paper,
                        child: Text(
                          opt,
                          style: AppTypography.labelSmall.copyWith(
                            color: isSelected ? Colors.white : col.ink3,
                            fontWeight: FontWeight.w600,
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
        Divider(height: 1, color: col.ink4.withValues(alpha: 0.3), indent: AppSpacing.md),
      ],
    );
  }

  Widget _nameRow(BuildContext context, String displayName, SettingsCubit cubit, AppThemeColors col) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showNameSheet(context, displayName, cubit, col),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text('display name', style: AppTypography.body.copyWith(fontSize: 15, color: col.ink)),
                ),
                Text(
                  displayName.isEmpty ? 'anon' : displayName,
                  style: AppTypography.body.copyWith(
                    fontSize: 15,
                    color: displayName.isEmpty ? col.ink4 : col.ink3,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Icon(Icons.arrow_forward_ios, size: 12, color: col.ink4),
              ],
            ),
          ),
        ),
        Divider(height: 1, color: col.ink4.withValues(alpha: 0.3), indent: AppSpacing.md),
      ],
    );
  }

  void _showNameSheet(BuildContext context, String displayName, SettingsCubit cubit, AppThemeColors col) {
    final controller = TextEditingController(text: displayName);
    showModalBottomSheet(
      context: context,
      backgroundColor: col.paper,
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
          style: AppTypography.body.copyWith(color: col.ink),
          decoration: InputDecoration(
            counterText: '',
            hintText: 'anon',
            hintStyle: AppTypography.body.copyWith(color: col.ink4),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: col.ink4),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: col.accent, width: 2),
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

  Widget _actionRow(String label, VoidCallback onTap, AppThemeColors col, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTypography.body.copyWith(
                  fontSize: 15,
                  color: isDestructive ? col.error : col.ink,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 12,
              color: isDestructive ? col.error.withValues(alpha: 0.5) : col.ink4,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    Log.exportData();
    final records = await context.read<PuzzleRecordRepository>().getAllRecords();
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

    if (!context.mounted) return;
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        sharePositionOrigin: context.shareOrigin,
      ),
    );
  }

  void _confirmReset(BuildContext context, SettingsCubit cubit) {
    final col = context.appColors;
    showModalBottomSheet(
      context: context,
      backgroundColor: col.paper,
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
              style: AppTypography.body.copyWith(color: col.ink),
            ),
            const SizedBox(height: 4),
            Text(
              'this cannot be undone.',
              style: AppTypography.labelSmall.copyWith(color: col.ink3),
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
                        color: col.paper,
                        border: Border.all(color: col.ink, width: 2),
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: col.cardShadow,
                      ),
                      child: Center(
                        child: Text('cancel', style: AppTypography.button.copyWith(color: col.ink)),
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
                        color: col.error,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: col.ink, width: 2),
                        boxShadow: col.cardShadow,
                      ),
                      child: Center(
                        child: Text('reset everything', style: AppTypography.button.copyWith(color: Colors.white)),
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
