import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/a11y/tappable.dart';
import '../../core/haptics.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_back_button.dart';
import 'feedback_context.dart';
import 'feedback_repository.dart';

/// Somewhere to say something that is not a public one-star review.
///
/// Until this existed the only channel was the store listing, which means
/// every complaint arrived in public, permanently, and usually after the
/// person had already given up.
///
/// The thing that makes it honest is the panel above the send button: the
/// exact payload, every field, rendered. Nothing is gathered that would be
/// awkward to show, because showing it is the design.
class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({
    super.key,
    this.repository = const FeedbackRepository(),
    this.attached,
  });

  final FeedbackRepository repository;

  /// Pre-gathered context. Only set by tests — gathering it for real reads a
  /// database, and a widget test's fake clock does not resolve those futures,
  /// so without a seam here every test of this screen would be a test of
  /// drift's async behaviour instead.
  final FeedbackContext? attached;

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _message = TextEditingController();
  final TextEditingController _replyTo = TextEditingController();

  FeedbackKind _kind = FeedbackKind.bug;
  FeedbackContext? _context;
  bool _sending = false;
  bool _sent = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _context = widget.attached;
    if (_context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _gather());
    }
  }

  @override
  void dispose() {
    _message.dispose();
    _replyTo.dispose();
    super.dispose();
  }

  Future<void> _gather() async {
    if (!mounted) return;
    final media = MediaQuery.of(context);
    final gathered = await FeedbackContext.gather(
      repos: context.read<Repositories>(),
      screenSize: media.size,
      locale: Localizations.localeOf(context).toLanguageTag(),
    );
    if (!mounted) return;
    setState(() => _context = gathered);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 10, AppSpacing.md, AppSpacing.xxl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppBackButton(label: 'back'),
              const SizedBox(height: 18),
              Text(
                _sent ? 'thanks.' : 'tell us.',
                style: AppTypography.wordmark.copyWith(
                    color: col.ink, fontSize: 26, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              Text(
                _sent
                    ? 'it landed. we read all of these.'
                    : 'a bug, an idea, or something that just felt wrong. '
                        'it goes straight to whoever builds this.',
                style: AppTypography.labelSmall
                    .copyWith(color: col.ink3, height: 1.4),
              ),
              if (_sent) ...[
                const SizedBox(height: 28),
                _DoneButton(onTap: () => context.pop()),
              ] else ...[
                const SizedBox(height: 22),
                _kindPicker(col),
                const SizedBox(height: 16),
                _field(
                  col: col,
                  controller: _message,
                  hint: 'what happened, or what you would change',
                  maxLines: 6,
                  maxLength: FeedbackRepository.maxMessageLength,
                  label: 'your message',
                ),
                const SizedBox(height: 12),
                _field(
                  col: col,
                  controller: _replyTo,
                  hint: 'email, only if you want a reply',
                  maxLines: 1,
                  maxLength: 320,
                  label: 'email for a reply, optional',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 20),
                _AttachedPanel(context: _context, col: col),
                if (_error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    _error!,
                    style: AppTypography.labelSmall.copyWith(color: col.error),
                  ),
                ],
                const SizedBox(height: 20),
                _sendButton(col),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _kindPicker(AppThemeColors col) {
    return Column(
      children: [
        for (final kind in FeedbackKind.values) ...[
          Tappable(
            label: kind.label,
            selected: kind == _kind,
            onTap: () {
              Haptics.select();
              setState(() => _kind = kind);
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: kind == _kind ? col.sun : col.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: col.ink, width: 2),
                boxShadow: kind == _kind ? col.cardShadow : null,
              ),
              child: Text(
                kind.label,
                style: AppTypography.body.copyWith(
                  color: col.ink,
                  fontWeight:
                      kind == _kind ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
          if (kind != FeedbackKind.values.last) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _field({
    required AppThemeColors col,
    required TextEditingController controller,
    required String hint,
    required int maxLines,
    required int maxLength,
    required String label,
    TextInputType? keyboardType,
  }) {
    return Semantics(
      label: label,
      textField: true,
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        style: AppTypography.body.copyWith(color: col.ink),
        cursorColor: col.accent,
        decoration: InputDecoration(
          hintText: hint,
          counterText: '',
          hintStyle: AppTypography.body.copyWith(color: col.ink4),
          filled: true,
          fillColor: col.surface,
          contentPadding: const EdgeInsets.all(14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: col.ink, width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: col.ink, width: 2),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: col.accent, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _sendButton(AppThemeColors col) {
    final ready = _message.text.trim().isNotEmpty && !_sending;
    return Tappable(
      label: _sending ? 'sending' : 'send',
      onTap: _sending ? null : _send,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: ready ? col.accent : col.background2,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ready ? col.ink : col.ink4, width: 2),
          boxShadow: ready ? col.cardShadow : null,
        ),
        child: Center(
          child: Text(
            _sending ? 'SENDING' : 'SEND',
            style: AppTypography.button.copyWith(
              color: ready ? Colors.white : col.ink4,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _send() async {
    final text = _message.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'write something first.');
      return;
    }
    final payload = _context;
    if (payload == null) {
      setState(() => _error = 'still getting ready. one moment.');
      return;
    }

    Haptics.select();
    setState(() {
      _sending = true;
      _error = null;
    });

    final result = await widget.repository.send(
      message: text,
      kind: _kind,
      context: payload,
      replyTo: _replyTo.text,
    );
    if (!mounted) return;

    setState(() {
      _sending = false;
      switch (result) {
        case FeedbackSent():
          _sent = true;
        case FeedbackFailed(reason: final reason):
          _error = reason;
      }
    });
  }
}

/// Exactly what is attached, rendered.
///
/// Not behind a disclosure triangle. A panel you have to open is a panel
/// nobody opens, and "we collect some diagnostic information" is the sentence
/// every app says before collecting whatever it likes.
class _AttachedPanel extends StatelessWidget {
  const _AttachedPanel({required this.context, required this.col});

  final FeedbackContext? context;
  final AppThemeColors col;

  @override
  Widget build(BuildContext _) {
    final payload = context;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.background2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: col.ink4, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SENT WITH IT',
            style: AppTypography.labelSmall.copyWith(
                color: col.ink3,
                fontSize: 9,
                letterSpacing: 1.0,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          if (payload == null)
            Text('…',
                style: AppTypography.labelSmall.copyWith(color: col.ink4))
          else
            for (final (name, value) in payload.lines)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: MergeSemantics(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 108,
                        child: Text(name,
                            style: AppTypography.labelSmall.copyWith(
                                color: col.ink4, fontSize: 10, height: 1.4)),
                      ),
                      Expanded(
                        child: Text(value,
                            style: AppTypography.labelSmall.copyWith(
                                color: col.ink3, fontSize: 10, height: 1.4)),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 6),
          Text(
            'no location, no contacts, nothing from other apps, and no way '
            'to tell who you are.',
            style: AppTypography.labelSmall
                .copyWith(color: col.ink4, fontSize: 10, height: 1.4),
          ),
        ],
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  const _DoneButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Tappable(
      label: 'done',
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: col.mint,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Center(
          child: Text('DONE',
              style: AppTypography.button
                  .copyWith(color: col.ink, letterSpacing: 1)),
        ),
      ),
    );
  }
}
