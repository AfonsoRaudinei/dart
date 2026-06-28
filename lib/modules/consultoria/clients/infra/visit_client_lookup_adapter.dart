import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import 'package:soloforte_app/core/contracts/visit_client_hierarchy.dart';
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

  @override
  Future<VisitClientHierarchy?> getClientHierarchy(String clientId) async {
    final client = await _clientsRepository.getClientById(clientId);
    if (client == null) return null;

    final farms = await _clientsRepository.getFarms(clientId);
    final farmSummaries = <VisitFarmDetailSummary>[];

    for (final farm in farms) {
      final fields = await _fieldRepository.getFieldsByFarmId(farm.id);
      farmSummaries.add(
        VisitFarmDetailSummary(
          id: farm.id,
          name: farm.name,
          fields: fields
              .map(
                (field) => VisitFieldDetailSummary(
                  id: field.id,
                  name: field.name,
                  areaHa: field.areaHa,
                ),
              )
              .toList(growable: false),
        ),
      );
    }

    return VisitClientHierarchy(
      id: client.id,
      name: client.name,
      farms: farmSummaries,
    );
  }
}
