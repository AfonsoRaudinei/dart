import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/core/utils/area_display_format.dart';
import '../../domain/drawing_state.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/models/drawing_visual_style.dart';
import '../controllers/drawing_controller.dart';

/// Widget responsável por renderizar as camadas de desenho no mapa.
class DrawingLayerWidget extends ConsumerStatefulWidget {
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
  ConsumerState<DrawingLayerWidget> createState() => _DrawingLayerWidgetState();
}

class _DrawingLayerWidgetState extends ConsumerState<DrawingLayerWidget> {
  static const Color _manualOutlineColor = Colors.white;
  static const Color _manualOutlineHalo = Color(0xCC111111);
  static const Color _gpsOutlineHalo = Color(0xB3000000);

  /// Azul Samsung (`PremiumTokens.blackAccentPrimary`) e a variante mais escura.
  static const Color _testFill = Color(0xFF1428A0);
  static const Color _testBorder = Color(0xFF0F1E7A);

  List<Polygon>? _cachedPolygons;
  List<Polyline>? _cachedPolylines;
  List<Marker>? _cachedMarkers;
  List<DrawingFeature>? _lastFeatures;
  String? _lastSelectedId;
  Set<String>? _lastSelectedIds;
  DrawingGeometry? _lastLiveGeo;
  List<LatLng>? _lastCurrentPoints;
  List<LatLng>? _lastFreehandTrail;
  LatLng? _lastPivotCenter;
  LatLng? _lastPivotEdge;
  bool? _lastFreehandActive;
  DrawingTool? _lastTool;
  Set<int>? _lastIntersectingIndices;
  bool _lastHoleCut = false;
  bool _lastSketchingTest = false;
  AreaDisplayUnit? _lastAreaUnit;
  TalhaoMapLabelPrefs? _lastLabelPrefs;
  String? _lastNdviOverlayId;
  bool _lastNdviCover = false;
  DrawingState? _lastDrawingState;
  List<LatLng>? _lastGpsVertices;
  bool _lastEditingPivot = false;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final areaUnit = ref.watch(areaDisplayUnitProvider);
        final labelPrefs = ref.watch(talhaoMapLabelPrefsProvider);
        final ndviOverlayId = ref.watch(mapNdviOverlayFieldIdProvider);
        final ndviSummary = ref
            .watch(mapNdviOverlaySummaryProvider)
            .asData
            ?.value;
        final ndviCover = mapNdviSummaryCoversField(ndviSummary);
        final features = widget.controller.features;
        final selectedId = widget.controller.selectedFeature?.id;
        final selectedIds = widget.controller.selectedFeatureIds;
        final liveGeo = widget.controller.liveGeometry;
        final currentPoints = widget.controller.currentPoints;
        final freehandTrail = widget.controller.freehandTrail;
        final currentTool = widget.controller.currentTool;
        final pivotCenter = widget.controller.pivotCenter;
        final pivotEdge = widget.controller.pivotEdgePoint;
        final editingPivot = widget.controller.isEditingPivot;
        final isFreehandStrokeActive = widget.controller.isFreehandStrokeActive;
        final intersectingIndices =
            widget.controller.intersectingSegmentIndices;
        final currentState = widget.controller.currentState;
        final gpsVertices = widget.controller.gpsVertices;
        final holeCutActive = widget.controller.isCuttingHole;
        final holeCutFeatureId = widget.controller.holeCutFeatureId;
        final sketchingTest = widget.controller.isSketchingTest;
        final sketchVerticesOwnedByEditLayer =
            currentTool == DrawingTool.polygon &&
            (currentState == DrawingState.drawing ||
                currentState == DrawingState.armed) &&
            currentPoints.isNotEmpty;
        final hideDecorativeVertexMarkers =
            sketchVerticesOwnedByEditLayer ||
            currentState == DrawingState.editing;

        final needsRebuild =
            _lastFeatures != features ||
            _lastSelectedId != selectedId ||
            !_sameIds(_lastSelectedIds, selectedIds) ||
            _lastLiveGeo != liveGeo ||
            !_samePoints(_lastCurrentPoints, currentPoints) ||
            _lastIntersectingIndices != intersectingIndices ||
            _lastTool != currentTool ||
            _lastHoleCut != holeCutActive ||
            _lastSketchingTest != sketchingTest ||
            !_samePoints(_lastFreehandTrail, freehandTrail) ||
            _lastPivotCenter != pivotCenter ||
            _lastPivotEdge != pivotEdge ||
            _lastFreehandActive != isFreehandStrokeActive ||
            _lastAreaUnit != areaUnit ||
            _lastLabelPrefs != labelPrefs ||
            _lastNdviOverlayId != ndviOverlayId ||
            _lastNdviCover != ndviCover ||
            _lastDrawingState != currentState ||
            _lastEditingPivot != editingPivot ||
            !_samePoints(_lastGpsVertices, gpsVertices);

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

