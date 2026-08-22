import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/logger.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/data_reset_service.dart';
import '../../core/storage/repositories/repositories.dart';

class SettingsState {
  final bool autoRemoveNotes;
  final bool highlightMatching;
  final bool showTimer;
  final int mistakeLimit;
  final String theme;
  final String displayName;
  final bool digitFirstInput;

  /// The three coaching switches.
  final bool hintsExplain;
  final bool flagMistakesInstantly;
  final bool nudgeWhenStuck;

  final bool loaded;

  const SettingsState({
    this.autoRemoveNotes = true,
    this.highlightMatching = true,
    this.showTimer = false,
    this.mistakeLimit = 0,
    this.theme = 'dark',
    this.displayName = 'anon',
    this.digitFirstInput = false,
    this.hintsExplain = true,
    this.flagMistakesInstantly = true,
    this.nudgeWhenStuck = true,
    this.loaded = false,
  });

  /// Every setter used to rebuild this by hand, and every one of them left
  /// out digitFirstInput — so changing any other preference silently switched
  /// it off in the UI until the next launch. With ten fields that is not a
  /// slip anyone would catch by reading; it needs to be impossible instead.
  SettingsState copyWith({
    bool? autoRemoveNotes,
    bool? highlightMatching,
    bool? showTimer,
    int? mistakeLimit,
    String? theme,
    String? displayName,
    bool? digitFirstInput,
    bool? hintsExplain,
    bool? flagMistakesInstantly,
    bool? nudgeWhenStuck,
    bool? loaded,
  }) {
    return SettingsState(
      autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      highlightMatching: highlightMatching ?? this.highlightMatching,
      showTimer: showTimer ?? this.showTimer,
      mistakeLimit: mistakeLimit ?? this.mistakeLimit,
      theme: theme ?? this.theme,
      displayName: displayName ?? this.displayName,
      digitFirstInput: digitFirstInput ?? this.digitFirstInput,
      hintsExplain: hintsExplain ?? this.hintsExplain,
      flagMistakesInstantly:
          flagMistakesInstantly ?? this.flagMistakesInstantly,
      nudgeWhenStuck: nudgeWhenStuck ?? this.nudgeWhenStuck,
      loaded: loaded ?? this.loaded,
    );
  }
}

class SettingsCubit extends Cubit<SettingsState> {
  final PreferencesRepository _preferences;
  final ProfileRepository _profiles;
  final DataResetService _reset;

  SettingsCubit({
    required PreferencesRepository preferences,
    required ProfileRepository profiles,
    required DataResetService reset,
  })  : _preferences = preferences,
        _profiles = profiles,
        _reset = reset,
        super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await _preferences.getPreferences();
      final profile = await _profiles.getProfile();
      if (isClosed) return;
      emit(SettingsState(
        autoRemoveNotes: prefs.autoRemoveNotes,
        highlightMatching: prefs.highlightMatching,
        showTimer: prefs.showTimer,
        mistakeLimit: prefs.mistakeLimit,
        theme: prefs.theme,
        displayName: profile.displayName,
        digitFirstInput: prefs.digitFirstInput,
        hintsExplain: prefs.hintsExplain,
        flagMistakesInstantly: prefs.flagMistakesInstantly,
        nudgeWhenStuck: prefs.nudgeWhenStuck,
        loaded: true,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const SettingsState(loaded: true));
    }
  }

  Future<void> setAutoRemoveNotes(bool value) async {
    Log.settingsChanged(setting: 'autoRemoveNotes', value: '$value');
    emit(state.copyWith(autoRemoveNotes: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(autoRemoveNotes: Value(value)),
    );
  }

  Future<void> setHighlightMatching(bool value) async {
    Log.settingsChanged(setting: 'highlightMatching', value: '$value');
    emit(state.copyWith(highlightMatching: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(highlightMatching: Value(value)),
    );
  }

  Future<void> setShowTimer(bool value) async {
    Log.settingsChanged(setting: 'showTimer', value: '$value');
    emit(state.copyWith(showTimer: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(showTimer: Value(value)),
    );
  }

  Future<void> setMistakeLimit(int value) async {
    Log.settingsChanged(setting: 'mistakeLimit', value: '$value');
    emit(state.copyWith(mistakeLimit: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(mistakeLimit: Value(value)),
    );
  }

  Future<void> setTheme(String value) async {
    Log.settingsChanged(setting: 'theme', value: value);
    emit(state.copyWith(theme: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(theme: Value(value)),
    );
  }

  Future<void> setHintsExplain(bool value) async {
    Log.settingsChanged(setting: 'hintsExplain', value: '$value');
    emit(state.copyWith(hintsExplain: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(hintsExplain: Value(value)),
    );
  }

  Future<void> setFlagMistakesInstantly(bool value) async {
    Log.settingsChanged(setting: 'flagMistakesInstantly', value: '$value');
    emit(state.copyWith(flagMistakesInstantly: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(flagMistakesInstantly: Value(value)),
    );
  }

  Future<void> setNudgeWhenStuck(bool value) async {
    Log.settingsChanged(setting: 'nudgeWhenStuck', value: '$value');
    emit(state.copyWith(nudgeWhenStuck: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(nudgeWhenStuck: Value(value)),
    );
  }

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 16) return;
    emit(state.copyWith(displayName: trimmed));
    await _profiles.updateProfile(
      PlayerProfilesCompanion(displayName: Value(trimmed)),
    );
  }

  Future<void> setDigitFirstInput(bool value) async {
    Log.settingsChanged(setting: 'digitFirstInput', value: '$value');
    emit(state.copyWith(digitFirstInput: value));
    await _preferences.updatePreferences(
      GamePreferencesTableCompanion(digitFirstInput: Value(value)),
    );
  }

  Future<void> resetAllData() async {
    Log.dataReset();
    await _reset.resetAll();
    if (isClosed) return;
    emit(const SettingsState(loaded: true));
  }
}
