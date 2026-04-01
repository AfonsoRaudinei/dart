// lib/core/contracts/i_field_lookup.dart
//
// Contrato neutro — acessível por todos os bounded contexts.
// ADR-022 (origem) + ADR-024 (expansão: geometry + listAll)
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// RETROCOMPATÍVEL: campos existentes mantidos; novos campos são nullable.

/// DTO mínimo de talhão para consumo por módulos externos.
/// NÃO é espelho completo de Talhao — apenas os campos necessários
/// para ndvi/, drawing/ e geofence (visitas/).
class FieldSummary {
  const FieldSummary({
    required this.id,
    required this.name,
    required this.farmId,
    this.areaHa,
    this.bbox,
    this.geometry,
  });

  final String id;
  final String name;
  final String farmId;
  final double? areaHa;

  // [minLon, minLat, maxLon, maxLat]
  final List<double>? bbox;

  /// GeoJSON serializado como String (jsonEncode de Map<String,dynamic>).
  /// Nullable para retrocompatibilidade — adapters existentes podem omitir.
  /// ADR-024
  final String? geometry;
}

/// Contrato de consulta de dados de talhão para módulos externos.
/// Implementações:
///   drawing/infra/field_lookup_adapter.dart (para ndvi/ e drawing/)
///   consultoria/fields/infra/field_lookup_geofence_adapter.dart (para visitas/)
/// ADR-022, ADR-024
abstract interface class IFieldLookup {
  Future<FieldSummary?> findById(String fieldId);
  Future<List<FieldSummary>> listByFarmId(String farmId);

  /// Retorna todos os talhões do usuário.
  /// Adicionado em ADR-024 — necessário para geofence_controller.
  Future<List<FieldSummary>> listAll();
}

