import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/repositories/preferences_repository.dart';

/// Manages the current theme mode ('paper', 'dark' or 'amoled').
/// Lives at the top of the widget tree so theme changes rebuild MaterialApp.
class ThemeCubit extends Cubit<String> {
  // Matches the schema default so the first frame does not flash a theme
  // the user is not on.
  ThemeCubit(this._prefs) : super('paper') {
    _load();
  }

  final PreferencesRepository _prefs;

  Future<void> _load() async {
    final prefs = await _prefs.getPreferences();
    if (!isClosed) emit(prefs.theme);
  }

  void setTheme(String theme) => emit(theme);
}
