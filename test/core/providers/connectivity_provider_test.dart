import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';

void main() {
  test(
    'isOnlineProvider publica estado inicial e acompanha mudanças',
    () async {
      final controller = StreamController<bool>.broadcast();
      final values = <bool>[];
      final container = ProviderContainer(
        overrides: [
          connectivityServiceProvider.overrideWithValue(
            _FakeConnectivityService(
              initialValue: false,
              stream: controller.stream,
            ),
          ),
        ],
      );
      addTearDown(() async {
        await controller.close();
        container.dispose();
      });

      final subscription = container.listen<AsyncValue<bool>>(
        isOnlineProvider,
        (_, next) {
          next.whenData(values.add);
        },
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      await Future<void>.delayed(Duration.zero);
      expect(values, contains(false));

      controller.add(true);

      await Future<void>.delayed(Duration.zero);
      expect(values, contains(true));
    },
  );
}

class _FakeConnectivityService implements ConnectivityService {
  _FakeConnectivityService({
    required bool initialValue,
    required Stream<bool> stream,
  }) : _initialValue = initialValue,
       _stream = stream;

  final bool _initialValue;
  final Stream<bool> _stream;

  @override
  Stream<bool> get connectivityStream => _stream;

  @override
  Future<bool> get isConnected async => _initialValue;

  @override
  void dispose() {}
}
