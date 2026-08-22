import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/storage_service.dart';

/// Manages the current theme mode ('paper', 'dark' or 'amoled').
/// Lives at the top of the widget tree so theme changes rebuild MaterialApp.
class ThemeCubit extends Cubit<String> {
  // Matches the schema default so the first frame does not flash a theme
  // the user is not on.
  ThemeCubit() : super('paper') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await StorageService.instance.getPreferences();
    if (!isClosed) emit(prefs.theme);
  }

  void setTheme(String theme) => emit(theme);
}
