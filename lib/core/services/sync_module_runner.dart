import 'sync_orchestrator.dart';

/// Resultado isolado de um módulo de sync (Fase 6).
class SyncModuleResult {
  const SyncModuleResult({
    required this.name,
    required this.tier,
    required this.success,
    required this.duration,
    this.error,
  });

  final String name;
  final int tier;
  final bool success;
  final Duration duration;
  final Object? error;
}

/// Executa módulos por tier: tier 0 sequencial, demais tiers em paralelo.
Future<List<SyncModuleResult>> runSyncModulesByTier(
  List<SyncModule> modules, {
  void Function(int completed, int total)? onProgress,
}) async {
  if (modules.isEmpty) return const [];

  final tiers = <int, List<SyncModule>>{};
  for (final module in modules) {
    tiers.putIfAbsent(module.syncTier, () => []).add(module);
  }

  final sortedTiers = tiers.keys.toList()..sort();
  final results = <SyncModuleResult>[];
  var completed = 0;
  final total = modules.length;

  for (final tier in sortedTiers) {
    final batch = tiers[tier]!;
    if (batch.length == 1) {
      final result = await _runModule(batch.first);
      results.add(result);
      completed++;
      onProgress?.call(completed, total);
      continue;
    }

    final batchResults = await Future.wait(batch.map(_runModule));
    results.addAll(batchResults);
    completed += batchResults.length;
    onProgress?.call(completed, total);
  }

  return results;
}

Future<SyncModuleResult> _runModule(SyncModule module) async {
  final stopwatch = Stopwatch()..start();
  try {
    await module.sync();
    return SyncModuleResult(
      name: module.name,
      tier: module.syncTier,
      success: true,
      duration: stopwatch.elapsed,
    );
  } catch (error) {
    return SyncModuleResult(
      name: module.name,
      tier: module.syncTier,
      success: false,
      duration: stopwatch.elapsed,
      error: error,
    );
  }
}
