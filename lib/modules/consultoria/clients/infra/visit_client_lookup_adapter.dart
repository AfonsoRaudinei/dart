import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import '../data/clients_repository.dart';
import '../../fields/data/repositories/field_repository.dart';

/// Implementação concreta de IVisitClientLookup.
/// Vive em consultoria/clients/infra/ — dono dos dados de cliente/fazenda/talhão.
class VisitClientLookupAdapter implements IVisitClientLookup {
  final ClientsRepository _clientsRepository;
  final FieldRepository _fieldRepository;

  VisitClientLookupAdapter(this._clientsRepository, this._fieldRepository);

  @override
  Future<List<VisitClientSummary>> listActiveClients() async {
    final clients = await _clientsRepository.getClients();
    return clients
        .where((c) => c.active)
        .map((c) => VisitClientSummary(id: c.id, name: c.name))
        .toList();
  }

  @override
  Future<List<VisitFarmSummary>> listFarmsByClient(String clientId) async {
    final farms = await _clientsRepository.getFarms(clientId);
    return farms.map((f) => VisitFarmSummary(id: f.id, name: f.name)).toList();
  }

  @override
  Future<List<VisitFieldSummary>> listFieldsByFarm(String farmId) async {
    final fields = await _fieldRepository.getFieldsByFarmId(farmId);
    return fields
        .map((f) => VisitFieldSummary(id: f.id, name: f.name))
        .toList();
  }
}
