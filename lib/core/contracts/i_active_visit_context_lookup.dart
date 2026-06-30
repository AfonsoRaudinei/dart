/// Contexto editável herdado da visita ativa por fluxos abertos no mapa.
///
/// Mantém apenas dados necessários para pré-preenchimento. Os formulários
/// continuam livres para alterar os valores antes de salvar.
class ActiveVisitContext {
  const ActiveVisitContext({
    required this.sessionId,
    required this.clientId,
    this.clientName,
    this.farmId,
    this.farmName,
    this.fieldId,
    this.fieldName,
    this.fieldAreaHa,
    this.city,
    this.state,
  });

  final String sessionId;
  final String clientId;
  final String? clientName;
  final String? farmId;
  final String? farmName;
  final String? fieldId;
  final String? fieldName;
  final double? fieldAreaHa;
  final String? city;
  final String? state;

  String? get producerFarmLabel {
    final parts = [
      clientName,
      farmName,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' / ');
  }

  String? get locationLabel {
    final parts = [
      city,
      state,
    ].whereType<String>().where((value) => value.trim().isNotEmpty).toList();
    return parts.isEmpty ? null : parts.join(' - ');
  }
}

/// Resolve os dados cadastrados relacionados à sessão ativa.
abstract interface class IActiveVisitContextLookup {
  Future<ActiveVisitContext?> getActiveContext();
}
