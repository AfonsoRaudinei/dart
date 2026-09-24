import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/drawing_state.dart';
import '../../domain/models/drawing_models.dart';
import '../providers/drawing_provider.dart';
import 'drawing_vertex_gota_metrics.dart';

/// Captura pan/zoom do mapa acima do canvas quando há gota ativa (IPA-238).
///
/// O [ScaleGestureRecognizer] do flutter_map 7 vence o pan nos markers; este overlay
/// fica entre o mapa e os controles e absorve gestos com [HitTestBehavior.opaque].
class DrawingVertexDragOverlay extends ConsumerStatefulWidget {
  const DrawingVertexDragOverlay({
    super.key,
    required this.mapController,
    required this.isMapReady,
  });

  final MapController mapController;
  final bool isMapReady;

  @override
  ConsumerState<DrawingVertexDragOverlay> createState() =>
      _DrawingVertexDragOverlayState();
}

class _DrawingVertexDragOverlayState
    extends ConsumerState<DrawingVertexDragOverlay> {
  bool _panActive = false;
  bool _isSketchDrag = false;
  int? _sketchIndex;
  int? _editRing;
  int? _editPoint;
  LatLng? _dragAnchor;

  static bool _isActive(DrawingControllerSnapshot c) {
    final sketch =
        c.tool == DrawingTool.polygon &&
        (c.state == DrawingState.drawing || c.state == DrawingState.armed) &&
        c.sketchPointsNotEmpty &&
        (c.selectedSketchVertexIndex != null || c.isDraggingSketchVertex);
    final edit =
        c.state == DrawingState.editing &&
        (c.isDraggingVertex ||
            (c.selectedEditRingIndex != null &&
                c.selectedEditPointIndex != null));
    return sketch || edit;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(drawingControllerProvider);
    final snapshot = DrawingControllerSnapshot.from(controller);
    if (!_isActive(snapshot)) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapUp: (details) => _onTapUp(controller, snapshot, details.localPosition),
        onPanStart: (details) =>
            _onPanStart(controller, snapshot, details.localPosition),
        onPanUpdate: (details) => _onPanUpdate(controller, details),
        onPanEnd: (_) => _onPanEnd(controller),
        onPanCancel: () => _onPanCancel(controller),
      ),
    );
  }

  void _onTapUp(
    DrawingController controller,
    DrawingControllerSnapshot snapshot,
    Offset localPosition,
  ) {
    if (_panActive) return;
    if (!widget.isMapReady) return;

    final vertex = _selectedVertexLatLng(controller, snapshot);
    if (vertex == null) return;

    if (_gotaHitRect(vertex).contains(localPosition)) return;

    if (_isSketchContext(snapshot)) {
      controller.clearSketchVertexSelection();
    } else {
      controller.clearEditVertexSelection();
    }
  }

  void _onPanStart(
    DrawingController controller,
    DrawingControllerSnapshot snapshot,
    Offset localPosition,
  ) {
    if (!widget.isMapReady) return;

    final vertex = _selectedVertexLatLng(controller, snapshot);
    if (vertex == null) return;
    if (!_gotaHitRect(vertex).contains(localPosition)) return;

    _panActive = true;
    _dragAnchor = vertex;

    if (_isSketchContext(snapshot)) {
      final index = snapshot.selectedSketchVertexIndex;
      if (index == null) return;
      _isSketchDrag = true;
      _sketchIndex = index;
      controller.beginSketchVertexDrag(index);
      return;
    }

    final ring = snapshot.selectedEditRingIndex;
    final point = snapshot.selectedEditPointIndex;
    if (ring == null || point == null) return;
    _isSketchDrag = false;
    _editRing = ring;
    _editPoint = point;
    controller.beginEditVertexDrag(point);
  }

  void _onPanUpdate(DrawingController controller, DragUpdateDetails details) {
    if (!_panActive || _dragAnchor == null) return;

    final base = _dragAnchor!;
    final screen = widget.mapController.camera.latLngToScreenPoint(base);
    final moved = math.Point<double>(
      screen.x + details.delta.dx,
      screen.y + details.delta.dy,
    );
    final newLatLng = widget.mapController.camera.pointToLatLng(moved);
    _dragAnchor = newLatLng;

    if (_isSketchDrag && _sketchIndex != null) {
      controller.moveSketchVertex(_sketchIndex!, newLatLng);
      return;
    }

    final ring = _editRing;
    final point = _editPoint;
    if (ring != null && point != null) {
      controller.moveVertex(ring, point, newLatLng);
    }
  }

  void _onPanEnd(DrawingController controller) {
    if (!_panActive) return;

    final position = _dragAnchor;
    if (_isSketchDrag && _sketchIndex != null && position != null) {
      controller.moveSketchVertex(_sketchIndex!, position);
      controller.endSketchVertexDrag();
    } else if (_editRing != null && _editPoint != null && position != null) {
      controller.updateVertexPosition(_editRing!, _editPoint!, position);
      controller.onDragEnd(persist: false);
    } else if (_isSketchDrag) {
      controller.endSketchVertexDrag();
    } else {
      controller.onDragEnd(persist: false);
    }

    _resetDragState();
  }

  void _onPanCancel(DrawingController controller) {
    if (!_panActive) return;
    if (_isSketchDrag) {
      controller.endSketchVertexDrag();
    } else {
      controller.onDragEnd(persist: false);
    }
    _resetDragState();
  }

  void _resetDragState() {
    _panActive = false;
    _isSketchDrag = false;
    _sketchIndex = null;
    _editRing = null;
    _editPoint = null;
    _dragAnchor = null;
  }

  bool _isSketchContext(DrawingControllerSnapshot snapshot) {
    return snapshot.tool == DrawingTool.polygon &&
        (snapshot.state == DrawingState.drawing ||
            snapshot.state == DrawingState.armed);
  }

  LatLng? _selectedVertexLatLng(
    DrawingController controller,
    DrawingControllerSnapshot snapshot,
  ) {
    if (_isSketchContext(snapshot)) {
      final index = snapshot.selectedSketchVertexIndex;
      if (index == null) return null;
      final points = controller.currentPoints;
      if (index < 0 || index >= points.length) return null;
      return points[index];
    }

    if (snapshot.state != DrawingState.editing) return null;
    final ringIdx = snapshot.selectedEditRingIndex;
    final pointIdx = snapshot.selectedEditPointIndex;
    final geometry = controller.liveGeometry;
    if (ringIdx == null || pointIdx == null || geometry is! DrawingPolygon) {
      return null;
    }
    if (ringIdx < 0 || ringIdx >= geometry.coordinates.length) return null;
    final ring = geometry.coordinates[ringIdx];
    if (pointIdx < 0 || pointIdx >= ring.length) return null;
    final raw = ring[pointIdx];
    return LatLng(raw[1], raw[0]);
  }

  Rect _gotaHitRect(LatLng vertex) {
    final screen = widget.mapController.camera.latLngToScreenPoint(vertex);
    final bottomCenter = Offset(screen.x, screen.y);
    return Rect.fromLTWH(
      bottomCenter.dx - DrawingVertexGotaMetrics.width / 2,
      bottomCenter.dy - DrawingVertexGotaMetrics.height,
      DrawingVertexGotaMetrics.width,
      DrawingVertexGotaMetrics.height,
    );
  }
}

