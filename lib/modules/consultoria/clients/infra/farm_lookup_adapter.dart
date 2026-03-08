import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import '../data/clients_repository.dart';
import '../domain/agronomic_models.dart' as agronomic;

/// Implementação concreta de IFarmLookup.
/// Vive em consultoria/clients/infra/ — dono dos dados de fazenda.
/// Registrado via ProviderScope.overrides em main.dart.
class FarmLookupAdapter implements IFarmLookup {
  final ClientsRepository _repository;

  const FarmLookupAdapter(this._repository);

  @override
  Future<List<FarmSummary>> getFarmsByClient(String clientId) async {
    final farms = await _repository.getFarms(clientId);
    return farms
        .map(
          (f) => FarmSummary(
            id: f.id,
            clientId: clientId,
            name: f.name,
            areaHa: f.totalAreaHa,
          ),
        )
        .toList();
  }

  @override
  Future<FarmSummary?> findById(String farmId) async {
    // ClientsRepository não expõe getFarmById.
    // Fallback seguro: varre farms por cliente.
    final clients = await _repository.getClients();
    for (final client in clients) {
      final farms = await _repository.getFarms(client.id);
      for (final farm in farms) {
        if (farm.id == farmId) {
          return FarmSummary(
            id: farm.id,
            clientId: client.id,
            name: farm.name,
            areaHa: farm.totalAreaHa,
          );
        }
      }
    }
    return null;
  }

  @override
  Future<void> saveFarm({
    required String clientId,
    required String farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {
    final farm = agronomic.Farm(
      id: farmId,
      name: name,
      city: city,
      state: state,
      totalAreaHa: areaHa,
      fields: const [],
    );
    await _repository.saveFarm(farm, clientId);
  }
}
