// Contrato DIP para acesso a dados de talhão sem importar drawing/ diretamente.
// Zona: core/contracts/ — acessível por todos os bounded contexts.

abstract class IFieldLookup {
  Future<FieldSummary?> findById(String fieldId);
  Future<List<FieldSummary>> listByFarmId(String farmId);
}

class FieldSummary {
  final String id;
  final String name;
  final String farmId;
  final double? areaHa;

  final List<double>? bbox; // [minLon, minLat, maxLon, maxLat]

  const FieldSummary({
    required this.id,
    required this.name,
    required this.farmId,
    this.areaHa,
    this.bbox,
  });
}
