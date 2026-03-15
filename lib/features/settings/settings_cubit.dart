import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/app_database.dart';
import '../../core/storage/storage_service.dart';

class SettingsState {
  final bool autoRemoveNotes;
  final bool highlightMatching;
  final bool showTimer;
  final int mistakeLimit;
  final String theme;
  final String displayName;
  final bool loaded;

  const SettingsState({
    this.autoRemoveNotes = true,
    this.highlightMatching = true,
    this.showTimer = false,
    this.mistakeLimit = 0,
    this.theme = 'dark',
    this.displayName = 'anon',
    this.loaded = false,
  });
}

class SettingsCubit extends Cubit<SettingsState> {
  final StorageService _storage;

  SettingsCubit(this._storage) : super(const SettingsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await _storage.getPreferences();
    final profile = await _storage.getProfile();
    if (isClosed) return;
    emit(SettingsState(
      autoRemoveNotes: prefs.autoRemoveNotes,
      highlightMatching: prefs.highlightMatching,
      showTimer: prefs.showTimer,
      mistakeLimit: prefs.mistakeLimit,
      theme: prefs.theme,
      displayName: profile.displayName,
      loaded: true,
    ));
  }

  Future<void> setAutoRemoveNotes(bool value) async {
    emit(SettingsState(
      autoRemoveNotes: value,
      highlightMatching: state.highlightMatching,
      showTimer: state.showTimer,
      mistakeLimit: state.mistakeLimit,
      theme: state.theme,
      displayName: state.displayName,
      loaded: true,
    ));
    await _storage.updatePreferences(
      GamePreferencesTableCompanion(autoRemoveNotes: Value(value)),
    );
  }

  Future<void> setHighlightMatching(bool value) async {
    emit(SettingsState(
      autoRemoveNotes: state.autoRemoveNotes,
      highlightMatching: value,
      showTimer: state.showTimer,
      mistakeLimit: state.mistakeLimit,
      theme: state.theme,
      displayName: state.displayName,
      loaded: true,
    ));
    await _storage.updatePreferences(
      GamePreferencesTableCompanion(highlightMatching: Value(value)),
    );
  }

  Future<void> setShowTimer(bool value) async {
    emit(SettingsState(
      autoRemoveNotes: state.autoRemoveNotes,
      highlightMatching: state.highlightMatching,
      showTimer: value,
      mistakeLimit: state.mistakeLimit,
      theme: state.theme,
      displayName: state.displayName,
      loaded: true,
    ));
    await _storage.updatePreferences(
      GamePreferencesTableCompanion(showTimer: Value(value)),
    );
  }

  Future<void> setMistakeLimit(int value) async {
    emit(SettingsState(
      autoRemoveNotes: state.autoRemoveNotes,
      highlightMatching: state.highlightMatching,
      showTimer: state.showTimer,
      mistakeLimit: value,
      theme: state.theme,
      displayName: state.displayName,
      loaded: true,
    ));
    await _storage.updatePreferences(
      GamePreferencesTableCompanion(mistakeLimit: Value(value)),
    );
  }

  Future<void> setTheme(String value) async {
    emit(SettingsState(
      autoRemoveNotes: state.autoRemoveNotes,
      highlightMatching: state.highlightMatching,
      showTimer: state.showTimer,
      mistakeLimit: state.mistakeLimit,
      theme: value,
      displayName: state.displayName,
      loaded: true,
    ));
    await _storage.updatePreferences(
      GamePreferencesTableCompanion(theme: Value(value)),
    );
  }

  Future<void> setDisplayName(String name) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.length > 16) return;
    emit(SettingsState(
      autoRemoveNotes: state.autoRemoveNotes,
      highlightMatching: state.highlightMatching,
      showTimer: state.showTimer,
      mistakeLimit: state.mistakeLimit,
      theme: state.theme,
      displayName: trimmed,
      loaded: true,
    ));
    await _storage.updateProfile(
      PlayerProfilesCompanion(displayName: Value(trimmed)),
    );
  }

  Future<void> resetAllData() async {
    await _storage.resetAllData();
    if (isClosed) return;
    emit(const SettingsState(loaded: true));
  }
}
