import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/layout_constants.dart';
import '../../../modules/drawing/domain/models/drawing_models.dart';

/// Margem padrão da toolbar contextual no mapa (espelha [MapTalhaoSelectionToolbar.edgeMargin]).
const kMapTalhaoToolbarEdgeMargin = 8.0;

/// Vértices do polígono/multipolígono em coordenadas LatLng.
@visibleForTesting
List<LatLng> drawingFeatureVertexLatLngs(DrawingFeature feature) {
  final points = <LatLng>[];
  final geometry = feature.geometry;

  if (geometry is DrawingPolygon) {
    for (final ring in geometry.coordinates) {
      points.addAll(ring.map((p) => LatLng(p[1], p[0])));
    }
  } else if (geometry is DrawingMultiPolygon) {
    for (final polygon in geometry.coordinates) {
      for (final ring in polygon) {
        points.addAll(ring.map((p) => LatLng(p[1], p[0])));
      }
    }
  }
  return points;
}

/// Centroide simples do polígono para ancorar a toolbar.
LatLng? drawingFeatureAnchorLatLng(DrawingFeature feature) {
  final points = drawingFeatureVertexLatLngs(feature);
  if (points.isEmpty) return null;

  var sumLat = 0.0;
  var sumLng = 0.0;
  for (final p in points) {
    sumLat += p.latitude;
    sumLng += p.longitude;
  }
  return LatLng(sumLat / points.length, sumLng / points.length);
}

/// Projeta vértices da feature em offsets de tela.
List<Offset> drawingFeatureScreenOffsets(
  DrawingFeature feature,
  Offset Function(LatLng latLng) project,
) {
  return drawingFeatureVertexLatLngs(feature).map(project).toList();
}

/// Retângulo na tela que envolve os vértices projetados, com padding opcional.
Rect? drawingFeatureScreenBounds(
  List<Offset> screenOffsets, {
  double padding = 8,
}) {
  if (screenOffsets.isEmpty) return null;

  var minX = double.infinity;
  var minY = double.infinity;
  var maxX = double.negativeInfinity;
  var maxY = double.negativeInfinity;
  for (final o in screenOffsets) {
    minX = math.min(minX, o.dx);
    minY = math.min(minY, o.dy);
    maxX = math.max(maxX, o.dx);
    maxY = math.max(maxY, o.dy);
  }
  return Rect.fromLTRB(
    minX - padding,
    minY - padding,
    maxX + padding,
    maxY + padding,
  );
}

/// Limites de posição da toolbar na viewport (mesma política de [clampMapToolbarOffset]).
@visibleForTesting
({double minLeft, double maxLeft, double minTop, double maxTop})
    mapToolbarClampBounds({
  required Size viewportSize,
  required double toolbarWidth,
  required double toolbarHeight,
  double topInset = 0,
  double bottomInset = 0,
  double edgeMargin = kMapTalhaoToolbarEdgeMargin,
}) {
  final minLeft = edgeMargin;
  final rightColumnReserve =
      kMapActionColumnRightInset + kMapActionColumnButtonSize;
  final maxLeft = math.max(
    edgeMargin,
    viewportSize.width - toolbarWidth - edgeMargin - rightColumnReserve,
  );
  final minTop = topInset + edgeMargin;
  final maxTop = math.max(
    minTop,
    viewportSize.height -
        bottomInset -
        kFabSafeArea -
        toolbarHeight -
        edgeMargin,
  );
  return (minLeft: minLeft, maxLeft: maxLeft, minTop: minTop, maxTop: maxTop);
}

Offset _clampToolbarPosition({
  required double left,
  required double top,
  required ({double minLeft, double maxLeft, double minTop, double maxTop})
      bounds,
}) {
  return Offset(
    left.clamp(bounds.minLeft, bounds.maxLeft),
    top.clamp(bounds.minTop, bounds.maxTop),
  );
}

double _toolbarSeparationFromBounds(Rect toolbar, Rect feature) {
  if (toolbar.overlaps(feature)) {
    final intersection = toolbar.intersect(feature);
    return -intersection.width * intersection.height;
  }
  final gapLeft = feature.left - toolbar.right;
  final gapRight = toolbar.left - feature.right;
  final gapTop = feature.top - toolbar.bottom;
  final gapBottom = toolbar.top - feature.bottom;
  return math.max(
    0,
    math.max(math.max(gapLeft, gapRight), math.max(gapTop, gapBottom)),
  );
}

