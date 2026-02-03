import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

class MapLogger {
  static void logRenderTime(int milliseconds) {
    if (kDebugMode || kProfileMode) {
      developer.log(
        'Map Render Time: ${milliseconds}ms',
        name: 'MapPerformance',
      );
    }
  }

  static void logMarkerCount(int count) {
    if (kDebugMode || kProfileMode) {
      developer.log('Markers Rendered: $count', name: 'MapPerformance');
    }
  }

  static void logEvent(String event) {
    if (kDebugMode || kProfileMode) {
      developer.log('Map Event: $event', name: 'MapTelemtry');
    }
  }

  static void logError(Object error, StackTrace? stackTrace) {
    if (kDebugMode || kProfileMode) {
      developer.log(
        'Map Error: $error',
        name: 'MapError',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
