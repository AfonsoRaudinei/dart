import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/sync_retry_runner.dart';

void main() {
  group('SyncRetryRunner', () {
    test('classifica falhas transitórias, conflito e auth', () {
      expect(
        SyncRetryRunner.classify(TimeoutException('timeout')),
        SyncFailureKind.transientNetwork,
      );
      expect(
        SyncRetryRunner.classify(const SocketException('offline')),
        SyncFailureKind.transientNetwork,
      );
      expect(
        SyncRetryRunner.classify(StateError('DrawingRemoteStore conflict 409')),
        SyncFailureKind.conflict,
      );
      expect(
        SyncRetryRunner.classify(
          StateError('DrawingRemoteStore requires an authenticated user.'),
        ),
        SyncFailureKind.auth,
      );
    });

    test('refaz operação transitória e recupera no segundo attempt', () async {
      var attempts = 0;

      final result = await SyncRetryRunner.execute<int>(
        operation: () async {
          attempts++;
          if (attempts == 1) {
            throw TimeoutException('temporary offline');
          }
          return 7;
        },
        tag: 'TestSync',
        stage: 'retryable_stage',
        maxAttempts: 2,
        retryDelay: Duration.zero,
      );

      expect(result, 7);
      expect(attempts, 2);
    });

    test('não repete falha não transitória', () async {
      var attempts = 0;

      await expectLater(
        SyncRetryRunner.execute<void>(
          operation: () async {
            attempts++;
            throw StateError('auth not ready');
          },
          tag: 'TestSync',
          stage: 'auth_stage',
          maxAttempts: 2,
          retryDelay: Duration.zero,
        ),
        throwsA(isA<StateError>()),
      );

      expect(attempts, 1);
    });
  });
}
