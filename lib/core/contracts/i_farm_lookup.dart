/// DTO mínimo de fazenda para consumo fora de consultoria/.
/// Ownership: core/contracts/ — zona neutra sem imports de modules/.
class FarmSummary {
  final String id;
  final String clientId;
  final String name;
  final double? areaHa;

  const FarmSummary({
    required this.id,
    required this.clientId,
    required this.name,
    this.areaHa,
  });
}

/// Interface de lookup/persistência de fazendas para módulos desacoplados.
///
/// Consumidores: drawing/
/// Implementação concreta: consultoria/clients/infra/farm_lookup_adapter.dart
abstract interface class IFarmLookup {
  /// Retorna as fazendas de um cliente, ordenadas por nome.
  Future<List<FarmSummary>> getFarmsByClient(String clientId);

  /// Retorna uma fazenda por ID, ou null se não encontrada.
  Future<FarmSummary?> findById(String farmId);

  /// Salva uma fazenda para o cliente informado.
  Future<void> saveFarm({
    required String clientId,
    required String farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  });
}
