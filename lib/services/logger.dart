import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class Log {
  static bool get _firebaseAvailable {
    try {
      Firebase.app();
      return true;
    } catch (_) {
      return false;
    }
  }

  static void d(String message) {
    debugPrint(message);
    if (!kDebugMode && _firebaseAvailable) {
      try {
        FirebaseCrashlytics.instance.log(message);
      } catch (_) {}
    }
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    debugPrint('ERROR: $message ${error ?? ''}');
    if (!kDebugMode && _firebaseAvailable) {
      try {
        FirebaseCrashlytics.instance.log('ERROR: $message');
        if (error != null) {
          FirebaseCrashlytics.instance.recordError(error, stack);
        }
      } catch (_) {}
    }
  }
}
