import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/domain/talhao_condicao.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/modules/map/presentation/widgets/visit_sheet.dart';

/// Talhões da fazenda para o check-in: polígono desenhado pode receber condição.
Future<List<VisitTalhaoOption>> loadVisitTalhaoOptions(
  WidgetRef ref,
  String farmId,
) async {
  final linked = await ref.read(farmLinkedFieldsProvider(farmId).future);
  final features = ref.read(drawingControllerProvider).features;
  final corById = {
    for (final feature in features) feature.id: feature.properties.cor,
  };

  return [
    for (final field in linked)
      VisitTalhaoOption(
        id: field.id,
        name: field.name,
        areaHa: field.areaHa,
        canRate: field.isDrawing,
        condicao: TalhaoCondicao.resolve(
          field.isDrawing ? corById[field.id] : null,
        ),
        centroid: visitTalhaoCentroid(
          field.boundsVertices.isNotEmpty
              ? field.boundsVertices
              : field.vertices,
        ),
      ),
  ];
}

/// Grava a condição e recarrega os polígonos para o mapa mudar na hora.
Future<void> applyVisitTalhaoCondicao(
  WidgetRef ref, {
  required String fieldId,
  required TalhaoCondicao condicao,
}) async {
  await ref
      .read(iDrawingFieldWriterProvider)
      .updateFieldAvaliacao(fieldId: fieldId, condicao: condicao);
  await ref.read(drawingControllerProvider).loadFeatures();
}

LatLng? visitTalhaoCentroid(List<LatLng> points) {
  if (points.isEmpty) return null;
  var lat = 0.0;
  var lng = 0.0;
  for (final point in points) {
    lat += point.latitude;
    lng += point.longitude;
  }
  final count = points.length;
  return LatLng(lat / count, lng / count);
}
