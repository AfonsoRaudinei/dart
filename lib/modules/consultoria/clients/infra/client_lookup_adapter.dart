import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import '../data/clients_repository.dart';

/// Implementação concreta de IClientLookup.
/// Vive em consultoria/clients/infra/ — dono dos dados de clientes.
/// NÃO é importado por agenda/ ou drawing/ — eles usam apenas a interface.
/// Registrado via ProviderScope.overrides em main.dart (ADR-015).
class ClientLookupAdapter implements IClientLookup {
  final ClientsRepository _repository;

  ClientLookupAdapter(this._repository);

  @override
  Future<List<ClientSummary>> listAtivos() async {
    final clients = await _repository.getClients();
    return clients
        .where((c) => c.active)
        .map(
          (c) => ClientSummary(
            id: c.id,
            name: c.name,
            photoPath: c.photoPath,
            active: c.active,
          ),
        )
        .toList();
  }

  @override
  Future<ClientSummary?> findById(String id) async {
    final client = await _repository.getClientById(id);
    if (client == null) return null;
    return ClientSummary(
      id: client.id,
      name: client.name,
      photoPath: client.photoPath,
      active: client.active,
    );
  }
}
