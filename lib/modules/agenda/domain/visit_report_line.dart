/// Uma linha da lista "Relatórios desta visita" na agenda.
class VisitReportLine {
  const VisitReportLine({required this.fieldName, required this.farmName});

  final String fieldName;
  final String farmName;

  String get label => '$fieldName · $farmName';
}

String visitReportCountLabel(int count) {
  if (count <= 0) return 'Nenhum relatório nesta visita.';
  if (count == 1) return '1 relatório';
  return '$count relatórios';
}

/// Resolve o rótulo de um relatório feito na visita.
///
/// Nome do talhão e da fazenda da ocorrência vencem. Sem eles, usa o
/// talhão e a fazenda do evento.
VisitReportLine resolveVisitReportLine({
  String? resolvedFieldName,
  String? resolvedFarmName,
  String? eventFieldName,
  String? eventFarmName,
}) {
  return VisitReportLine(
    fieldName: _name(resolvedFieldName) ?? _name(eventFieldName) ?? 'Talhão',
    farmName: _name(resolvedFarmName) ?? _name(eventFarmName) ?? 'Fazenda',
  );
}

String? _name(String? value) {
  final trimmed = value?.trim() ?? '';
  if (trimmed.isEmpty || trimmed == '…') return null;
  if (trimmed == 'Fazenda não encontrada' ||
      trimmed == 'Talhão não encontrado') {
    return null;
  }
  return trimmed;
}
