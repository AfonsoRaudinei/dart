import '../../domain/repositories/i_clients_repository.dart';
import '../../../consultoria/clients/domain/client.dart';
import '../../../consultoria/clients/domain/agronomic_models.dart';
import '../../../consultoria/clients/data/clients_repository.dart';

/// Adapter que conecta [ClientsRepository] (módulo consultoria) à interface
/// [IClientsRepository] definida pelo módulo drawing.
///
/// Esta é a única classe autorizada a cruzar a fronteira consultoria→drawing.
/// Vive em `drawing/infra/` para que o módulo drawing nunca importe diretamente
/// de consultoria, mantendo o fluxo correto de dependência.
class ClientsRepositoryAdapter implements IClientsRepository {
  final ClientsRepository _inner;

  const ClientsRepositoryAdapter(this._inner);

  @override
  Future<List<Client>> getClients() => _inner.getClients();

  @override
  Future<List<Farm>> getFarms(String clientId) => _inner.getFarms(clientId);

  @override
  Future<void> saveFarm(Farm farm, String clientId) =>
      _inner.saveFarm(farm, clientId);
}
