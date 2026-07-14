import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/services/connectivity_service.dart';
import '../../../../core/session/session_controller.dart';
import '../../data/repositories/i_marketing_case_repository.dart';
import '../../data/repositories/marketing_case_repository_impl.dart';
import '../../data/services/marketing_sync_service.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

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
  Future<void>? _activeLoad;

  MarketingCasesNotifier(this._repository, this._syncService)
    : super(const AsyncLoading());

  /// Carrega os cases (cache local com fallback remoto)
  Future<void> load({bool forceSync = false}) async {
    final activeLoad = _activeLoad;
    if (activeLoad != null) return activeLoad;

    final loadFuture = _loadLocalFirst(forceSync: forceSync);
    _activeLoad = loadFuture;
    return loadFuture.whenComplete(() {
      _activeLoad = null;
    });
  }

  Future<void> _loadLocalFirst({required bool forceSync}) async {
    List<MarketingCase> localCases = const [];

    try {
      localCases = await _repository.getLocalCases();
      if (localCases.isNotEmpty) {
        state = AsyncData(localCases);
      } else {
        state = const AsyncLoading();
      }

      final cases = await _syncService.getCases(forceSync: true);
      state = AsyncData(cases);
    } catch (e, st) {
      if (localCases.isNotEmpty) {
        AppLogger.error(
          'Erro ao sincronizar MarketingCase; mantendo cache local',
          tag: 'MarketingProvider',
          error: e,
          stackTrace: st,
        );
        state = AsyncData(localCases);
        return;
      }

      if (forceSync) {
        state = AsyncError(e, st);
        return;
      }

      try {
        final fallbackCases = await _syncService.getCases(forceSync: false);
        state = AsyncData(fallbackCases);
      } catch (_) {
        state = AsyncError(e, st);
      }
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
      AppLogger.error('Erro ao publicar case', error: e, stackTrace: st);
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

  /// Salva o case como rascunho (apenas local, não sincroniza)
  Future<MarketingCase> saveAsDraft(MarketingCase newCase) async {
    try {
      final draftCase = await _repository.saveAsDraft(newCase);

      // Adiciona à lista local se necessário (para futuras consultas)
      final currentCases = state.valueOrNull ?? [];
      final exists = currentCases.any((c) => c.id == draftCase.id);

      if (!exists) {
        state = AsyncData([...currentCases, draftCase]);
      }

      return draftCase;
    } catch (e, st) {
      AppLogger.error('Erro ao salvar rascunho', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Publica um rascunho existente (muda status de draft para published)
  Future<MarketingCase?> publishDraft(MarketingCase draft) async {
    if (draft.status != MarketingCaseStatus.draft) {
      throw Exception('Apenas rascunhos podem ser publicados via publishDraft');
    }

    // Atualiza o status para published e tenta enviar ao Supabase
    final publishedCase = MarketingCase.fromJson({
      ...draft.toJson(),
      'status': MarketingCaseStatus.published.toValue(),
      'atualizado_em': DateTime.now().toIso8601String(),
    });

    return publishCase(publishedCase);
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
        AppLogger.error(
          'Falha ao re-tentar upload do case ${pending.id}',
          error: e,
        );
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

// ignore: unused_element
final _marketingLogoutInvalidationRegistration = () {
  SessionController.registerLogoutInvalidation(
    key: 'marketingCasesProvider',
    invalidate: (ref) => ref.invalidate(marketingCasesProvider),
  );
  return true;
}();

// ── Provider de rascunhos ──────────────────────────────────────
/// Retorna apenas os cases com status=draft
final draftCasesProvider = Provider.autoDispose<List<MarketingCase>>((ref) {
  final allCases = ref.watch(marketingCasesProvider).valueOrNull ?? [];
  return allCases.where((c) => c.status == MarketingCaseStatus.draft).toList();
});

// ── Provider de cases publicados ───────────────────────────────
/// Retorna apenas os cases com status=published (para o mapa)
final publishedCasesProvider = Provider.autoDispose<List<MarketingCase>>((ref) {
  final allCases = ref.watch(marketingCasesProvider).valueOrNull ?? [];
  return allCases
      .where(
        (c) =>
            c.status == MarketingCaseStatus.published &&
            c.ativo &&
            c.deletadoEm == null,
      )
      .toList();
});
