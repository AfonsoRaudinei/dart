/// Nome de fazenda ou talhão no relatório de visita.
///
/// Sem nome resolvido, devolve [unidentified] em vez do UUID.
String resolveVisitPlaceName({
  String? lookedUpName,
  required String unidentified,
}) {
  final name = lookedUpName?.trim() ?? '';
  if (name.isEmpty) return unidentified;
  return name;
}
