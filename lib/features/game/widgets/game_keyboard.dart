import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/haptics.dart';
import '../game_cubit.dart';
import '../hint_engine.dart';

/// Plays the board from a hardware keyboard.
///
/// An iPad with a keyboard case is a very good way to solve sudoku and a very
/// bad one to reach across the screen ninety times. Anyone using a switch
/// device or a keyboard for accessibility reasons is in the same position.
///
/// Every binding maps onto a control that already exists on screen — this
/// adds no capability, only a second way to reach the ones there. The
/// exception is the arrow keys, which move a cursor the touch UI has no need
/// for.
class GameKeyboard extends StatelessWidget {
  const GameKeyboard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<GameCubit>();

    return Focus(
      // The board is the screen, so the screen holds the focus. Nothing else
      // here is focusable, so this keeps it for the whole session rather than
      // handing it to whichever control was tapped last.
      autofocus: true,
      onKeyEvent: (node, event) => _handle(cubit, event),
      child: child,
    );
  }

  KeyEventResult _handle(GameCubit cubit, KeyEvent event) {
    // Key repeat is a held arrow key, which should keep moving. Everything
    // else acts once, on the way down.
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;

    if (_arrows[key] case final delta?) {
      cubit.moveSelection(delta.$1, delta.$2);
      return KeyEventResult.handled;
    }

    if (event is KeyRepeatEvent) return KeyEventResult.ignored;

    if (_digits[key] case final digit?) {
      cubit.placeNumber(digit);
      return KeyEventResult.handled;
    }

    if (_erasers.contains(key)) {
      if (cubit.erase()) Haptics.erase();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyN) {
      Haptics.select();
      cubit.toggleNotesMode();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyU) {
      if (cubit.state.history.isEmpty) return KeyEventResult.handled;
      Haptics.undo();
      cubit.undo();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyH) {
      final result = cubit.useHint();
      if (result is HintNothing) {
        Haptics.select();
      } else {
        unawaited(Haptics.hintRung(cubit.state.hintRung.index));
      }
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape) {
      if (!cubit.state.hasHint) return KeyEventResult.ignored;
      Haptics.select();
      cubit.dismissHint();
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// Arrows and the vi keys, because the audience that owns a keyboard case
  /// overlaps heavily with the audience that has opinions about hjkl.
  // `final`, not `const`: LogicalKeyboardKey overrides `==`, and Dart 3
  // refuses those as constant map keys.
  static final Map<LogicalKeyboardKey, (int, int)> _arrows = {
    LogicalKeyboardKey.arrowUp: (-1, 0),
    LogicalKeyboardKey.arrowDown: (1, 0),
    LogicalKeyboardKey.arrowLeft: (0, -1),
    LogicalKeyboardKey.arrowRight: (0, 1),
    LogicalKeyboardKey.keyK: (-1, 0),
    LogicalKeyboardKey.keyJ: (1, 0),
    LogicalKeyboardKey.keyL: (0, 1),
  };

  /// Both rows of digits: the number row and the numpad on a full keyboard.
  static final Map<LogicalKeyboardKey, int> _digits = {
    LogicalKeyboardKey.digit1: 1,
    LogicalKeyboardKey.digit2: 2,
    LogicalKeyboardKey.digit3: 3,
    LogicalKeyboardKey.digit4: 4,
    LogicalKeyboardKey.digit5: 5,
    LogicalKeyboardKey.digit6: 6,
    LogicalKeyboardKey.digit7: 7,
    LogicalKeyboardKey.digit8: 8,
    LogicalKeyboardKey.digit9: 9,
    LogicalKeyboardKey.numpad1: 1,
    LogicalKeyboardKey.numpad2: 2,
    LogicalKeyboardKey.numpad3: 3,
    LogicalKeyboardKey.numpad4: 4,
    LogicalKeyboardKey.numpad5: 5,
    LogicalKeyboardKey.numpad6: 6,
    LogicalKeyboardKey.numpad7: 7,
    LogicalKeyboardKey.numpad8: 8,
    LogicalKeyboardKey.numpad9: 9,
  };

  static final Set<LogicalKeyboardKey> _erasers = {
    LogicalKeyboardKey.backspace,
    LogicalKeyboardKey.delete,
    LogicalKeyboardKey.digit0,
    LogicalKeyboardKey.numpad0,
    LogicalKeyboardKey.space,
  };

  /// The bindings, in the words settings uses to list them. Kept next to the
  /// handler so the documentation and the behaviour cannot drift.
  static const List<(String, String)> bindings = [
    ('arrows / j k l', 'move around the board'),
    ('1 – 9', 'place a digit, or toggle a note'),
    ('0 / space / delete', 'clear the cell'),
    ('n', 'notes mode'),
    ('u', 'undo'),
    ('h', 'hint, and keep pressing for more'),
    ('esc', 'dismiss the hint'),
  ];
}
