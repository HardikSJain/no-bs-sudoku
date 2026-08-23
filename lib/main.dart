import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/logger.dart';
import 'core/notifications/background_worker.dart';
import 'core/notifications/notification_service.dart';
import 'core/storage/app_database.dart';
import 'core/storage/repositories/repositories.dart';
import 'core/update/forced_update.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase only on platforms with config
  final firebaseOptions = DefaultFirebaseOptions.currentPlatform;
  if (firebaseOptions != null) {
    await Firebase.initializeApp(options: firebaseOptions);

    // Crashlytics: capture Flutter framework errors
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Crashlytics: capture async errors not caught by Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    if (kDebugMode) {
      // Disable Crashlytics + Analytics in debug — avoids polluting prod data.
      // To verify analytics events during dev, run:
      //   adb shell setprop debug.firebase.analytics.app com.nobssudoku.no_bs_sudoku
      // then open Firebase Console → Analytics → DebugView.
      await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(false);
      await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(false);
    }

    // Initialize structured logger (connects to Crashlytics + Analytics)
    Log.init();

    // Not awaited. The cached answer is applied without a network, and the
    // refresh must never stand between a player and the first frame.
    unawaited(ForcedUpdate.instance.start());

    try {
      await NotificationService.init();
      await BackgroundWorker.init();
      await BackgroundWorker.registerPeriodicTasks();
    } catch (e) {
      Log.warn('notification init failed (non-fatal): $e', tag: 'notifications');
    }
  }

  // Initialize database and storage
  final db = AppDatabase.instance;
  final repositories = Repositories(db);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(App(repositories: repositories));
}
