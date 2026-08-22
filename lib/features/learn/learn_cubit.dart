import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/storage/repositories/repositories.dart';
import 'mastery.dart';

class LearnState {
  const LearnState({this.profile, this.loaded = false});

  final MasteryProfile? profile;
  final bool loaded;
}

class LearnCubit extends Cubit<LearnState> {
  LearnCubit(this._mastery) : super(const LearnState()) {
    refresh();
  }

  final MasteryRepository _mastery;

  /// Re-read on every return to the screen: finishing a drill changes what
  /// this shows, and a stale level after a session of practice reads as the
  /// app not noticing.
  Future<void> refresh() async {
    final profile = await _mastery.getProfile();
    if (isClosed) return;
    emit(LearnState(profile: profile, loaded: true));
  }
}
