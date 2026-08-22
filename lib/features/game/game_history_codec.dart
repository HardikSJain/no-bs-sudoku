import 'dart:convert';

import 'game_state.dart';

/// Serializes the undo stack so it survives backgrounding.
///
/// Today `fromSaved` restores no history at all, so putting the app in the
/// background destroys the undo stack outright. It also drops every velocity
/// counter, which is why quality score and velocity analysis are wrong for any
/// resumed puzzle — and `IntelligenceEngine` acts on that data for difficulty
/// recommendations and daily insights.
///
/// Format is deliberately compact. `AutoFillNotes` carries a full 81-cell notes
/// map, autosave fires on every keystroke, and the whole payload is rewritten
/// each time — so a verbose encoding would rewrite tens of kilobytes per tap.
///
/// The envelope carries a version byte. A format change bumps it; an unreadable
/// or newer blob degrades to an empty history rather than taking the whole save
/// down with it.
class GameHistoryCodec {
  static const int formatVersion = 1;

  static String encode(List<GameAction> history) {
    return jsonEncode({
      'v': formatVersion,
      'a': history.map(_encodeAction).toList(),
    });
  }

  /// Never throws. A corrupt or future-version blob yields an empty history —
  /// the board and notes are the irreplaceable part of a save, and losing the
  /// undo stack must never cost the player their puzzle.
  static List<GameAction> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return const [];
      if (decoded['v'] != formatVersion) return const [];
      final actions = decoded['a'];
      if (actions is! List) return const [];
      final out = <GameAction>[];
      for (final entry in actions) {
        final action = _decodeAction(entry);
        if (action != null) out.add(action);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  // ── encoding ───────────────────────────────────────────────────────

  static Map<String, dynamic> _encodeAction(GameAction a) => switch (a) {
        PlaceNumber() => {
            't': 'p',
            'r': a.row,
            'c': a.col,
            'v': a.value,
            'pv': a.previousValue,
            'pn': a.previousNotes.toList(),
            'cn': _encodeNotes(a.clearedNotes),
          },
        PlaceNote() => {
            't': 'n',
            'r': a.row,
            'c': a.col,
            'nv': a.noteValue,
            'ad': a.wasAdded,
          },
        EraseCell() => {
            't': 'e',
            'r': a.row,
            'c': a.col,
            'pv': a.previousValue,
            'pn': a.previousNotes.toList(),
          },
        UseHint() => {
            't': 'h',
            'r': a.row,
            'c': a.col,
            'rv': a.revealedValue,
            'pv': a.previousValue,
            'pn': a.previousNotes.toList(),
            'cn': _encodeNotes(a.clearedNotes),
          },
        AutoFillNotes() => {
            't': 'f',
            'pn': _encodeNotes(a.previousNotes),
          },
      };

  static Map<String, List<int>> _encodeNotes(Map<int, Set<int>> notes) =>
      {for (final e in notes.entries) '${e.key}': e.value.toList()};

  // ── decoding ───────────────────────────────────────────────────────

  static GameAction? _decodeAction(dynamic e) {
    if (e is! Map) return null;
    try {
      return switch (e['t']) {
        'p' => PlaceNumber(
            e['r'] as int,
            e['c'] as int,
            e['v'] as int,
            e['pv'] as int,
            _ints(e['pn']),
            _decodeNotes(e['cn']),
          ),
        'n' => PlaceNote(
            e['r'] as int,
            e['c'] as int,
            e['nv'] as int,
            e['ad'] as bool,
          ),
        'e' => EraseCell(
            e['r'] as int,
            e['c'] as int,
            e['pv'] as int,
            _ints(e['pn']),
          ),
        'h' => UseHint(
            e['r'] as int,
            e['c'] as int,
            e['rv'] as int,
            e['pv'] as int,
            _ints(e['pn']),
            _decodeNotes(e['cn']),
          ),
        'f' => AutoFillNotes(_decodeNotes(e['pn'])),
        _ => null,
      };
    } catch (_) {
      // One malformed action drops that action, not the whole stack.
      return null;
    }
  }

  static Set<int> _ints(dynamic v) =>
      v is List ? v.whereType<int>().toSet() : <int>{};

  static Map<int, Set<int>> _decodeNotes(dynamic v) {
    if (v is! Map) return {};
    final out = <int, Set<int>>{};
    for (final e in v.entries) {
      final key = int.tryParse('${e.key}');
      if (key == null) continue;
      out[key] = _ints(e.value);
    }
    return out;
  }
}
