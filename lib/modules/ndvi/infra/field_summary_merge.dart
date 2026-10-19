import 'package:soloforte_app/core/contracts/i_field_lookup.dart';

/// Geometria usada no fetch remoto NDVI.
///
/// Alinha com a ficha da fazenda (`farmLinkedFieldsProvider`): cadastro
/// consultoria primeiro; drawing só complementa ids ausentes ou geometria vazia.
bool fieldSummaryHasNdviOrigin(FieldSummary summary) {
  final bbox = summary.bbox;
  if (bbox != null && bbox.length == 4) {
    final lonSpan = (bbox[2] - bbox[0]).abs();
    final latSpan = (bbox[3] - bbox[1]).abs();
    if (lonSpan > 0 && latSpan > 0) return true;
  }
  final geometry = summary.geometry;
  return geometry != null && geometry.trim().isNotEmpty;
}

/// [drawing] = primary (mapa/drawings). [consultoria] = fallback (SQLite).
FieldSummary mergeFieldSummariesForNdvi({
  required FieldSummary drawing,
  required FieldSummary consultoria,
}) {
  final consultoriaOrigin = fieldSummaryHasNdviOrigin(consultoria);
  final drawingOrigin = fieldSummaryHasNdviOrigin(drawing);

  final FieldSummary geoSource;
  if (consultoriaOrigin) {
    geoSource = consultoria;
  } else if (drawingOrigin) {
    geoSource = drawing;
  } else {
    geoSource = consultoria;
  }

  return FieldSummary(
    id: drawing.id,
    name: drawing.name.trim().isNotEmpty ? drawing.name : consultoria.name,
    farmId: drawing.farmId.trim().isNotEmpty
        ? drawing.farmId
        : consultoria.farmId,
    areaHa: drawing.areaHa ?? consultoria.areaHa,
    crop: drawing.crop ?? consultoria.crop,
    harvest: drawing.harvest ?? consultoria.harvest,
    bbox: geoSource.bbox,
    geometry: geoSource.geometry,
  );
}

List<FieldSummary> mergeFieldSummariesByFarmId({
  required List<FieldSummary> drawingFields,
  required List<FieldSummary> consultoriaFields,
}) {
  final byId = <String, FieldSummary>{};

  for (final consultoria in consultoriaFields) {
    if (consultoria.id.isEmpty) continue;
    byId[consultoria.id] = consultoria;
  }

  for (final drawing in drawingFields) {
    if (drawing.id.isEmpty) continue;
    final existing = byId[drawing.id];
    if (existing == null) {
      byId[drawing.id] = drawing;
      continue;
    }
    byId[drawing.id] = mergeFieldSummariesForNdvi(
      drawing: drawing,
      consultoria: existing,
    );
  }

  return byId.values.toList();
}
