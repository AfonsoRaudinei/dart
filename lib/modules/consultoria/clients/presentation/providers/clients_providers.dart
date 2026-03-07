import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/clients_repository.dart';
import '../../domain/client.dart';
import '../../domain/client_cultura.dart';

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
final clientCulturasProvider =
    FutureProvider.family.autoDispose<List<ClientCultura>, String>(
  (ref, clientId) async {
    final repo = ref.watch(clientsRepositoryProvider);
    return repo.getCulturas(clientId);
  },
);

// Controller for Actions
class ClientsController {
  final Ref ref;
  ClientsController(this.ref);

  Future<void> saveClient(
    Client client, {
    List<ClientCultura> culturas = const [],
  }) async {
    final repo = ref.read(clientsRepositoryProvider);
    await repo.saveClient(client, culturas: culturas);
    ref.invalidate(clientsListProvider);
    ref.invalidate(clientDetailProvider(client.id));
    ref.invalidate(clientCulturasProvider(client.id));
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
  }

  Future<void> deleteClient(String id) async {
    final repo = ref.read(clientsRepositoryProvider);
    await repo.deleteClient(id);
    ref.invalidate(clientsListProvider);
    ref.invalidate(clientDetailProvider(id));
    ref.invalidate(clientCulturasProvider(id));
  }
}

final clientsControllerProvider = Provider<ClientsController>((ref) {
  return ClientsController(ref);
});
