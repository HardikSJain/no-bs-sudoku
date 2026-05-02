import 'dart:convert';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../logger.dart';
import '../storage/storage_service.dart';

// ── FCM background handler ──────────────────────────────────────────────────
// Must be top-level for the isolate to find it.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService._showFcmLocal(message);
}

// ── Notification IDs ────────────────────────────────────────────────────────
// Fixed IDs so we can cancel/replace individual slots without touching others.
class _Id {
  static const int dailyReminder = 2001;
  static const int streakRisk = 2002;
  static const int reengagement = 2003;
  static const int morningNudge = 2004;
}

// ── Channel ─────────────────────────────────────────────────────────────────
const _channelId = 'daily_reminders';
const _channelName = 'Daily Reminders';

// ── Context object passed into schedule() ───────────────────────────────────
class _NotifContext {
  final int streak;
  final int longestStreak;
  final int totalSolved;
  final bool dailyDoneToday;
  final int daysSinceLastPlay; // 0 = played today, 1 = yesterday, etc.
  final String preferredDifficulty;
  final int inferredPlayHour; // 0-23, inferred from recent history
  final double avgQuality; // 0-100
  final bool usedStreakFreezeRecently;

  const _NotifContext({
    required this.streak,
    required this.longestStreak,
    required this.totalSolved,
    required this.dailyDoneToday,
    required this.daysSinceLastPlay,
    required this.preferredDifficulty,
    required this.inferredPlayHour,
    required this.avgQuality,
    required this.usedStreakFreezeRecently,
  });
}

// ── Service ─────────────────────────────────────────────────────────────────

class NotificationService {
  NotificationService._();

  static final _fcm = FirebaseMessaging.instance;
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  // ── Init (call once after Firebase.initializeApp) ──────────────────────

  /// Full init — call from main() after Firebase is ready.
  static Future<void> init() async {
    if (_initialized) return;
    await _initLocalAndTimezone();

    // FCM permission (Android 13+ requires explicit grant)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: false,
      sound: false,
      provisional: false,
    );
    Log.info('notification permission: ${settings.authorizationStatus.name}', tag: 'fcm');

    // FCM: foreground messages → local notification
    FirebaseMessaging.onMessage.listen(_onFcmForeground);

    // FCM: app opened from notification (background state)
    FirebaseMessaging.onMessageOpenedApp.listen(_onFcmOpened);

