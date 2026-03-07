import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/models/drawing_visual_style.dart';
import '../controllers/drawing_controller.dart';

/// Widget responsável por renderizar as camadas de desenho no mapa.
/// Ele escuta o controller e atualiza os polígonos conforme o estado.
///
/// ⚡ OTIMIZADO: Usa cache para evitar reconstrução de polígonos
class DrawingLayerWidget extends StatefulWidget {
  final DrawingController controller;
  final Function(DrawingFeature)? onFeatureTap;
  final VoidCallback? onDrawingComplete;

  const DrawingLayerWidget({
    super.key,
    required this.controller,
    this.onFeatureTap,
    this.onDrawingComplete,
  });

  @override
  State<DrawingLayerWidget> createState() => _DrawingLayerWidgetState();
}

class _DrawingLayerWidgetState extends State<DrawingLayerWidget> {
  // ⚡ CACHE: Evita reconstruir polígonos quando features não mudaram
  List<Polygon>? _cachedPolygons;
  List<Polyline>? _cachedPolylines;
  List<Marker>? _cachedMarkers;
  List<DrawingFeature>? _lastFeatures;
  String? _lastSelectedId;
  DrawingGeometry? _lastLiveGeo;
  Set<int>? _lastIntersectingIndices;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final features = widget.controller.features;
        final selectedId = widget.controller.selectedFeature?.id;
        final liveGeo = widget.controller.liveGeometry;
        final intersectingIndices = widget.controller.intersectingSegmentIndices;

        // ⚡ CACHE CHECK: Só reconstrói se algo mudou
        final needsRebuild =
            _lastFeatures != features ||
            _lastSelectedId != selectedId ||
            _lastLiveGeo != liveGeo ||
            _lastIntersectingIndices != intersectingIndices;

        if (!needsRebuild &&
            _cachedPolygons != null &&
            _cachedPolylines != null &&
            _cachedMarkers != null) {
          return Stack(
            children: [
              PolygonLayer(polygons: _cachedPolygons!),
              PolylineLayer(polylines: _cachedPolylines!),
              if (_cachedMarkers!.isNotEmpty)
                MarkerLayer(markers: _cachedMarkers!),
            ],
          );
        }

        // Atualizar cache vars
        _lastFeatures = features;
        _lastSelectedId = selectedId;
        _lastLiveGeo = liveGeo;
        _lastIntersectingIndices = Set.from(intersectingIndices);

        final polygons = <Polygon>[];
        final polylines = <Polyline>[];
        final markers = <Marker>[];

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

            final isSelected = feature.id == selectedId;

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
                    ? StrokePattern.dashed(segments: const [10, 5])
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
        if (liveGeo is DrawingPolygon && liveGeo.coordinates.isNotEmpty) {
          final outerRing = liveGeo.coordinates.first
              .map((c) => LatLng(c[1], c[0]))
              .toList();

          polygons.add(
            Polygon(
              points: outerRing,
              color: Colors.white.withValues(alpha: 0.2), // Mais claro
              borderColor: Colors.white, // Alto contraste
              borderStrokeWidth: 3, // Mais visível
              pattern: const StrokePattern.dotted(), // Estilo "em construção"
            ),
          );

          // Renderizar vértices durante o desenho (feedback visual imediato)
          for (int i = 0; i < outerRing.length; i++) {
            final point = outerRing[i];
            final isStart = i == 0;
            final size = isStart ? 18.0 : 14.0;
            
            // Desenhar linha de erro para segmentos que cruzam
            if (intersectingIndices.contains(i)) {
              final nextPoint = outerRing[i < outerRing.length - 1 ? i + 1 : 0];
              polylines.add(
                Polyline(
                  points: [point, nextPoint],
                  color: Colors.red,
                  strokeWidth: 4,
                )
              );
            }

            markers.add(
              Marker(
                point: point,
                width: size,
                height: size,
                child: GestureDetector(
                  onTap: (isStart && !widget.controller.hasSelfIntersection) 
                      ? widget.onDrawingComplete 
                      : null,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isStart && widget.controller.hasSelfIntersection ? Colors.red.withValues(alpha: 0.5) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isStart ? (widget.controller.hasSelfIntersection ? Colors.red : Colors.green) : Colors.black26,
                        width: isStart ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
                alignment: Alignment.center,
              ),
            );
          }
        }

        // ⚡ Salvar cache
        _cachedPolygons = polygons;
        _cachedPolylines = polylines;
        _cachedMarkers = markers;

        return Stack(
          children: [
            PolygonLayer(polygons: polygons),
            PolylineLayer(polylines: polylines),
            if (markers.isNotEmpty) MarkerLayer(markers: markers),
          ],
        );
      },
    );
  }
}
