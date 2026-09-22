import '../state/map_state.dart';

/// Formata área em hectares para exibição conforme [unit].
String formatAreaFromHectares(double areaHa, AreaDisplayUnit unit) {
  switch (unit) {
    case AreaDisplayUnit.hectare:
      return '${areaHa.toStringAsFixed(3)} ha';
    case AreaDisplayUnit.squareMeter:
      return '${(areaHa * 10000).toStringAsFixed(0)} m²';
    case AreaDisplayUnit.alqueire:
      return '${(areaHa / 4.84).toStringAsFixed(3)} alq GO/MG';
  }
}

/// Sufixos curtos só para labels de polígono no mapa (menor largura no cull do flutter_map).
String _formatAreaShortForMapLabel(double areaHa, AreaDisplayUnit unit) {
  switch (unit) {
    case AreaDisplayUnit.hectare:
      return '${areaHa.toStringAsFixed(3)} ha';
    case AreaDisplayUnit.squareMeter:
      return '${(areaHa * 10000).toStringAsFixed(0)} m²';
    case AreaDisplayUnit.alqueire:
      return '${(areaHa / 4.84).toStringAsFixed(3)} alq';
  }
}

/// Label de polígono no mapa: nome do talhão + área (omitida se [areaHa] <= 0).
String buildTalhaoMapLabel(
  String name,
  double areaHa,
  AreaDisplayUnit unit,
) {
  if (areaHa <= 0) return name;
  final areaText = _formatAreaShortForMapLabel(areaHa, unit);
  return '$name\n$areaText';
}
