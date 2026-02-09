import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/models/drawing_visual_style.dart';
import '../controllers/drawing_controller.dart';

/// Widget responsável por renderizar as camadas de desenho no mapa.
/// Ele escuta o controller e atualiza os polígonos conforme o estado.
class DrawingLayerWidget extends StatelessWidget {
  final DrawingController controller;
  final Function(DrawingFeature)? onFeatureTap;

  const DrawingLayerWidget({
    super.key,
    required this.controller,
    this.onFeatureTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final features = controller.features;
        final polygons = <Polygon>[];

        // 1. Renderiza features salvas
        for (final feature in features) {
          if (feature.geometry is DrawingPolygon) {
            final poly = feature.geometry as DrawingPolygon;

            // Converter coordenadas [lon, lat] para LatLng(lat, lon)
            // O primeiro anel é o outline externo
            if (poly.coordinates.isEmpty) continue;

            final outerRing = poly.coordinates.first
                .map((c) => LatLng(c[1], c[0]))
                .toList();

            // Os demais anéis são buracos
            final holes = poly.coordinates.length > 1
                ? poly.coordinates.skip(1).map((ring) {
                    return ring.map((c) => LatLng(c[1], c[0])).toList();
                  }).toList()
                : null;

            final isSelected = feature.id == controller.selectedFeature?.id;

            // Determina estilo
            // Se estiver selecionado no controller, sobrescreve o estilo base
            final style = isSelected ? FieldStyle.selected : feature.style;

            polygons.add(
              Polygon(
                points: outerRing,
                holePointsList: holes,
                color: style.fillColor.withValues(alpha: style.fillOpacity),
                borderColor: style.borderColor,
                borderStrokeWidth: style.borderWidth,
                pattern: style.isDashed
                    ? StrokePattern.dashed(segments: [10, 5])
                    : const StrokePattern.solid(),
                label: feature.properties.nome,
                labelStyle: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ), // TODO: Usar tema SoloForteTextStyles
                rotateLabel: true,
              ),
            );
          }
        }

        // 2. Renderiza sketch manual (desenho em progresso)
        final liveGeo = controller.liveGeometry;
        if (liveGeo is DrawingPolygon && liveGeo.coordinates.isNotEmpty) {
          final outerRing = liveGeo.coordinates.first
              .map((c) => LatLng(c[1], c[0]))
              .toList();

          polygons.add(
            Polygon(
              points: outerRing,
              color: Colors.blue.withValues(alpha: 0.1),
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
              pattern: StrokePattern.dashed(segments: [10, 5]),
            ),
          );
        }

        return PolygonLayer(polygons: polygons);
      },
    );
  }
}
