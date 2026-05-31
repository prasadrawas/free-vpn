import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class Log {
  static void d(String message) {
    debugPrint(message);
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log(message);
    }
  }

  static void error(String message, [Object? error, StackTrace? stack]) {
    debugPrint('ERROR: $message ${error ?? ''}');
    if (!kDebugMode) {
      FirebaseCrashlytics.instance.log('ERROR: $message');
      if (error != null) {
        FirebaseCrashlytics.instance.recordError(error, stack);
      }
    }
  }
}
