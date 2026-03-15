import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/storage/app_database.dart';
import 'core/storage/storage_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database and storage
  final db = AppDatabase.instance;
  StorageService.init(db);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const App());
}
