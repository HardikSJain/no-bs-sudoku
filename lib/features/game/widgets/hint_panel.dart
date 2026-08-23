import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/a11y/tappable.dart';
import '../../../core/haptics.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../game_cubit.dart';
import '../game_state.dart';
import '../hint_copy.dart';
import '../hint_engine.dart';

/// The explanation, shown between the grid and the toolbar.
///
/// It sits there rather than over the grid on purpose: you are reading the
/// sentence and looking at the cells it describes at the same time, so the
/// board must not be covered, and it must not move or resize either — cells
/// shifting under a finger mid-explanation is worse than the explanation
/// being absent. The toolbar and number pad take the space instead.
/// What the board reserves for the panel, whether or not a hint is showing.
///
/// A reservation rather than "however much the copy needs": the board's size
/// is computed from what will be left once this is on screen, so an unbounded
/// panel would either push the board or overflow the column.
///
/// It is a floor, not a ceiling. Once the board is sized, whatever vertical
/// slack is left over goes to the panel too — see `hintPanelHeightFor`.
const double hintPanelMinHeight = 150;

/// The most the panel will take even on a very tall screen.
///
/// Past this it stops being a caption under the board and starts being a page
/// of prose with a sudoku above it.
const double hintPanelCeiling = 260;

/// What the panel takes up before a single word of prose is in it: its own
/// padding, the technique chip, the rung dots and the gaps between them.
///
/// The board is not allowed to squeeze the panel below this, because these
/// parts do not scroll and do not shrink — the chip names the technique and
/// the dots say how much further the explanation goes.
const double hintPanelChromeHeight = 64;

/// The soft bottom edge shown while the panel has copy below the fold.
@visibleForTesting
const Key hintFadeKey = Key('hint-panel-fade');

/// The matching top edge, once the prose has been scrolled past its start.
@visibleForTesting
const Key hintFadeTopKey = Key('hint-panel-fade-top');

class HintPanel extends StatelessWidget {
  const HintPanel({super.key, required this.maxHeight});

