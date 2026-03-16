import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;

class DefaultFirebaseOptions {
  /// Returns null on platforms where Firebase is not yet configured.
  static FirebaseOptions? get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        // iOS not configured yet — return null to skip Firebase init
        return null;
      default:
        return null;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDtBMN8dMmMuaxQYq7JD8_QdgGxee2lP5s',
    appId: '1:59739570150:android:db07e0b03e6f2a5fa2e027',
    messagingSenderId: '59739570150',
    projectId: 'sudoku-48937',
    storageBucket: 'sudoku-48937.firebasestorage.app',
  );
}
