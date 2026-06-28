import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/sync_module_runner.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';

class _StubModule implements SyncModule {
  _StubModule({
    required this.name,
    required this.delay,
    this.syncTier = 1,
    this.shouldFail = false,
  });

  @override
  final String name;
  final Duration delay;
  @override
  final int syncTier;
  final bool shouldFail;

  static final List<String> executionLog = [];

  @override
  Future<void> sync() async {
    executionLog.add('$name:start');
    await Future<void>.delayed(delay);
    if (shouldFail) throw StateError('$name failed');
    executionLog.add('$name:end');
  }
}

void main() {
  setUp(() => _StubModule.executionLog.clear());

  test('tier 0 executa antes de tiers paralelos', () async {
    final modules = [
      _StubModule(name: 'drawing', delay: const Duration(milliseconds: 30)),
      _StubModule(name: 'agronomic', delay: const Duration(milliseconds: 10), syncTier: 0),
      _StubModule(
        name: 'occurrence',
        delay: const Duration(milliseconds: 30),
      ),
    ];

    final results = await runSyncModulesByTier(modules);

    expect(results.map((r) => r.name), ['agronomic', 'drawing', 'occurrence']);
    expect(_StubModule.executionLog.first, 'agronomic:start');
    expect(
      _StubModule.executionLog.indexOf('agronomic:end'),
      lessThan(_StubModule.executionLog.indexOf('drawing:start')),
    );
  });

  test('módulos do mesmo tier rodam em paralelo', () async {
    final modules = [
      _StubModule(name: 'a', delay: const Duration(milliseconds: 50)),
      _StubModule(name: 'b', delay: const Duration(milliseconds: 50)),
      _StubModule(name: 'c', delay: const Duration(milliseconds: 50)),
    ];

    final stopwatch = Stopwatch()..start();
    final results = await runSyncModulesByTier(modules);
    stopwatch.stop();

    expect(results, hasLength(3));
    expect(results.every((r) => r.success), isTrue);
    expect(stopwatch.elapsed.inMilliseconds, lessThan(120));
  });

  test('falha de um módulo não interrompe os demais no mesmo tier', () async {
    final modules = [
      _StubModule(name: 'ok', delay: const Duration(milliseconds: 5)),
      _StubModule(
        name: 'bad',
        delay: const Duration(milliseconds: 5),
        shouldFail: true,
      ),
    ];

    final results = await runSyncModulesByTier(modules);

    expect(results.where((r) => r.success), hasLength(1));
    expect(results.where((r) => !r.success), hasLength(1));
    expect(results.firstWhere((r) => !r.success).error, isA<StateError>());
  });

  test('onProgress reporta conclusão incremental', () async {
    final modules = [
      _StubModule(name: 't0', delay: Duration.zero, syncTier: 0),
      _StubModule(name: 'p1', delay: Duration.zero),
      _StubModule(name: 'p2', delay: Duration.zero),
    ];

    final progress = <int>[];
    await runSyncModulesByTier(
      modules,
      onProgress: (completed, total) => progress.add(completed),
    );

    expect(progress, [1, 3]);
  });
}
