/// DTO mínimo de cliente para início de visita.
class VisitClientSummary {
  final String id;
  final String name;

  const VisitClientSummary({required this.id, required this.name});
}

/// DTO mínimo de fazenda para início de visita.
class VisitFarmSummary {
  final String id;
  final String name;

  const VisitFarmSummary({required this.id, required this.name});
}

/// DTO mínimo de talhão/área para início de visita.
class VisitFieldSummary {
  final String id;
  final String name;

  const VisitFieldSummary({required this.id, required this.name});
}

/// Contrato de lookup para fluxo de abertura de visita.
/// Zona neutra em core/contracts/ para evitar imports cross-module em presentation.
abstract interface class IVisitClientLookup {
  Future<List<VisitClientSummary>> listActiveClients();

  Future<List<VisitFarmSummary>> listFarmsByClient(String clientId);

  Future<List<VisitFieldSummary>> listFieldsByFarm(String farmId);
}