/// Campos usados pelo overlay (evita rebuild amplo no orchestrator).
class DrawingControllerSnapshot {
  const DrawingControllerSnapshot({
    required this.tool,
    required this.state,
    required this.sketchPointsNotEmpty,
    required this.selectedSketchVertexIndex,
    required this.isDraggingSketchVertex,
    required this.isDraggingVertex,
    required this.selectedEditRingIndex,
    required this.selectedEditPointIndex,
  });

  final DrawingTool tool;
  final DrawingState state;
  final bool sketchPointsNotEmpty;
  final int? selectedSketchVertexIndex;
  final bool isDraggingSketchVertex;
  final bool isDraggingVertex;
  final int? selectedEditRingIndex;
  final int? selectedEditPointIndex;

  static DrawingControllerSnapshot from(DrawingController controller) {
    return DrawingControllerSnapshot(
      tool: controller.currentTool,
      state: controller.currentState,
      sketchPointsNotEmpty: controller.currentPoints.isNotEmpty,
      selectedSketchVertexIndex: controller.selectedSketchVertexIndex,
      isDraggingSketchVertex: controller.isDraggingSketchVertex,
      isDraggingVertex: controller.isDraggingVertex,
      selectedEditRingIndex: controller.selectedEditRingIndex,
      selectedEditPointIndex: controller.selectedEditPointIndex,
    );
  }
}
