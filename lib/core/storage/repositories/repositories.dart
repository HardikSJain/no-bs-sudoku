import '../app_database.dart';
import 'preferences_repository.dart';
import 'profile_repository.dart';
import 'puzzle_record_repository.dart';
import 'saved_game_repository.dart';

export 'preferences_repository.dart';
export 'profile_repository.dart';
export 'puzzle_record_repository.dart';
export 'saved_game_repository.dart';

/// The four repositories, constructed together over one database.
///
/// A convenience for bootstrap only. Consumers should depend on the single
/// repository they actually need, not on this bundle — that narrowness is the
/// whole reason the god object was split, and it is what lets a test hand a
/// cubit one fake instead of a whole database.
class Repositories {
  Repositories(AppDatabase db)
      : records = PuzzleRecordRepository(db),
        profiles = ProfileRepository(db),
        preferences = PreferencesRepository(db),
        savedGames = SavedGameRepository(db);

  final PuzzleRecordRepository records;
  final ProfileRepository profiles;
  final PreferencesRepository preferences;
  final SavedGameRepository savedGames;
}