        _lastFeatures = features;
        _lastSelectedId = selectedId;
        _lastSelectedIds = Set.from(selectedIds);
        _lastLiveGeo = liveGeo;
        _lastCurrentPoints = List.of(currentPoints);
        _lastFreehandTrail = List.of(freehandTrail);
        _lastPivotCenter = pivotCenter;
        _lastPivotEdge = pivotEdge;
        _lastFreehandActive = isFreehandStrokeActive;
        _lastTool = currentTool;
        _lastHoleCut = holeCutActive;
        _lastSketchingTest = sketchingTest;
        _lastIntersectingIndices = Set.from(intersectingIndices);
        _lastAreaUnit = areaUnit;
        _lastLabelPrefs = labelPrefs;
        _lastNdviOverlayId = ndviOverlayId;
        _lastNdviCover = ndviCover;
        _lastDrawingState = currentState;
        _lastEditingPivot = editingPivot;
        _lastGpsVertices = List.of(gpsVertices);

        final polygons = <Polygon>[];
        final polylines = <Polyline>[];
        final markers = <Marker>[];
        final holeCutPreview = holeCutActive
            ? widget.controller.holeCutPreviewGeometry
            : null;

        final editingThisFeature =
            currentState == DrawingState.editing && liveGeo != null;
        final orderedFeatures = <DrawingFeature>[
          for (final feature in features)
            if (feature.properties.tipo != DrawingType.teste) feature,
          for (final feature in features)
            if (feature.properties.tipo == DrawingType.teste) feature,
        ];
        for (final feature in orderedFeatures) {
          final geometry = editingThisFeature && feature.id == selectedId
              ? liveGeo
              : holeCutActive &&
                    feature.id == holeCutFeatureId &&
                    holeCutPreview != null
              ? holeCutPreview
              : feature.geometry;
          final parts = geometry is DrawingPolygon
              ? [geometry.coordinates]
              : geometry is DrawingMultiPolygon
              ? geometry.coordinates
              : const <List<List<List<double>>>>[];
          final isSelected =
              feature.id == selectedId || selectedIds.contains(feature.id);
          final baseStyle = feature.style;
          final style = isSelected
              ? FieldStyle(
                  fillColor: baseStyle.fillColor,
                  borderColor: FieldStyle.selected.borderColor,
                  borderWidth: FieldStyle.selected.borderWidth,
                  isDashed: baseStyle.isDashed,
                  fillOpacity: baseStyle.fillOpacity,
                )
              : baseStyle;
          final ndviActiveForField =
              ndviOverlayId != null && feature.id == ndviOverlayId;
          final hideNdviFill = ndviCover && ndviActiveForField;

          for (var index = 0; index < parts.length; index++) {
            final rings = parts[index];
            if (rings.isEmpty) continue;
            final label = index == 0
                ? buildTalhaoMapLabel(
                    feature.properties.nome,
                    feature.properties.areaHa,
                    areaUnit,
                    prefs: labelPrefs,
                    cultura: feature.properties.cultura,
                    material: feature.properties.material,
                  )
                : null;
            polygons.add(
              _polygonFromRings(
                rings,
                color: hideNdviFill
                    ? const Color(0x00000000)
                    : style.fillColor.withValues(alpha: style.fillOpacity),
                borderColor: style.borderColor,
                borderStrokeWidth: style.borderWidth,
                pattern: style.isDashed
                    ? StrokePattern.dashed(segments: const [10, 5])
                    : const StrokePattern.solid(),
                label: ndviActiveForField
                    ? null
                    : (label != null && label.isEmpty ? null : label),
              ),
            );
          }
        }

        if (!hideDecorativeVertexMarkers &&
            currentTool == DrawingTool.polygon &&
            liveGeo == null &&
            currentPoints.length == 1) {
          markers.add(_vertexMarker(currentPoints.single, index: 0));
        }

        if ((currentTool == DrawingTool.pivot || editingPivot) &&
            pivotCenter != null) {
          markers.add(_pivotCenterMarker(pivotCenter));
          if (pivotEdge != null) {
            markers.add(_pivotEdgeMarker(pivotEdge));
            polylines.add(
              Polyline(
                points: [pivotCenter, pivotEdge],
                color: Colors.orange,
                strokeWidth: 2,
                pattern: StrokePattern.dashed(segments: const [8, 6]),
              ),
            );
          }
        }

