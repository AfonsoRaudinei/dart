import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/drawing_state.dart';
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
  static const Color _manualOutlineColor = Colors.white;
  static const Color _manualOutlineHalo = Color(0xCC111111);
  static const Color _gpsOutlineHalo = Color(0xB3000000);

  // ⚡ CACHE: Evita reconstruir polígonos quando features não mudaram
  List<Polygon>? _cachedPolygons;
  List<Polyline>? _cachedPolylines;
  List<Marker>? _cachedMarkers;
  List<DrawingFeature>? _lastFeatures;
  String? _lastSelectedId;
  Set<String>? _lastSelectedIds;
  DrawingGeometry? _lastLiveGeo;
  List<LatLng>? _lastCurrentPoints;
  Set<int>? _lastIntersectingIndices;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final features = widget.controller.features;
        final selectedId = widget.controller.selectedFeature?.id;
        final selectedIds = widget.controller.selectedFeatureIds;
        final liveGeo = widget.controller.liveGeometry;
        final currentPoints = widget.controller.currentPoints;
        final intersectingIndices =
            widget.controller.intersectingSegmentIndices;

        // ⚡ CACHE CHECK: Só reconstrói se algo mudou
        final needsRebuild =
            _lastFeatures != features ||
            _lastSelectedId != selectedId ||
            !_sameIds(_lastSelectedIds, selectedIds) ||
            _lastLiveGeo != liveGeo ||
            !_samePoints(_lastCurrentPoints, currentPoints) ||
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
        _lastSelectedIds = Set.from(selectedIds);
        _lastLiveGeo = liveGeo;
        _lastCurrentPoints = List.of(currentPoints);
        _lastIntersectingIndices = Set.from(intersectingIndices);

        final polygons = <Polygon>[];
        final polylines = <Polyline>[];
        final markers = <Marker>[];

        // 1. Renderiza features salvas
        for (final feature in features) {
          final geometry = feature.geometry;
          final parts = geometry is DrawingPolygon
              ? [geometry.coordinates]
              : geometry is DrawingMultiPolygon
              ? geometry.coordinates
              : const <List<List<List<double>>>>[];
          final isSelected =
              feature.id == selectedId || selectedIds.contains(feature.id);
          final style = isSelected ? FieldStyle.selected : feature.style;

          for (var index = 0; index < parts.length; index++) {
            final rings = parts[index];
            if (rings.isEmpty) continue;
            polygons.add(
              _polygonFromRings(
                rings,
                color: style.fillColor.withValues(alpha: style.fillOpacity),
                borderColor: style.borderColor,
                borderStrokeWidth: style.borderWidth,
                pattern: style.isDashed
                    ? StrokePattern.dashed(segments: const [10, 5])
                    : const StrokePattern.solid(),
                label: index == 0 ? feature.properties.nome : null,
              ),
            );
          }
        }

        // 2. Renderiza sketch em progresso (manual ou GPS Walk)
        if (liveGeo == null && currentPoints.length == 1) {
          markers.add(_vertexMarker(currentPoints.single, index: 0));
        }

        if (liveGeo is DrawingPolygon || liveGeo is DrawingMultiPolygon) {
          // GPS Walk usa estilo vermelho; desenho manual usa branco
          final isGpsWalk =
              widget.controller.currentState == DrawingState.gpsTracking;
          final isImportPreview =
              widget.controller.currentState == DrawingState.importPreview ||
              widget.controller.interactionMode ==
                  DrawingInteraction.importPreview;

          final parts = liveGeo is DrawingPolygon
              ? [liveGeo.coordinates]
              : (liveGeo as DrawingMultiPolygon).coordinates;
          for (final rings in parts) {
            if (rings.isEmpty) continue;
            final outerRing = _toLatLngRing(rings.first);
            if (outerRing.length >= 2) {
              final outlineColor = isGpsWalk ? Colors.red : _manualOutlineColor;
              final haloColor = isGpsWalk
                  ? _gpsOutlineHalo
                  : _manualOutlineHalo;

              polylines.add(
                Polyline(
                  points: outerRing,
                  color: haloColor,
                  strokeWidth: isGpsWalk ? 7 : 8,
                ),
              );
              polylines.add(
                Polyline(
                  points: outerRing,
                  color: outlineColor,
                  strokeWidth: isGpsWalk ? 3 : 4,
                  pattern: isGpsWalk
                      ? const StrokePattern.solid()
                      : const StrokePattern.dotted(),
                ),
              );
            }
            polygons.add(
              _polygonFromRings(
                rings,
                color: isGpsWalk
                    ? Colors.red.withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.2),
                borderColor: isGpsWalk ? Colors.red : Colors.white,
                borderStrokeWidth: isGpsWalk ? 2.0 : 3,
                pattern: isGpsWalk
                    ? const StrokePattern.solid()
                    : const StrokePattern.dotted(),
              ),
            );
          }

          // Renderizar vértices apenas no desenho manual/GPS.
          // Em importPreview exibimos somente o polígono para evitar "pontos soltos".
          if (!isImportPreview &&
              liveGeo is DrawingPolygon &&
              liveGeo.coordinates.isNotEmpty) {
            final outerRing = _toLatLngRing(liveGeo.coordinates.first);
            for (int i = 0; i < outerRing.length; i++) {
              final point = outerRing[i];
              final isStart = i == 0;
              final size = isStart ? 18.0 : 14.0;

              // Desenhar linha de erro para segmentos que cruzam
              if (intersectingIndices.contains(i)) {
                final nextPoint =
                    outerRing[i < outerRing.length - 1 ? i + 1 : 0];
                polylines.add(
                  Polyline(
                    points: [point, nextPoint],
                    color: Colors.red,
                    strokeWidth: 4,
                  ),
                );
              }

              markers.add(_vertexMarker(point, index: i, size: size));
            }
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

  bool _sameIds(Set<String>? previous, Set<String> current) {
    return previous != null &&
        previous.length == current.length &&
        previous.containsAll(current);
  }

  bool _samePoints(List<LatLng>? previous, List<LatLng> current) {
    if (previous == null || previous.length != current.length) return false;
    for (var i = 0; i < current.length; i++) {
      if (previous[i] != current[i]) return false;
    }
    return true;
  }

  Marker _vertexMarker(LatLng point, {required int index, double? size}) {
    final isStart = index == 0;
    final markerSize = size ?? (isStart ? 18.0 : 14.0);
    return Marker(
      point: point,
      width: markerSize,
      height: markerSize,
      child: GestureDetector(
        key: Key('drawing_point_$index'),
        onTap: (isStart && !widget.controller.hasSelfIntersection)
            ? widget.onDrawingComplete
            : null,
        child: Container(
          decoration: BoxDecoration(
            color: isStart && widget.controller.hasSelfIntersection
                ? Colors.red.withValues(alpha: 0.5)
                : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isStart
                  ? (widget.controller.hasSelfIntersection
                        ? Colors.red
                        : Colors.green)
                  : Colors.black26,
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
    );
  }

  Polygon _polygonFromRings(
    List<List<List<double>>> rings, {
    required Color color,
    required Color borderColor,
    required double borderStrokeWidth,
    required StrokePattern pattern,
    String? label,
  }) {
    final holes = rings.length > 1
        ? rings.skip(1).map(_toLatLngRing).toList()
        : null;
    return Polygon(
      points: _toLatLngRing(rings.first),
      holePointsList: holes,
      color: color,
      borderColor: borderColor,
      borderStrokeWidth: borderStrokeWidth,
      pattern: pattern,
      label: label,
      labelStyle: const TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
      rotateLabel: true,
    );
  }

  List<LatLng> _toLatLngRing(List<List<double>> ring) =>
      ring.map((c) => LatLng(c[1], c[0])).toList();
}
