import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../core/logger.dart';
import '../../firebase_options.dart';
import 'feedback_context.dart';

/// What a piece of feedback is about. Three buckets, because a list of ten
/// makes people hunt for the right one and then pick "other" anyway.
enum FeedbackKind {
  bug('something is broken'),
  idea('an idea'),
  other('something else');

  const FeedbackKind(this.label);

  final String label;
}

sealed class FeedbackResult {
  const FeedbackResult();
}

class FeedbackSent extends FeedbackResult {
  const FeedbackSent();
}

class FeedbackFailed extends FeedbackResult {
  const FeedbackFailed(this.reason);

  /// Shown to the player, so it has to be a sentence rather than a status
  /// code. The code goes to the log.
  final String reason;
}

/// Writes feedback to Firestore over its REST API.
///
/// REST rather than `cloud_firestore`, deliberately. The SDK drags in the
/// Firestore C++ core, gRPC and BoringSSL, which costs ten to twenty minutes
/// on every clean iOS build and a large slice of binary size — to send one
/// small document, occasionally, from a screen most people will never open.
/// It also would not work on iOS at all, where this app has no Firebase SDK
/// configured. An HTTPS POST works on both platforms today and adds nothing
/// to the build.
///
/// The API key is not a secret and is already in the app: a Firebase web key
/// identifies the project, it does not authorise anything. What stops abuse
/// is the security rules in `firestore.rules`, which allow a create that
/// looks like feedback and forbid reads, updates and deletes outright.
class FeedbackRepository {
  const FeedbackRepository({http.Client? client}) : _client = client;

  final http.Client? _client;

  static const String collection = 'feedback';

  /// Firestore rejects a document over 1MiB, and nobody types a novel into a
  /// phone. Cut here rather than let the write fail after the player has
  /// spent five minutes writing.
  static const int maxMessageLength = 4000;

  Future<FeedbackResult> send({
    required String message,
    required FeedbackKind kind,
    required FeedbackContext context,
    String? replyTo,
  }) async {
    final text = message.trim();
    if (text.isEmpty) return const FeedbackFailed('nothing to send.');

    // The platform's own options, not Android's. iOS has a different API
    // key, and hardcoding one would work right up until somebody restricts
    // the keys per app — which Google recommends and nags about.
    final options = DefaultFirebaseOptions.currentPlatform;
    final uri = Uri.parse(
      'https://firestore.googleapis.com/v1/projects/${options.projectId}'
      '/databases/(default)/documents/$collection?key=${options.apiKey}',
    );

    final client = _client ?? http.Client();
    try {
      final response = await client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(document(
              message: text,
              kind: kind,
              context: context,
              replyTo: replyTo,
              at: DateTime.now().toUtc(),
            )),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        Log.feedbackSent(kind: kind.name, hasReply: (replyTo ?? '').isNotEmpty);
        return const FeedbackSent();
      }

      Log.warn('feedback rejected: ${response.statusCode} ${response.body}',
          tag: 'feedback');
      return const FeedbackFailed(
          'that did not go through. try again in a moment.');
    } catch (e) {
      Log.warn('feedback failed to send: $e', tag: 'feedback');
      return const FeedbackFailed(
          'could not reach the internet. try again when you are back on.');
    } finally {
      if (_client == null) client.close();
    }
  }

  /// The Firestore REST document body.
  ///
  /// Its own function because the typed-value encoding is fiddly enough to
  /// get wrong quietly — integers go over the wire as *strings*, and a number
  /// sent as a number is silently stored as a double.
  static Map<String, Object?> document({
    required String message,
    required FeedbackKind kind,
    required FeedbackContext context,
    required DateTime at,
    String? replyTo,
  }) {
    final trimmedReply = (replyTo ?? '').trim();
    return {
      'fields': {
        'message': _string(_cap(message)),
        'kind': _string(kind.name),
        'createdAt': {'timestampValue': at.toIso8601String()},
        if (trimmedReply.isNotEmpty) 'replyTo': _string(trimmedReply),
        'context': {
          'mapValue': {
            'fields': {
              for (final entry in context.toMap().entries)
                entry.key: _value(entry.value),
            },
          },
        },
      },
    };
  }

  static String _cap(String text) => text.length <= maxMessageLength
      ? text
      : text.substring(0, maxMessageLength);

  static Map<String, Object?> _string(String value) => {'stringValue': value};

  static Map<String, Object?> _value(Object? value) => switch (value) {
        // Firestore's REST encoding wants integers as strings. Sending 12
        // rather than "12" stores a double, and every query against it then
        // has to know that.
        final int i => {'integerValue': '$i'},
        final bool b => {'booleanValue': b},
        null => {'nullValue': null},
        _ => {'stringValue': '$value'},
      };
}
