import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/clients_repository.dart';
import '../../domain/client.dart';

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

// Controller for Actions
class ClientsController {
  final Ref ref;
  ClientsController(this.ref);

  Future<void> saveClient(Client client) async {
    final repo = ref.read(clientsRepositoryProvider);
    await repo.saveClient(client);
    // Invalidate to refresh lists
    ref.invalidate(clientsListProvider);
    ref.invalidate(clientDetailProvider(client.id));
  }
}

final clientsControllerProvider = Provider<ClientsController>((ref) {
  return ClientsController(ref);
});
