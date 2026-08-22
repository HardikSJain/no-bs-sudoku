import '../logger.dart';
import 'repositories/repositories.dart';

/// Factory reset. The one operation that legitimately spans repositories.
///
/// It fans out rather than deleting tables directly, which is what keeps two
/// guarantees: the saved-game stream fires (the home screen used to keep
/// rendering a resume bar for a game it had just erased), and a table added
/// later cannot be silently missed — it has to be given a repository, and that
/// repository has to be wired in here.
class DataResetService {
  DataResetService({
    required PuzzleRecordRepository records,
    required SavedGameRepository savedGames,
    required ProfileRepository profiles,
    required MasteryRepository mastery,
  })  : _records = records,
        _savedGames = savedGames,
        _profiles = profiles,
        _mastery = mastery;

  final PuzzleRecordRepository _records;
  final SavedGameRepository _savedGames;
  final ProfileRepository _profiles;
  final MasteryRepository _mastery;

  Future<void> resetAll() async {
    Log.storage('resetAllData');
    await _records.deleteAll();
    await _savedGames.deleteAll();
    await _profiles.reset();
    // A mastery profile surviving a factory reset is exactly the kind of
    // thing that erodes trust in the button.
    await _mastery.deleteAll();
  }
}