        if (currentTool == DrawingTool.freehand && freehandTrail.length >= 2) {
          polylines.add(
            Polyline(
              points: freehandTrail,
              color: _manualOutlineHalo,
              strokeWidth: 8,
            ),
          );
          polylines.add(
            Polyline(
              points: freehandTrail,
              color: _manualOutlineColor,
              strokeWidth: 4,
            ),
          );
        }

        if (currentState == DrawingState.gpsTracking &&
            gpsVertices.isNotEmpty) {
          if (gpsVertices.length >= 2) {
            polylines.add(
              Polyline(
                points: gpsVertices,
                color: _gpsOutlineHalo,
                strokeWidth: 7,
              ),
            );
            polylines.add(
              Polyline(points: gpsVertices, color: Colors.red, strokeWidth: 3),
            );
          }
          markers.add(_gpsTipMarker(gpsVertices.first, isStart: true));
          if (gpsVertices.length >= 2) {
            markers.add(_gpsTipMarker(gpsVertices.last, isStart: false));
          }
        }

        if ((liveGeo is DrawingPolygon || liveGeo is DrawingMultiPolygon) &&
            currentState != DrawingState.gpsTracking &&
            currentState != DrawingState.editing) {
          final isImportPreview =
              widget.controller.currentState == DrawingState.importPreview ||
              widget.controller.interactionMode ==
                  DrawingInteraction.importPreview;

          final parts = liveGeo is DrawingPolygon
              ? [liveGeo.coordinates]
              : (liveGeo as DrawingMultiPolygon).coordinates;
          final liveOutlineHalo = sketchingTest
              ? _testFill.withValues(alpha: 0.85)
              : _manualOutlineHalo;
          final liveOutline = sketchingTest ? _testBorder : _manualOutlineColor;
          for (final rings in parts) {
            if (rings.isEmpty) continue;
            final outerRing = _toLatLngRing(rings.first);
            if (outerRing.length >= 2) {
              polylines.add(
                Polyline(
                  points: outerRing,
                  color: liveOutlineHalo,
                  strokeWidth: 8,
                ),
              );
              polylines.add(
                Polyline(
                  points: outerRing,
                  color: liveOutline,
                  strokeWidth: 4,
                  pattern: const StrokePattern.dotted(),
                ),
              );
            }
            polygons.add(
              _polygonFromRings(
                rings,
                color: sketchingTest
                    ? _testFill.withValues(alpha: 0.45)
                    : Colors.white.withValues(alpha: 0.2),
                borderColor: sketchingTest ? _testBorder : Colors.white,
                borderStrokeWidth: 3,
                pattern: const StrokePattern.dotted(),
              ),
            );
          }

          if (!isImportPreview &&
              currentTool == DrawingTool.polygon &&
              liveGeo is DrawingPolygon &&
              liveGeo.coordinates.isNotEmpty) {
            final outerRing = _toLatLngRing(liveGeo.coordinates.first);
            for (int i = 0; i < outerRing.length; i++) {
              final point = outerRing[i];
              final isStart = i == 0;
              final size = isStart ? 18.0 : 14.0;

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

              // Vértices interativos mid-draw/edição ficam no DrawingEditLayer.
              if (!hideDecorativeVertexMarkers) {
                markers.add(_vertexMarker(point, index: i, size: size));
              }
            }
          }
        }

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

  Marker _gpsTipMarker(LatLng point, {required bool isStart}) {
    final size = isStart ? 18.0 : 16.0;
    return Marker(
      point: point,
      width: size,
      height: size,
      alignment: Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          color: isStart ? const Color(0xFF30D158) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isStart ? Colors.white : Colors.red,
            width: 2,
          ),
        ),
      ),
    );
  }

  Marker _pivotCenterMarker(LatLng point) {
    return Marker(
      point: point,
      width: 20,
      height: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.orange,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2),
        ),
      ),
      alignment: Alignment.center,
    );
  }

  Marker _pivotEdgeMarker(LatLng point) {
    return Marker(
      point: point,
      width: 16,
      height: 16,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.orange, width: 2),
        ),
      ),
      alignment: Alignment.center,
    );
  }

  Marker _vertexMarker(LatLng point, {required int index, double? size}) {
    final isStart = index == 0;
    final markerSize = size ?? (isStart ? 18.0 : 14.0);
    final allowClose =
        widget.controller.currentTool == DrawingTool.polygon && isStart;
    return Marker(
      point: point,
      width: markerSize,
      height: markerSize,
      child: GestureDetector(
        key: Key('drawing_point_$index'),
        onTap: allowClose ? widget.onDrawingComplete : null,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isStart ? Colors.green : Colors.black26,
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
