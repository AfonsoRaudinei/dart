import '../domain/cultura_tipo.dart';
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

String formatCulturaMaterialLine(String? cultura, String? material) {
  final crop = CulturaTipo.displayLabel(cultura);
  final seed = material?.trim() ?? '';
  if (crop.isEmpty) return seed;
  if (seed.isEmpty) return crop;
  return '$crop · $seed';
}

/// Label de polígono no mapa: nome, cultura/material e área conforme [prefs].
String buildTalhaoMapLabel(
  String name,
  double areaHa,
  AreaDisplayUnit unit, {
  TalhaoMapLabelPrefs prefs = const TalhaoMapLabelPrefs(),
  String? cultura,
  String? material,
}) {
  if (prefs.isHidden) return '';

  final lines = <String>[];
  final trimmedName = name.trim();
  if (prefs.showName && trimmedName.isNotEmpty) {
    lines.add(trimmedName);
  }
  if (prefs.showCultura) {
    final cropLine = formatCulturaMaterialLine(cultura, material);
    if (cropLine.isNotEmpty) lines.add(cropLine);
  }
  if (prefs.showArea && areaHa > 0) {
    lines.add(_formatAreaShortForMapLabel(areaHa, unit));
  }
  return lines.join('\n');
}
