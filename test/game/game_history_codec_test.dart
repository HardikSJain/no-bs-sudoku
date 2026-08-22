import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/features/game/game_history_codec.dart';
import 'package:no_bs_sudoku/features/game/game_state.dart';

void main() {
  group('round trip', () {
    test('every variant survives encode then decode', () {
      final original = <GameAction>[
        PlaceNumber(0, 1, 5, 0, {2, 3}, {
          10: {5, 7},
          11: {5},
        }),
        const PlaceNote(2, 3, 4, true),
        EraseCell(4, 5, 6, {1, 9}),
        UseHint(6, 7, 8, 0, {4}, {
          20: {8},
        }),
        AutoFillNotes({
          0: {1, 2, 3},
          80: {9},
        }),
      ];

      final decoded = GameHistoryCodec.decode(GameHistoryCodec.encode(original));

      expect(decoded, hasLength(original.length));

      final p = decoded[0] as PlaceNumber;
      expect([p.row, p.col, p.value, p.previousValue], [0, 1, 5, 0]);
      expect(p.previousNotes, {2, 3});
      expect(p.clearedNotes[10], {5, 7});
      expect(p.clearedNotes[11], {5});

      final n = decoded[1] as PlaceNote;
      expect([n.row, n.col, n.noteValue], [2, 3, 4]);
      expect(n.wasAdded, true);

      final e = decoded[2] as EraseCell;
      expect([e.row, e.col, e.previousValue], [4, 5, 6]);
      expect(e.previousNotes, {1, 9});

      final h = decoded[3] as UseHint;
      expect([h.row, h.col, h.revealedValue, h.previousValue], [6, 7, 8, 0]);
      expect(h.previousNotes, {4});
      expect(h.clearedNotes[20], {8});

      final f = decoded[4] as AutoFillNotes;
      expect(f.previousNotes[0], {1, 2, 3});
      expect(f.previousNotes[80], {9});
    });

    test('an empty history round trips', () {
      expect(GameHistoryCodec.decode(GameHistoryCodec.encode([])), isEmpty);
    });

    test('order is preserved', () {
      final actions = <GameAction>[
        for (int i = 0; i < 20; i++) PlaceNote(i ~/ 9, i % 9, (i % 9) + 1, true),
      ];
      final decoded = GameHistoryCodec.decode(GameHistoryCodec.encode(actions));
      expect(decoded, hasLength(20));
      for (int i = 0; i < 20; i++) {
        expect((decoded[i] as PlaceNote).noteValue, (i % 9) + 1);
      }
    });
  });

  group('degrades instead of throwing', () {
    // Losing the undo stack must never cost the player the puzzle. The board
    // and notes are the irreplaceable part of a save.
    test('null and empty yield an empty history', () {
      expect(GameHistoryCodec.decode(null), isEmpty);
      expect(GameHistoryCodec.decode(''), isEmpty);
    });

    test('malformed JSON yields an empty history', () {
      expect(GameHistoryCodec.decode('{not json'), isEmpty);
      expect(GameHistoryCodec.decode('[]'), isEmpty);
      expect(GameHistoryCodec.decode('"a string"'), isEmpty);
    });

    test('a future format version yields an empty history', () {
      expect(GameHistoryCodec.decode('{"v":999,"a":[]}'), isEmpty);
    });

    test('one malformed action drops that action, not the stack', () {
      const raw = '{"v":1,"a":['
          '{"t":"n","r":0,"c":0,"nv":1,"ad":true},'
          '{"t":"n","r":"oops"},'
          '{"t":"zzz"},'
          '{"t":"n","r":1,"c":1,"nv":2,"ad":false}'
          ']}';
      final decoded = GameHistoryCodec.decode(raw);
      expect(decoded, hasLength(2));
      expect((decoded[0] as PlaceNote).noteValue, 1);
      expect((decoded[1] as PlaceNote).noteValue, 2);
    });
  });

  group('payload size', () {
    test('a heavy notes history stays within the autosave budget', () {
      // Autosave rewrites the whole payload on every keystroke, and
      // AutoFillNotes carries a full 81-cell map. Verbose encoding here is the
      // difference between a few KB and tens of KB per tap.
      final heavy = <GameAction>[
        for (int i = 0; i < 5; i++)
          AutoFillNotes({
            for (int c = 0; c < 81; c++) c: {1, 2, 3, 4, 5, 6, 7, 8, 9},
          }),
        for (int i = 0; i < 200; i++) PlaceNote(i % 9, (i * 3) % 9, (i % 9) + 1, true),
      ];

      final encoded = GameHistoryCodec.encode(heavy);
      expect(GameHistoryCodec.decode(encoded), hasLength(205));
      expect(encoded.length, lessThan(60 * 1024),
          reason: 'encoded ${encoded.length} bytes — autosave rewrites this '
              'on every keystroke');
    });
  });
}