  /// The space this screen actually has for the panel. At least
  /// [hintPanelMinHeight] on any screen the board did not have to be clamped
  /// on, and never more than [hintPanelCeiling].
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.activeHint != curr.activeHint ||
          prev.hintRung != curr.hintRung ||
          prev.wrongCells != curr.wrongCells,
      builder: (context, state) {
        if (!state.hasHint) return const SizedBox.shrink();

        final col = context.appColors;
        final cubit = context.read<GameCubit>();
        final result = state.wrongCells.isNotEmpty
            ? HintWrongDigit(state.wrongCells)
            : HintStep(state.activeHint!, honoursSelection: true);
        final label = HintCopy.techniqueLabel(result, state.hintRung);
        final lookFor = HintCopy.lookFor(result, state.hintRung);
        final technique = HintCopy.techniqueOf(result);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: Container(
            width: double.infinity,
            constraints: BoxConstraints(maxHeight: maxHeight),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: col.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.ink, width: 2),
              boxShadow: col.cardShadow,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (label != null) ...[
                        // The name, as a tappable chip. Hearing "pointing
                        // pair" attached to the thing itself, every time, is
                        // how the word stops being jargon — and the chip goes
                        // to the full explanation for anyone who wants it now.
                        //
                        // Outside the scroll region, with the rung dots. It
                        // is the label for everything below it, and a label
                        // that scrolls away the moment you read past the
                        // first line is not doing the job the chip exists
                        // for.
                        Tappable(
                          label: label,
                          hint: technique == null
                              ? null
                              : 'read more about this technique',
                          onTap: technique == null
                              ? null
                              : () {
                                  Haptics.select();
                                  context.push('/learn/${technique.name}');
                                },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 3),
                            decoration: BoxDecoration(
                              color: col.sun,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: col.ink, width: 1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: col.ink,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.4,
                                  ),
                                ),
                                if (technique != null) ...[
                                  const SizedBox(width: 3),
                                  Icon(Icons.chevron_right,
                                      size: 11, color: col.ink),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                      ],
                      // The prose scrolls; the chip and the rung dots do not.
                      // Long copy used to push the dots out of sight, which
                      // hides how far along the explanation is and whether
                      // another tap will say more.
                      Flexible(
                        child: _FadingScroll(
                          surface: col.surface,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                HintCopy.forResult(result, state.hintRung),
                                style: AppTypography.body.copyWith(
                                  color: col.ink,
                                  fontSize: 13,
                                  height: 1.35,
                                ),
                              ),
                              if (lookFor != null) ...[
                                const SizedBox(height: 7),
                                Text(
                                  'look for: $lookFor',
                                  style: AppTypography.labelSmall.copyWith(
                                    color: col.ink4,
                                    fontSize: 10,
                                    height: 1.35,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      _RungDots(rung: state.hintRung, col: col),
                    ],
                  ),
                ),
                Tappable(
                  label: 'dismiss the hint',
                  onTap: () {
                    Haptics.select();
                    cubit.dismissHint();
                  },
                  child: Padding(
                    // Small glyph, real tap target.
                    padding: const EdgeInsets.only(left: 10, top: 2, bottom: 8),
                    child: Icon(Icons.close, size: 16, color: col.ink4),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 140.ms).slideY(
              begin: 0.15,
              end: 0,
              duration: 160.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

/// How far along the explanation is, and how much further it can go.
class _RungDots extends StatelessWidget {
  const _RungDots({required this.rung, required this.col});

  final HintRung rung;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in HintRung.values)
          Container(
            width: r == rung ? 14 : 5,
            height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: r.index <= rung.index
                  ? col.sun
                  : col.ink4.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

/// A scroll view that fades its bottom edge while there is more below.
///
/// The panel clips its prose rather than growing, which without an
/// affordance reads as a sentence that just stops — the recognition cue
/// ended mid-word with nothing to say it continued. A scrollbar would be
/// wrong here (this app has none anywhere), so the last few points of the
/// text soften instead, and the fade goes away once you have reached the
/// bottom.
///
/// The fade is a sibling in a [Stack], not a wrapper around the scroll view.
/// Wrapping was the obvious way to write it and it did not work: adding or
/// removing a widget above the scroll view replaces its element, the
/// [Scrollable] remounts with a fresh state, and the offset resets to zero on
/// the frame the fade appears — so the panel could not be scrolled at all.
class _FadingScroll extends StatefulWidget {
  const _FadingScroll({required this.child, required this.surface});

  final Widget child;

  /// The panel's own background, which the fade ramps to.
  final Color surface;

  @override
  State<_FadingScroll> createState() => _FadingScrollState();
}

class _FadingScrollState extends State<_FadingScroll> {
  final ScrollController _controller = ScrollController();
  bool _more = false;
  bool _above = false;

  /// How much of an edge softens.
  static const double _fadeHeight = 20;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_sync);
    WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _sync() {
    if (!mounted || !_controller.hasClients) return;
    final p = _controller.position;
    final more = p.maxScrollExtent - p.pixels > 1;
    final above = p.pixels > 1;
    if (more != _more || above != _above) {
      setState(() {
        _more = more;
        _above = above;
      });
    }
  }

  /// One soft edge. Named keys so a test can ask whether the affordance is
  /// showing without matching on a gradient.
  Widget _edge({required bool top}) => Positioned(
        left: 0,
        right: 0,
        top: top ? 0 : null,
        bottom: top ? null : 0,
        child: IgnorePointer(
          key: top ? hintFadeTopKey : hintFadeKey,
          child: Container(
            height: _fadeHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: top ? Alignment.bottomCenter : Alignment.topCenter,
                end: top ? Alignment.topCenter : Alignment.bottomCenter,
                colors: [
                  widget.surface.withValues(alpha: 0),
                  widget.surface,
                ],
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        NotificationListener<ScrollMetricsNotification>(
          // The copy changes length with the rung, so whether there is more
          // below changes without anyone scrolling.
          onNotification: (_) {
            WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
            return false;
          },
          child: SingleChildScrollView(
            controller: _controller,
            child: widget.child,
          ),
        ),
        if (_above) _edge(top: true),
        if (_more) _edge(top: false),
      ],
    );
  }
}
