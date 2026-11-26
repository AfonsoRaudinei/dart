import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import '../../data/clients_repository.dart';
import '../../domain/client.dart';
import '../../domain/client_cultura.dart';
import '../../domain/enums/perfil_atendimento_tipo.dart';
import '../../domain/perfil_atendimento_calculator.dart';
import '../client_list_filter_logic.dart';

typedef ClientSyncTrigger = Future<void> Function();

// Repository
final clientsRepositoryProvider = Provider<ClientsRepository>((ref) {
  return ClientsRepository();
});

// Base List
final clientsListProvider = FutureProvider.autoDispose<List<Client>>((
  ref,
) async {
  final repo = ref.watch(clientsRepositoryProvider);
  return repo.getClients();
});

final clientSyncTriggerProvider = Provider<ClientSyncTrigger>((ref) {
  return () =>
      ref.read(syncOrchestratorProvider).triggerSync(SyncPriority.immediate);
});

// Filters
final clientFilterProvider = StateProvider<String>(
  (ref) => 'Todos',
); // Todos, Ativos, Inativos
final clientSearchProvider = StateProvider<String>((ref) => '');

final clientAdvancedFiltersProvider = StateProvider<ClientListAdvancedFilters>(
  (ref) => const ClientListAdvancedFilters(),
);

final clientListCulturaIndexProvider = FutureProvider.autoDispose<
    Map<String, List<ClientListCulturaRow>>>((ref) async {
  final repo = ref.watch(clientsRepositoryProvider);
  final drawings = await repo.getAllDrawingCropRowsByClientId();
  final dbCulturas = await repo.getAllCulturasForUser();
  return buildClientListCulturaIndex(
    drawingsByClientId: drawings,
    culturasByClientId: dbCulturas,
  );
});

// Filtered List
final filteredClientsProvider = Provider.autoDispose<AsyncValue<List<Client>>>((
  ref,
) {
  final clientsAsync = ref.watch(clientsListProvider);
  final culturasAsync = ref.watch(clientListCulturaIndexProvider);
  final filter = ref.watch(clientFilterProvider);
  final search = ref.watch(clientSearchProvider);
  final advanced = ref.watch(clientAdvancedFiltersProvider);

  if (clientsAsync.isLoading) {
    return clientsAsync;
  }
  if (clientsAsync.hasError) {
    return clientsAsync;
  }

  if (advancedFilterNeedsCulturaIndex(advanced)) {
    if (culturasAsync.isLoading) {
      return const AsyncValue.loading();
    }
    if (culturasAsync.hasError) {
      return AsyncValue.error(
        culturasAsync.error!,
        culturasAsync.stackTrace ?? StackTrace.empty,
      );
    }
  }

  final culturasMap = culturasAsync.valueOrNull ?? {};

  return clientsAsync.whenData((clients) {
    return applyClientListFilters(
      clients: clients,
      statusFilter: filter,
      search: search,
      advanced: advanced,
      culturasByClientId: culturasMap,
    );
  });
});

// Single Client
final clientDetailProvider = FutureProvider.family.autoDispose<Client?, String>(
  (ref, id) async {
    final repo = ref.watch(clientsRepositoryProvider);
    return repo.getClientById(id);
  },
);

// Culturas de um cliente
final clientCulturasProvider = FutureProvider.family
    .autoDispose<List<ClientCultura>, String>((ref, clientId) async {
      final repo = ref.watch(clientsRepositoryProvider);
      return repo.getCulturas(clientId);
    });

// Controller for Actions
class ClientsController {
  final Ref ref;
  ClientsController(this.ref);

  void _triggerSyncInBackground() {
    final trigger = ref.read(clientSyncTriggerProvider);
    unawaited(trigger().catchError((_) {}));
  }

  Future<void> saveClient(
    Client client, {
    List<ClientCultura> culturas = const [],
  }) async {
    final repo = ref.read(clientsRepositoryProvider);
    await repo.saveClient(client, culturas: culturas);
    ref.invalidate(clientsListProvider);
    ref.invalidate(clientListCulturaIndexProvider);
    ref.invalidate(clientDetailProvider(client.id));
    ref.invalidate(clientCulturasProvider(client.id));
    _triggerSyncInBackground();
  }

  Future<void> updateClient(
    Client client, {
    List<ClientCultura> culturas = const [],
  }) async {
    final repo = ref.read(clientsRepositoryProvider);
    await repo.updateClient(client, culturas: culturas);
    ref.invalidate(clientsListProvider);
    ref.invalidate(clientListCulturaIndexProvider);
    ref.invalidate(clientDetailProvider(client.id));
    ref.invalidate(clientCulturasProvider(client.id));
    _triggerSyncInBackground();
  }

  Future<void> savePerfilDiagnostico({
    required String clientId,
    required List<PerfilAtendimentoTipo> respostas,
  }) async {
    final resultado = calcularPerfilAtendimento(respostas);
    final repo = ref.read(clientsRepositoryProvider);
    final now = DateTime.now();
    await repo.updateClientPerfilAtendimento(
      clientId: clientId,
      dominante: resultado.dominante,
      secundario: resultado.secundario,
      pontosPragmatico: resultado.pontos.pragmatico,
      pontosAnalitico: resultado.pontos.analitico,
      pontosAfavel: resultado.pontos.afavel,
      pontosExpressivo: resultado.pontos.expressivo,
      atualizadoEm: now,
    );
    ref.invalidate(clientsListProvider);
    ref.invalidate(clientDetailProvider(clientId));
    _triggerSyncInBackground();
  }

  Future<void> deleteClient(String id) async {
    final repo = ref.read(clientsRepositoryProvider);
    await repo.deleteClient(id);
    ref.invalidate(clientsListProvider);
    ref.invalidate(clientListCulturaIndexProvider);
    ref.invalidate(clientDetailProvider(id));
    ref.invalidate(clientCulturasProvider(id));
    _triggerSyncInBackground();
  }
}

final clientsControllerProvider = Provider<ClientsController>((ref) {
  return ClientsController(ref);
});
