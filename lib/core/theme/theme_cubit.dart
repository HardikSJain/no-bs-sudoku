import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/storage_service.dart';

/// Manages the current theme mode ('dark' or 'amoled').
/// Lives at the top of the widget tree so theme changes rebuild MaterialApp.
class ThemeCubit extends Cubit<String> {
  ThemeCubit() : super('dark') {
    _load();
  }

  Future<void> _load() async {
    final prefs = await StorageService.instance.getPreferences();
    if (!isClosed) emit(prefs.theme);
  }

  void setTheme(String theme) => emit(theme);
}