    // FCM token — TOO_MANY_REGISTRATIONS can occur on emulators/test devices;
    // treat as non-fatal so the app still launches.
    try {
      final token = await _fcm.getToken();
      if (token != null) Log.info('fcm token: $token', tag: 'fcm');
      _fcm.onTokenRefresh.listen((_) => Log.info('fcm token refreshed', tag: 'fcm'));
    } catch (e) {
      Log.warn('fcm getToken failed (non-fatal): $e', tag: 'fcm');
    }
  }

  /// Lightweight init for WorkManager background isolate — no Firebase.
  static Future<void> initForBackground() async {
    if (_initialized) return;
    await _initLocalAndTimezone();
  }

  static Future<void> _initLocalAndTimezone() async {
    _initialized = true;

    // Timezone
    tz_data.initializeTimeZones();
    final tzInfo = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzInfo.identifier));

    // Android notification channel
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Daily puzzle reminders and streak nudges',
      importance: Importance.defaultImportance,
      playSound: false,
      enableVibration: true,
    );
    await _local
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    // Local notifications plugin
    const initSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onTap,
      onDidReceiveBackgroundNotificationResponse: _onTap,
    );

    Log.info('NotificationService initialized (tz: ${tzInfo.identifier})', tag: 'notifications');
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Call on every app foreground (home screen load). Cancels stale
  /// notifications and reschedules based on fresh user context.
  static Future<void> schedule() async {
    if (!_initialized) return;
    final ctx = await _buildContext();

    // cancelAll deserializes previously saved notifications; stale records from
    // a prior install or schema mismatch throw "Missing type parameter". Swallow
    // the error — we still schedule fresh slots below.
    try {
      await _local.cancelAll();
    } catch (e) {
      Log.warn('cancelAll failed, skipping (stale notification records): $e', tag: 'notifications');
    }

    final now = tz.TZDateTime.now(tz.local);

    if (ctx.dailyDoneToday) {
      // Puzzle done — schedule tomorrow's morning nudge and nothing else
      await _scheduleMorningNudge(ctx, now);
      return;
    }

    // Not done today → schedule in priority order
    await _scheduleDailyReminder(ctx, now);
    if (ctx.streak > 0) await _scheduleStreakRisk(ctx, now);
    if (ctx.daysSinceLastPlay >= 2) await _scheduleReengagement(ctx, now);

    Log.info(
      'scheduled notifications: streak=${ctx.streak} daysSince=${ctx.daysSinceLastPlay}',
      tag: 'notifications',
    );
  }

  /// Call immediately after completing today's puzzle so the daily reminder
  /// is cancelled and tomorrow's morning nudge takes its place.
  static Future<void> onPuzzleCompleted() async {
    if (!_initialized) return;
    try {
      await _local.cancel(_Id.dailyReminder);
      await _local.cancel(_Id.streakRisk);
      await _local.cancel(_Id.reengagement);
    } catch (e) {
      Log.warn('cancel failed (stale notification records): $e', tag: 'notifications');
    }
    final ctx = await _buildContext();
    await _scheduleMorningNudge(ctx, tz.TZDateTime.now(tz.local));
    Log.info('daily reminders cancelled, morning nudge set', tag: 'notifications');
  }

  static Future<String?> getFcmToken() => _fcm.getToken();

  // ── Context builder ────────────────────────────────────────────────────

  static Future<_NotifContext> _buildContext() async {
    final storage = StorageService.instance;
    final profile = await storage.getProfile();
    final records = await storage.getAllRecords();
    final dailyDone = await storage.hasCompletedDailyToday();
    final avgQuality = await storage.getAvgQualityScore();

    // Days since last play
    int daysSince = 999;
    if (profile.lastPlayedDate != null) {
      final today = DateTime.now();
      final last = profile.lastPlayedDate!;
      daysSince = DateTime(today.year, today.month, today.day)
          .difference(DateTime(last.year, last.month, last.day))
          .inDays;
    }

    // Infer play hour from last 10 records (hour of day they completed puzzles)
    int inferredHour = 19; // default: 7pm
    if (records.isNotEmpty) {
      final recent = records.take(10).toList();
      final hours = recent.map((r) => r.completedAt.hour).toList();
      // Circular mean for hours (handles midnight wrap)
      final sinMean = hours.map((h) => sin(h * 2 * pi / 24)).reduce((a, b) => a + b) / hours.length;
      final cosMean = hours.map((h) => cos(h * 2 * pi / 24)).reduce((a, b) => a + b) / hours.length;
      inferredHour = (atan2(sinMean, cosMean) * 24 / (2 * pi)).round() % 24;
      // Clamp to reasonable hours (8am–10pm)
      inferredHour = inferredHour.clamp(8, 22);
    }

    final lastFreeze = profile.lastFreezeUsedDate;
    final usedFreezeRecently = lastFreeze != null &&
        DateTime.now().difference(lastFreeze).inDays < 7;

    return _NotifContext(
      streak: profile.currentStreak,
      longestStreak: profile.longestStreak,
      totalSolved: profile.totalSolved,
      dailyDoneToday: dailyDone,
      daysSinceLastPlay: daysSince,
      preferredDifficulty: profile.preferredDifficulty,
      inferredPlayHour: inferredHour,
      avgQuality: avgQuality,
      usedStreakFreezeRecently: usedFreezeRecently,
    );
  }

  // ── Schedulers ─────────────────────────────────────────────────────────

  // Fires at the user's inferred play time (or 7pm fallback).
  // If that time already passed today, skips (streak risk covers evening).
  static Future<void> _scheduleDailyReminder(
      _NotifContext ctx, tz.TZDateTime now) async {
    final target = _todayAt(ctx.inferredPlayHour, 0, now);
    if (target.isBefore(now)) return; // already past — let streak risk handle it

    final (title, body) = _dailyCopy(ctx, urgent: false);
    await _schedule(_Id.dailyReminder, title, body, target);
  }

  // Fires at 9pm if not played. Only scheduled when streak > 0 or played yesterday.
  static Future<void> _scheduleStreakRisk(
      _NotifContext ctx, tz.TZDateTime now) async {
    final target = _todayAt(21, 0, now); // 9pm
    if (target.isBefore(now)) return;

    final (title, body) = _dailyCopy(ctx, urgent: true);
    await _schedule(_Id.streakRisk, title, body, target);
  }

  // Fires tomorrow at 10am for lapsed users (2+ days away).
  static Future<void> _scheduleReengagement(
      _NotifContext ctx, tz.TZDateTime now) async {
    final target = _tomorrowAt(10, 0, now);
    final (title, body) = _reengagementCopy(ctx);
    await _schedule(_Id.reengagement, title, body, target);
  }

  // Fires tomorrow at the inferred play hour. Positive reinforcement.
  static Future<void> _scheduleMorningNudge(
      _NotifContext ctx, tz.TZDateTime now) async {
    // Next day at same-ish time they usually play (or 8am if early bird)
    final hour = ctx.inferredPlayHour.clamp(8, 20);
    final target = _tomorrowAt(hour, 0, now);
    final (title, body) = _morningNudgeCopy(ctx);
    await _schedule(_Id.morningNudge, title, body, target);
  }

  // ── Core schedule helper ───────────────────────────────────────────────

  static Future<void> _schedule(
      int id, String title, String body, tz.TZDateTime at) async {
    await _local.zonedSchedule(
      id,
      title,
      body,
      at,
      NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: false,
          enableVibration: true,
          styleInformation: BigTextStyleInformation(body),
        ),
      ),
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    Log.info('scheduled #$id "$title" at ${at.toIso8601String()}', tag: 'notifications');
  }

  // ── Time helpers ───────────────────────────────────────────────────────

  static tz.TZDateTime _todayAt(int hour, int minute, tz.TZDateTime now) {
    return tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
  }

  static tz.TZDateTime _tomorrowAt(int hour, int minute, tz.TZDateTime now) {
    final tomorrow = now.add(const Duration(days: 1));
    return tz.TZDateTime(tz.local, tomorrow.year, tomorrow.month, tomorrow.day, hour, minute);
  }

  // ── Copy: daily reminder ───────────────────────────────────────────────

  static (String, String) _dailyCopy(_NotifContext ctx, {required bool urgent}) {
    final s = ctx.streak;

    if (urgent) {
      // Evening / streak-at-risk copy
      if (s == 0) {
        return ('no bs sudoku', "today's puzzle is still here.");
      } else if (s == 1) {
        return ('no bs sudoku', 'last call. keep your streak alive.');
      } else if (s < 7) {
        return ('no bs sudoku', '$s day streak ends at midnight. don\'t let it.');
      } else if (s < 30) {
        return ('no bs sudoku', '$s days. ends tonight. play now.');
      } else {
        return ('no bs sudoku', '$s day streak — don\'t break it tonight.');
      }
    }

    // Standard reminder
    if (ctx.totalSolved == 0) {
      return ('no bs sudoku', 'your first puzzle is waiting. takes about 5 minutes.');
    } else if (s == 0) {
      return ('no bs sudoku', "today's puzzle is live.");
    } else if (s == 1) {
      return ('no bs sudoku', 'day 2 starts today. puzzle is ready.');
    } else if (s < 7) {
      return ('no bs sudoku', '$s day streak. keep it going.');
    } else if (s < 30) {
      return ('no bs sudoku', '$s days in a row. today\'s puzzle is up.');
    } else if (s == ctx.longestStreak) {
      return ('no bs sudoku', '$s days — your longest streak ever. today\'s is ready.');
    } else {
      return ('no bs sudoku', '$s day streak. one puzzle a day.');
    }
  }

  // ── Copy: re-engagement ────────────────────────────────────────────────

  static (String, String) _reengagementCopy(_NotifContext ctx) {
    final days = ctx.daysSinceLastPlay;
    final diff = ctx.preferredDifficulty;

    if (days == 2) {
      return ('no bs sudoku', 'two days away. easy to get back into.');
    } else if (days == 3) {
      return ('no bs sudoku', '3 days since your last solve. $diff difficulty is waiting.');
    } else if (days < 7) {
      return ('no bs sudoku', '$days days away. today\'s puzzle takes 5 minutes.');
    } else if (days < 14) {
      return ('no bs sudoku', 'a week off. no judgement. puzzle is here when you are.');
    } else {
      return (
        'no bs sudoku',
        ctx.totalSolved > 0
            ? 'been a while. you\'ve solved ${ctx.totalSolved} puzzles before.'
            : 'still here. today\'s puzzle is waiting.',
      );
    }
  }

  // ── Copy: morning nudge (post-completion) ──────────────────────────────

  static (String, String) _morningNudgeCopy(_NotifContext ctx) {
    final s = ctx.streak;

    if (s >= 30) {
      return ('no bs sudoku', '$s day streak. new puzzle just dropped.');
    } else if (s >= 7) {
      return ('no bs sudoku', '$s days strong. new puzzle is live.');
    } else if (s > 0) {
      return ('no bs sudoku', 'new daily puzzle. streak: $s days.');
    } else {
      return ('no bs sudoku', "new puzzle just dropped. 5 minutes.");
    }
  }

  // ── FCM handlers ───────────────────────────────────────────────────────

  static void _onFcmForeground(RemoteMessage message) {
    Log.info('fcm foreground: ${message.messageId}', tag: 'fcm');
    _showFcmLocal(message);
  }

  static void _onFcmOpened(RemoteMessage message) {
    Log.info('fcm opened app: ${message.data}', tag: 'fcm');
  }

  static Future<void> _showFcmLocal(RemoteMessage message) async {
    final n = message.notification;
    if (n == null) return;

    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: false,
      styleInformation: n.body != null ? BigTextStyleInformation(n.body!) : null,
    );

    await _local.show(
      message.hashCode,
      n.title,
      n.body,
      NotificationDetails(android: androidDetails),
      payload: jsonEncode(message.data),
    );
  }

  // ── Notification tap ───────────────────────────────────────────────────

  @pragma('vm:entry-point')
  static void _onTap(NotificationResponse response) {
    if (response.payload == null) return;
    try {
      final data = jsonDecode(response.payload!) as Map<String, dynamic>;
      Log.info('notification tapped: $data', tag: 'notifications');
      // Wire deep links here via a navigator key if needed
    } catch (_) {}
  }
}
