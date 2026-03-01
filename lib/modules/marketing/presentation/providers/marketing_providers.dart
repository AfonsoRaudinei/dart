import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../data/repositories/i_marketing_case_repository.dart';
import '../../data/repositories/marketing_case_repository_impl.dart';
import '../../data/services/marketing_sync_service.dart';
import '../../domain/entities/marketing_case.dart';

// ── Repositório ────────────────────────────────────────────────
final marketingCaseRepositoryProvider = Provider<IMarketingCaseRepository>((
  ref,
) {
  return MarketingCaseRepositoryImpl(Supabase.instance.client);
});

// ── Sync Service ───────────────────────────────────────────────
final marketingSyncServiceProvider = Provider<MarketingSyncService>((ref) {
  final repo = ref.watch(marketingCaseRepositoryProvider);
  return MarketingSyncService(repo);
});

// ── State do provider: a lista de cases ───────────────────────
class MarketingCasesNotifier
    extends StateNotifier<AsyncValue<List<MarketingCase>>> {
  final IMarketingCaseRepository _repository;
  final MarketingSyncService _syncService;

  MarketingCasesNotifier(this._repository, this._syncService)
    : super(const AsyncLoading());

  /// Carrega os cases (cache local com fallback remoto)
  Future<void> load({bool forceSync = false}) async {
    try {
      state = const AsyncLoading();
      final cases = await _syncService.getCases(forceSync: forceSync);
      state = AsyncData(cases);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  /// Envia o case ao Supabase, atualiza a lista imediatamente (optimistic)
  Future<MarketingCase?> publishCase(MarketingCase newCase) async {
    // 1. Optimistic update: adiciona à lista com syncStatus=local_only
    final previousCases = state.valueOrNull ?? [];
    state = AsyncData([...previousCases, newCase]);

    try {
      // 2. Enviar ao Supabase
      final savedCase = await _repository.saveCase(newCase);

      // 3. Substituir o case temporário pelo definitivo (syncStatus=synced)
      final updatedCases = state.valueOrNull ?? [];
      state = AsyncData(
        updatedCases.map((c) => c.id == newCase.id ? savedCase : c).toList(),
      );

      return savedCase;
    } catch (e, st) {
      debugPrint('Erro ao publicar case: $e\n$st');
      // Rollback: remover da lista em caso de falha remota mas manter no cache local
      final updatedCases = state.valueOrNull ?? [];
      // Marcar como pending_sync em vez de remover (offline-first)
      state = AsyncData(
        updatedCases
            .map(
              (c) => c.id == newCase.id
                  ? MarketingCase.fromJson({
                      ...newCase.toJson(),
                      'sync_status': 'pending_sync',
                    })
                  : c,
            )
            .toList(),
      );
      return null;
    }
  }

  /// Re-tenta o upload em lote de todos os cases que estão marcados como pending_sync
  Future<void> retryPendingCases() async {
    final currentCases = state.valueOrNull ?? [];
    final pendingCases = currentCases
        .where((c) => c.syncStatus == 'pending_sync')
        .toList();

    if (pendingCases.isEmpty) return;

    bool anyUpdated = false;
    List<MarketingCase> updatedList = List.from(currentCases);

    for (final pending in pendingCases) {
      try {
        final savedCase = await _repository.saveCase(pending);
        // Atualizar na lista local
        final index = updatedList.indexWhere((c) => c.id == pending.id);
        if (index != -1) {
          updatedList[index] = savedCase;
        }
        anyUpdated = true;
      } catch (e) {
        debugPrint('Falha ao re-tentar upload do case ${pending.id}: $e');
      }
    }

    if (anyUpdated) {
      state = AsyncData(updatedList);
    }
  }
}

// ── Provider principal ─────────────────────────────────────────
final marketingCasesProvider =
    StateNotifierProvider<
      MarketingCasesNotifier,
      AsyncValue<List<MarketingCase>>
    >((ref) {
      ref.keepAlive();
      final repo = ref.watch(marketingCaseRepositoryProvider);
      final sync = ref.watch(marketingSyncServiceProvider);
      final notifier = MarketingCasesNotifier(repo, sync);

      // Listener para re-tentar upload de pending_sync quando voltar a conexão
      ref.listen<AsyncValue<bool>>(connectivityStateProvider, (previous, next) {
        final wasDisconnected = previous?.value == false || previous == null;
        final isConnectedNow = next.value == true;

        if (wasDisconnected && isConnectedNow) {
          notifier.retryPendingCases();
        }
      });

      // Auto-load na criação
      notifier.load();
      return notifier;
    });
