import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';
import '../../data/clients_repository.dart';
import '../../domain/client.dart';
import '../../domain/client_cultura.dart';

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

// Filtered List
final filteredClientsProvider = Provider.autoDispose<AsyncValue<List<Client>>>((
  ref,
) {
  final clientsAsync = ref.watch(clientsListProvider);
  final filter = ref.watch(clientFilterProvider);
  final search = ref.watch(clientSearchProvider).toLowerCase();

  return clientsAsync.whenData((clients) {
    return clients.where((c) {
      final matchesSearch = c.name.toLowerCase().contains(search);
      final matchesFilter =
          filter == 'Todos' ||
          (filter == 'Ativos' && c.active) ||
          (filter == 'Inativos' && !c.active);
      return matchesSearch && matchesFilter;
    }).toList();
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
    ref.invalidate(clientDetailProvider(client.id));
    ref.invalidate(clientCulturasProvider(client.id));
    _triggerSyncInBackground();
  }

  Future<void> deleteClient(String id) async {
    final repo = ref.read(clientsRepositoryProvider);
    await repo.deleteClient(id);
    ref.invalidate(clientsListProvider);
    ref.invalidate(clientDetailProvider(id));
    ref.invalidate(clientCulturasProvider(id));
    _triggerSyncInBackground();
  }
}

final clientsControllerProvider = Provider<ClientsController>((ref) {
  return ClientsController(ref);
});
