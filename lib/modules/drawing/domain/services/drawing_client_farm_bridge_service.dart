import '../repositories/i_clients_repository.dart';

/// Serviço bridge entre o módulo drawing e dados de Cliente/Fazenda.
///
/// Encapsula o acesso ao [IClientsRepository], tornando o DrawingController
/// independente de ClientsRepository concreto em testes.
class DrawingClientFarmBridgeService {
  final IClientsRepository? _repository;

  const DrawingClientFarmBridgeService(this._repository);

  /// Retorna todos os clientes, ou lista vazia se repositório não configurado.
  Future<List<Client>> loadClients() async {
    if (_repository == null) return const [];
    return await _repository.getClients();
  }

  /// Retorna fazendas do cliente [clientId], ou lista vazia se não configurado.
  Future<List<Farm>> loadFarms(String clientId) async {
    if (_repository == null) return const [];
    return await _repository.getFarms(clientId);
  }

  /// Cria nova fazenda e recarrega a lista do cliente.
  ///
  /// Lança exceção se repositório não está configurado.
  Future<void> createFarm(
    String name,
    String clientId,
    String city,
    String state,
    double areaHa,
  ) async {
    if (_repository == null) return;
    final newFarm = Farm(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      city: city,
      state: state,
      totalAreaHa: areaHa,
      fields: [],
    );
    await _repository.saveFarm(newFarm, clientId);
  }
}
