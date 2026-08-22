import 'package:flutter/widgets.dart';
import 'package:workmanager/workmanager.dart';

import '../storage/app_database.dart';
import '../storage/repositories/repositories.dart';
import 'notification_service.dart';

const _taskRefresh = 'refreshNotifications';

/// Top-level entry point for WorkManager tasks.
/// Runs in a separate isolate — no Flutter engine, no singletons from main.
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((taskName, _) async {
    try {
      WidgetsFlutterBinding.ensureInitialized();

      // This isolate gets its own object graph — nothing from main survives
      // the isolate boundary, which is precisely why the repositories are
      // passed explicitly rather than reached for through a singleton.
      final repositories = Repositories(AppDatabase.instance);

      switch (taskName) {
        case _taskRefresh:
          // Background-only init: timezone + local notifications, no Firebase
          await NotificationService.initForBackground();
          await NotificationService.schedule(
            records: repositories.records,
            profiles: repositories.profiles,
          );
      }
      return true;
    } catch (_) {
      // Return true anyway — returning false causes WorkManager to retry
      // immediately and can drain battery. Failures here are non-critical.
      return true;
    }
  });
}

class BackgroundWorker {
  BackgroundWorker._();

  /// Call once after Firebase init in main(). Safe to call multiple times.
  static Future<void> init() async {
    await Workmanager().initialize(callbackDispatcher);
  }

  /// Register the 24h notification refresh task.
  /// Uses [ExistingPeriodicWorkPolicy.replace] so re-installs on every app
  /// launch, keeping the schedule accurate across time zones.
  static Future<void> registerPeriodicTasks() async {
    await Workmanager().registerPeriodicTask(
      _taskRefresh,
      _taskRefresh,
      frequency: const Duration(hours: 24),
      initialDelay: const Duration(hours: 20),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.replace,
      constraints: Constraints(
        networkType: NetworkType.notRequired,
        requiresBatteryNotLow: false,
        requiresCharging: false,
        requiresDeviceIdle: false,
      ),
    );
  }
}
