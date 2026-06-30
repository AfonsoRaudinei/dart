import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';

class _RecordingModule implements SyncModule {
  _RecordingModule(this.name, {this.delay = Duration.zero, this.syncTier = 1});

  @override
  final String name;
  final Duration delay;
  @override
  final int syncTier;

  int callCount = 0;

  @override
  Future<void> sync() async {
    callCount++;
    await Future<void>.delayed(delay);
  }
}

class _StaticConnectivityService extends ConnectivityService {
  _StaticConnectivityService(this._connected);

  final bool _connected;

  @override
  Future<bool> get isConnected async => _connected;
}

ProviderContainer _container({required bool connected}) {
  return ProviderContainer(
    overrides: [
      connectivityServiceProvider.overrideWithValue(
        _StaticConnectivityService(connected),
      ),
      syncOrchestratorProvider.overrideWith(
        (ref) => SyncOrchestrator(ref, enableObservers: false),
      ),
    ],
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('triggerSync offline não executa módulos', () async {
    final container = _container(connected: false);
    addTearDown(container.dispose);

    final orchestrator = container.read(syncOrchestratorProvider);
    final module = _RecordingModule('m1');
    orchestrator.registerModule(module);

    await orchestrator.triggerSync(SyncPriority.immediate);

    expect(module.callCount, 0);
    expect(orchestrator.isSyncing, isFalse);
  });

  test('triggerSync online executa módulos e popula lastResults', () async {
    final container = _container(connected: true);
    addTearDown(container.dispose);

    final orchestrator = container.read(syncOrchestratorProvider);
    orchestrator.registerModule(_RecordingModule('alpha'));
    orchestrator.registerModule(_RecordingModule('beta'));

    await orchestrator.triggerSync(SyncPriority.immediate);

    expect(orchestrator.lastResults, hasLength(2));
    expect(orchestrator.lastResults.every((r) => r.success), isTrue);
    expect(orchestrator.progress, 1.0);
  });

  test('immediate enquanto syncing agenda nova execução', () async {
    final container = _container(connected: true);
    addTearDown(container.dispose);

    final orchestrator = container.read(syncOrchestratorProvider);
    final module = _RecordingModule('slow', delay: const Duration(milliseconds: 80));
    orchestrator.registerModule(module);

    unawaited(orchestrator.triggerSync(SyncPriority.normal));
    await Future<void>.delayed(const Duration(milliseconds: 10));
    await orchestrator.triggerSync(SyncPriority.immediate);

    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(module.callCount, 2);
  });

  test('notifyListeners após dispose não lança', () async {
    final container = _container(connected: true);

    final orchestrator = container.read(syncOrchestratorProvider);
    orchestrator.registerModule(
      _RecordingModule('x', delay: const Duration(milliseconds: 30)),
    );

    final future = orchestrator.triggerSync(SyncPriority.immediate);
    orchestrator.dispose();
    await future;

    expect(orchestrator.isSyncing, isFalse);
  });
}
