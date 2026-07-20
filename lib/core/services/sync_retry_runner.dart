import 'dart:async';
import 'dart:io';

import '../network/network_policy.dart';
import '../utils/app_logger.dart';

enum SyncFailureKind { transientNetwork, conflict, auth, unknown }

class SyncRetryRunner {
  const SyncRetryRunner._();

  static SyncFailureKind classify(Object error) {
    if (error is TimeoutException || error is SocketException) {
      return SyncFailureKind.transientNetwork;
    }

    final normalized = error.toString().toLowerCase();
    if (normalized.contains('failed host lookup') ||
        normalized.contains('network') ||
        normalized.contains('connection') ||
        normalized.contains('timeout')) {
      return SyncFailureKind.transientNetwork;
    }
    if (normalized.contains('conflict') || normalized.contains('409')) {
      return SyncFailureKind.conflict;
    }
    if (normalized.contains('authenticated user') ||
        normalized.contains('auth not ready') ||
        normalized.contains('userid is null')) {
      return SyncFailureKind.auth;
    }

    return SyncFailureKind.unknown;
  }

  static bool shouldRetry(Object error) =>
      classify(error) == SyncFailureKind.transientNetwork;

  static Future<T> execute<T>({
    required Future<T> Function() operation,
    required String tag,
    required String stage,
    String? entityId,
    int maxAttempts = NetworkPolicy.kMaxRetries,
    Duration retryDelay = const Duration(milliseconds: 300),
  }) async {
    Object? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final result = await NetworkPolicy.withTimeout(operation);
        if (attempt > 1) {
          AppLogger.warning(
            '$stage recovered after retry '
            '[attempt=$attempt entity=${entityId ?? '-'}]',
            tag: tag,
          );
        }
        return result;
      } catch (error) {
        lastError = error;
        final failureKind = classify(error);
        final retryable = shouldRetry(error);
        AppLogger.warning(
          '$stage failed '
          '[attempt=$attempt/$maxAttempts kind=${failureKind.name} '
          'retryable=$retryable entity=${entityId ?? '-'}]: $error',
          tag: tag,
          error: error,
        );

        if (!retryable || attempt >= maxAttempts) break;
        await Future<void>.delayed(retryDelay);
      }
    }

    throw lastError!;
  }
}