double _toolbarFreeSpaceToViewportEdge(
  Rect toolbar,
  Size viewportSize,
  double topInset,
  double bottomInset,
) {
  final rightReserve = kMapActionColumnRightInset + kMapActionColumnButtonSize;
  final spaceLeft = toolbar.left;
  final spaceRight = viewportSize.width - rightReserve - toolbar.right;
  final spaceTop = toolbar.top - topInset;
  final spaceBottom =
      viewportSize.height - bottomInset - kFabSafeArea - toolbar.bottom;
  return math.min(
    math.min(spaceLeft, spaceRight),
    math.min(spaceTop, spaceBottom),
  );
}

/// Escolhe posição ao redor da bbox da feature, sem cobrir a área de trabalho.
Offset resolveMapTalhaoToolbarOffset({
  required Offset screenPoint,
  required Rect? featureScreenBounds,
  required Size viewportSize,
  required double toolbarWidth,
  required double toolbarHeight,
  double topInset = 0,
  double bottomInset = 0,
  double edgeMargin = kMapTalhaoToolbarEdgeMargin,
  double anchorGap = 24,
  double? anchorHeight,
}) {
  final lineH = anchorHeight ?? toolbarHeight;
  final bounds = mapToolbarClampBounds(
    viewportSize: viewportSize,
    toolbarWidth: toolbarWidth,
    toolbarHeight: toolbarHeight,
    topInset: topInset,
    bottomInset: bottomInset,
    edgeMargin: edgeMargin,
  );

  if (featureScreenBounds == null) {
    return clampMapToolbarOffset(
      screenPoint: screenPoint,
      viewportSize: viewportSize,
      toolbarWidth: toolbarWidth,
      toolbarHeight: toolbarHeight,
      topInset: topInset,
      bottomInset: bottomInset,
      edgeMargin: edgeMargin,
      anchorGap: anchorGap,
      anchorHeight: anchorHeight,
    );
  }

  final f = featureScreenBounds;
  final anchorX = screenPoint.dx;
  final anchorY = screenPoint.dy;
  final centerY = f.center.dy;

  final candidates = <Offset>[
    _clampToolbarPosition(
      left: f.center.dx - toolbarWidth / 2,
      top: f.top - lineH - anchorGap,
      bounds: bounds,
    ),
    _clampToolbarPosition(
      left: f.center.dx - toolbarWidth / 2,
      top: f.bottom + anchorGap,
      bounds: bounds,
    ),
    _clampToolbarPosition(
      left: f.left - toolbarWidth - anchorGap,
      top: centerY - lineH / 2,
      bounds: bounds,
    ),
    _clampToolbarPosition(
      left: f.right + anchorGap,
      top: centerY - lineH / 2,
      bounds: bounds,
    ),
    _clampToolbarPosition(
      left: anchorX - toolbarWidth / 2,
      top: anchorY - lineH - anchorGap,
      bounds: bounds,
    ),
  ];

  Offset? best;
  var bestSeparation = double.negativeInfinity;
  var bestFreeSpace = double.negativeInfinity;

  for (final offset in candidates) {
    final toolbarRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      toolbarWidth,
      toolbarHeight,
    );
    final separation = _toolbarSeparationFromBounds(toolbarRect, f);
    final freeSpace = _toolbarFreeSpaceToViewportEdge(
      toolbarRect,
      viewportSize,
      topInset,
      bottomInset,
    );

    final better = separation > bestSeparation ||
        (separation == bestSeparation && freeSpace > bestFreeSpace);
    if (better) {
      best = offset;
      bestSeparation = separation;
      bestFreeSpace = freeSpace;
    }
  }

  return best ??
      clampMapToolbarOffset(
        screenPoint: screenPoint,
        viewportSize: viewportSize,
        toolbarWidth: toolbarWidth,
        toolbarHeight: toolbarHeight,
        topInset: topInset,
        bottomInset: bottomInset,
        edgeMargin: edgeMargin,
        anchorGap: anchorGap,
        anchorHeight: anchorHeight,
      );
}

/// Posiciona a toolbar acima do ponto de ancoragem, com clamp nas bordas.
Offset clampMapToolbarOffset({
  required Offset screenPoint,
  required Size viewportSize,
  required double toolbarWidth,
  required double toolbarHeight,
  double topInset = 0,
  double bottomInset = 0,
  double edgeMargin = kMapTalhaoToolbarEdgeMargin,
  double anchorGap = 24,
  double? anchorHeight,
}) {
  final lineH = anchorHeight ?? toolbarHeight;
  final bounds = mapToolbarClampBounds(
    viewportSize: viewportSize,
    toolbarWidth: toolbarWidth,
    toolbarHeight: toolbarHeight,
    topInset: topInset,
    bottomInset: bottomInset,
    edgeMargin: edgeMargin,
  );
  return _clampToolbarPosition(
    left: screenPoint.dx - toolbarWidth / 2,
    top: screenPoint.dy - lineH - anchorGap,
    bounds: bounds,
  );
}