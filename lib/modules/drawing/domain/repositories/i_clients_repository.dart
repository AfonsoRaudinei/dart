import '../../../consultoria/clients/domain/client.dart';
import '../../../consultoria/clients/domain/agronomic_models.dart';

/// Contrato mínimo de acesso a clientes e fazendas,
/// definido no módulo que consome (drawing), seguindo DIP.
///
/// O [ClientsRepository] do módulo consultoria implementa esta interface.
/// Em testes, basta criar um fake sem tocar no banco.
abstract interface class IClientsRepository {
  Future<List<Client>> getClients();
  Future<List<Farm>> getFarms(String clientId);
  Future<void> saveFarm(Farm farm, String clientId);
}
