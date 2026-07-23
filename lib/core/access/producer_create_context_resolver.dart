import '../contracts/i_active_visit_context_lookup.dart';
import '../contracts/i_client_lookup.dart';
import '../contracts/i_producer_property_gateway.dart';

/// Resolve contexto de criação (client/fazenda/talhão) para o perfil produtor.
///
/// Usa [IProducerPropertyGateway] (ADR-040) — sem import de `modules/produtor`.
class ProducerCreateContextResolver {
  const ProducerCreateContextResolver._();

  static Future<ActiveVisitContext?> asVisitContext(
    IProducerPropertyGateway gateway, {
    String? preferredFarmId,
    String? preferredFieldId,
  }) async {
    try {
      final property = await gateway.loadOwnProperty();
      final farm = _pickFarm(property.farms, preferredFarmId);
      final field = _pickField(farm?.fields ?? const [], preferredFieldId);

      return ActiveVisitContext(
        sessionId: 'producer-own',
        clientId: property.clientId,
        clientName: property.name,
        farmId: farm?.id,
        farmName: farm?.name,
        fieldId: field?.id,
        fieldName: field?.name,
        fieldAreaHa: field?.areaHa,
        city: farm?.city,
        state: farm?.state,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<ClientSummary?> asClientSummary(
    IProducerPropertyGateway gateway,
  ) async {
    try {
      final property = await gateway.loadOwnProperty();
      final areaTotal = property.farms.fold<double>(
        0,
        (sum, farm) => sum + farm.areaHa,
      );
      return ClientSummary(
        id: property.clientId,
        name: property.name,
        active: true,
        areaTotal: areaTotal,
      );
    } catch (_) {
      return null;
    }
  }

  static ProducerFarmSnapshot? _pickFarm(
    List<ProducerFarmSnapshot> farms,
    String? preferredFarmId,
  ) {
    if (farms.isEmpty) return null;
    if (preferredFarmId != null) {
      for (final farm in farms) {
        if (farm.id == preferredFarmId) return farm;
      }
    }
    return farms.first;
  }

  static ProducerFieldSnapshot? _pickField(
    List<ProducerFieldSnapshot> fields,
    String? preferredFieldId,
  ) {
    if (fields.isEmpty) return null;
    if (preferredFieldId != null) {
      for (final field in fields) {
        if (field.id == preferredFieldId) return field;
      }
    }
    return fields.first;
  }
}
