/// Hierarquia cliente → fazendas → talhões para fluxos de visita no mapa.
/// Zona neutra — ADR-045.
class VisitFieldDetailSummary {
  const VisitFieldDetailSummary({
    required this.id,
    required this.name,
    this.areaHa,
  });

  final String id;
  final String name;
  final double? areaHa;
}

class VisitFarmDetailSummary {
  const VisitFarmDetailSummary({
    required this.id,
    required this.name,
    required this.fields,
  });

  final String id;
  final String name;
  final List<VisitFieldDetailSummary> fields;
}

class VisitClientHierarchy {
  const VisitClientHierarchy({
    required this.id,
    required this.name,
    required this.farms,
  });

  final String id;
  final String name;
  final List<VisitFarmDetailSummary> farms;
}
