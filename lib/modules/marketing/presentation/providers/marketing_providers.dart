import 'dart:async';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' show ClientException;
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

/// Resultado detalhado de [MarketingCasesNotifier.publishCaseDetailed].
class PublishOutcome {
  const PublishOutcome.success(this.publishedCase) : error = null;
  const PublishOutcome.failure(this.error) : publishedCase = null;

  final MarketingCase? publishedCase;
  final Object? error;

  bool get isSuccess => publishedCase != null;
}

/// Falha transitória de rede — offline-first legítimo (mantém published + pending_sync).
bool isTransientNetworkPublishError(Object? error) {
  if (error == null) return false;
  return error is SocketException ||
      error is TimeoutException ||
      error is HttpException ||
      error is ClientException;
}

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

  /// Envia o case ao Supabase, atualiza a lista imediatamente (optimistic).
  /// Em falha, preserva o erro original para a UI classificar a causa.
  Future<PublishOutcome> publishCaseDetailed(MarketingCase newCase) async {
    // 1. Optimistic update idempotente por id (retry não duplica)
    final previousCases = state.valueOrNull ?? [];
    final withoutDuplicate =
        previousCases.where((c) => c.id != newCase.id).toList(growable: false);
    state = AsyncData([...withoutDuplicate, newCase]);

    try {
      // 2. Enviar ao Supabase
      final savedCase = await _repository.saveCase(newCase);

      // 3. Substituir o case temporário pelo definitivo (syncStatus=synced)
      final updatedCases = state.valueOrNull ?? [];
      state = AsyncData(
        updatedCases.map((c) => c.id == newCase.id ? savedCase : c).toList(),
      );

      return PublishOutcome.success(savedCase);
    } catch (e, st) {
      AppLogger.error('Erro ao publicar case', error: e, stackTrace: st);
      final updatedCases = state.valueOrNull ?? [];

      if (isTransientNetworkPublishError(e)) {
        // Offline-first: mantém published + pending_sync para retry automático
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
      } else {
        // Erro permanente (sessão, RLS, schema): reverte para draft recuperável
        final draftCase = MarketingCase.fromJson({
          ...newCase.toJson(),
          'status': MarketingCaseStatus.draft.toValue(),
          'sync_status': 'local_only',
        });
        state = AsyncData(
          updatedCases
              .map((c) => c.id == newCase.id ? draftCase : c)
              .toList(),
        );
        try {
          await _repository.saveAsDraft(draftCase);
        } catch (draftError, draftSt) {
          AppLogger.error(
            'Erro ao reverter case para rascunho após falha permanente',
            tag: 'MarketingProvider',
            error: draftError,
            stackTrace: draftSt,
          );
        }
      }
      return PublishOutcome.failure(e);
    }
  }

  /// Wrapper de compatibilidade — retorna `null` em qualquer falha.
  Future<MarketingCase?> publishCase(MarketingCase newCase) async {
    final outcome = await publishCaseDetailed(newCase);
    return outcome.publishedCase;
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

  /// Atualiza um case existente mantendo o fluxo offline-first.
  Future<void> updateCase(MarketingCase updatedCase) async {
    final previousCases = state.valueOrNull ?? [];
    final optimisticCase = MarketingCase.fromJson({
      ...updatedCase.toJson(),
      'sync_status': 'pending_sync',
      'atualizado_em': DateTime.now().toUtc().toIso8601String(),
    });

    state = AsyncData(
      previousCases
          .map((c) => c.id == optimisticCase.id ? optimisticCase : c)
          .toList(),
    );

    try {
      await _repository.updateCase(optimisticCase);
    } catch (e, st) {
      AppLogger.error('Erro ao atualizar case', error: e, stackTrace: st);
      state = AsyncData(previousCases);
      rethrow;
    }

    try {
      await load(forceSync: true);
    } catch (e, st) {
      AppLogger.error(
        'Erro ao recarregar após update de case; mantendo estado otimista',
        tag: 'MarketingProvider',
        error: e,
        stackTrace: st,
      );
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

  /// Exclusão lógica offline-first: remove da lista visível e enfileira sync.
  Future<void> deleteCase(String id) async {
    final previousCases = state.valueOrNull ?? [];
    final index = previousCases.indexWhere((c) => c.id == id);
    if (index < 0) return;

    final existing = previousCases[index];
    final now = DateTime.now().toUtc();
    final optimisticDeleted = MarketingCase.fromJson({
      ...existing.toJson(),
      'deletado_em': now.toIso8601String(),
      'ativo': false,
      'sync_status': 'pending_sync',
      'atualizado_em': now.toIso8601String(),
    });

    state = AsyncData(
      previousCases
          .map((c) => c.id == id ? optimisticDeleted : c)
          .toList(),
    );

    try {
      final synced = await _repository.softDelete(id);
      final updatedCases = state.valueOrNull ?? [];
      state = AsyncData(
        updatedCases.map((c) => c.id == id ? synced : c).toList(),
      );
    } catch (e, st) {
      AppLogger.error('Erro ao excluir case', error: e, stackTrace: st);
      state = AsyncData(previousCases);
      rethrow;
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
