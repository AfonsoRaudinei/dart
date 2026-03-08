import '../../domain/repositories/i_clients_repository.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';

/// Adapter que conecta [ClientsRepository] (módulo consultoria) à interface
/// [IClientsRepository] definida pelo módulo drawing.
///
/// Esta é a única classe autorizada a cruzar a fronteira consultoria→drawing.
/// Vive em `drawing/infra/` para que o módulo drawing nunca importe diretamente
/// de consultoria, mantendo o fluxo correto de dependência.
class ClientsRepositoryAdapter implements IClientsRepository {
  final IClientLookup _clientLookup;
  final IFarmLookup _farmLookup;

  const ClientsRepositoryAdapter(this._clientLookup, this._farmLookup);

  @override
  Future<List<Client>> getClients() async {
    final clients = await _clientLookup.listAtivos();
    return clients
        .map(
          (c) => Client(
            id: c.id,
            name: c.name,
            photoPath: c.photoPath,
            active: c.active,
          ),
        )
        .toList();
  }

  @override
  Future<List<Farm>> getFarms(String clientId) async {
    final farms = await _farmLookup.getFarmsByClient(clientId);
    return farms
        .map(
          (f) => Farm(
            id: f.id,
            clientId: f.clientId,
            name: f.name,
            city: '',
            state: '',
            totalAreaHa: f.areaHa ?? 0.0,
          ),
        )
        .toList();
  }

  @override
  Future<void> saveFarm(Farm farm, String clientId) {
    return _farmLookup.saveFarm(
      clientId: clientId,
      farmId: farm.id,
      name: farm.name,
      city: farm.city,
      state: farm.state,
      areaHa: farm.totalAreaHa,
    );
  }
}
