import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/drawing_state.dart';
import '../../domain/drawing_utils.dart';
import '../../domain/models/drawing_models.dart';
import '../controllers/drawing_controller.dart';
import 'vertex_handle_drag_preview.dart';

/// Igual a [_VertexGotaMetrics] em drawing_edit_layer.dart (ponta no LatLng).
const double _kHandleWidth = 56;
const double _kHandleHeight = 78;

/// Alças de vértice acima do [FlutterMap].
///
/// O dedo fica no corpo da gota (abaixo do LatLng). O mapa não recebe esse
/// ponteiro, então o pan do mapa continua fora da alça.
class DrawingVertexHandleOverlay extends StatefulWidget {
  const DrawingVertexHandleOverlay({
    super.key,
    required this.controller,
    required this.mapController,
    this.onPolygonClose,
  });

  final DrawingController controller;
  final MapController mapController;
  final VoidCallback? onPolygonClose;

  @override
  State<DrawingVertexHandleOverlay> createState() =>
      _DrawingVertexHandleOverlayState();
}

class _DrawingVertexHandleOverlayState extends State<DrawingVertexHandleOverlay> {
  StreamSubscription<MapEvent>? _cameraSub;
  VertexHandleDrag? _active;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onController);
    widget.controller.vertexDragPreview.addListener(_onPreview);
    _cameraSub = widget.mapController.mapEventStream.listen((_) {
      if (mounted) setState(() {});
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void didUpdateWidget(covariant DrawingVertexHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onController);
      oldWidget.controller.vertexDragPreview.removeListener(_onPreview);
      widget.controller.addListener(_onController);
      widget.controller.vertexDragPreview.addListener(_onPreview);
    }
    if (oldWidget.mapController != widget.mapController) {
      _cameraSub?.cancel();
      _cameraSub = widget.mapController.mapEventStream.listen((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _cameraSub?.cancel();
    widget.controller.removeListener(_onController);
    widget.controller.vertexDragPreview.removeListener(_onPreview);
    super.dispose();
  }

  void _onController() {
    if (mounted) setState(() {});
  }

  void _onPreview() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final handles = _handles();
    if (handles.isEmpty) return const SizedBox.shrink();

    return Stack(
      children: [
        for (final handle in handles) _positioned(handle),
      ],
    );
  }

  List<_VertexHandleTarget> _handles() {
    final controller = widget.controller;
    final preview = controller.vertexDragPreview.drag ?? _active;
    if (_isSketch) {
      final points = List<LatLng>.from(controller.currentPoints);
      if (preview != null &&
          preview.isSketch &&
          preview.pointIndex >= 0 &&
          preview.pointIndex < points.length) {
        points[preview.pointIndex] = preview.position;
      }
      return [
        for (var i = 0; i < points.length; i++)
          _VertexHandleTarget(
            key: Key('drawing_sketch_vertex_hit_$i'),
            point: points[i],
            isSketch: true,
            ringIndex: 0,
            pointIndex: i,
          ),
      ];
    }

    if (controller.currentState != DrawingState.editing) return const [];
    final geometry = controller.liveGeometry;
    if (geometry is! DrawingPolygon) return const [];

    final targets = <_VertexHandleTarget>[];
    for (var ringIdx = 0; ringIdx < geometry.coordinates.length; ringIdx++) {
      final ring = geometry.coordinates[ringIdx]
          .map((p) => LatLng(p[1], p[0]))
          .toList();
      final isClosed =
          ring.length > 1 &&
          ring.first.latitude == ring.last.latitude &&
          ring.first.longitude == ring.last.longitude;
      final logicalLength = isClosed ? ring.length - 1 : ring.length;
      for (var i = 0; i < logicalLength; i++) {
        var point = ring[i];
        if (preview != null &&
            !preview.isSketch &&
            preview.ringIndex == ringIdx &&
            preview.pointIndex == i) {
          point = preview.position;
        }
        targets.add(
          _VertexHandleTarget(
            key: Key('drawing_vertex_hit_${ringIdx}_$i'),
            point: point,
            isSketch: false,
            ringIndex: ringIdx,
            pointIndex: i,
          ),
        );
      }
    }
    return targets;
  }

  bool get _isSketch {
    final c = widget.controller;
    return c.currentTool == DrawingTool.polygon &&
        (c.currentState == DrawingState.drawing ||
            c.currentState == DrawingState.armed) &&
        c.currentPoints.isNotEmpty;
  }

  Widget _positioned(_VertexHandleTarget handle) {
    final screen = _screenOf(handle.point);
    if (screen == null) return const SizedBox.shrink();
    return Positioned(
      left: screen.x - _kHandleWidth / 2,
      top: screen.y,
      width: _kHandleWidth,
      height: _kHandleHeight,
      child: GestureDetector(
        key: handle.key,
        behavior: HitTestBehavior.opaque,
        onTap: () => _onTap(handle),
        onDoubleTap: handle.isSketch ? null : () => _onDoubleTap(handle),
        onPanStart: (_) => _onPanStart(handle),
        onPanUpdate: (details) => _onPanUpdate(details, handle),
        onPanEnd: (_) => _onPanEnd(handle),
        onPanCancel: _onPanCancel,
        child: const SizedBox.expand(),
      ),
    );
  }

  math.Point<double>? _screenOf(LatLng point) {
    try {
      final screen = widget.mapController.camera.latLngToScreenPoint(point);
      return math.Point<double>(screen.x, screen.y);
    } catch (_) {
      return null;
    }
  }

  void _onTap(_VertexHandleTarget handle) {
    final controller = widget.controller;
    if (handle.isSketch) {
      final already = controller.selectedSketchVertexIndex == handle.pointIndex;
      if (handle.pointIndex == 0 &&
          already &&
          controller.canFinishDrawing &&
          !controller.hasSelfIntersection) {
        widget.onPolygonClose?.call();
        return;
      }
      controller.selectSketchVertex(handle.pointIndex);
      return;
    }
    controller.selectEditVertex(handle.ringIndex, handle.pointIndex);
  }

  void _onDoubleTap(_VertexHandleTarget handle) {
    widget.controller.removeVertex(handle.ringIndex, handle.pointIndex);
    widget.controller.clearEditVertexSelection();
  }

  void _onPanStart(_VertexHandleTarget handle) {
    final controller = widget.controller;
    if (handle.isSketch) {
      controller.beginSketchVertexDrag(handle.pointIndex);
    } else {
      controller.beginEditVertexDrag(handle.pointIndex, handle.ringIndex);
    }
    final drag = VertexHandleDrag(
      isSketch: handle.isSketch,
      ringIndex: handle.ringIndex,
      pointIndex: handle.pointIndex,
      position: handle.point,
    );
    _active = drag;
    _publish(drag);
  }

  void _onPanUpdate(DragUpdateDetails details, _VertexHandleTarget handle) {
    final current = _active;
    if (current == null) return;
    final screen = _screenOf(current.position);
    if (screen == null) return;
    final moved = math.Point<double>(
      screen.x + details.delta.dx,
      screen.y + details.delta.dy,
    );
    LatLng next;
    try {
      next = widget.mapController.camera.pointToLatLng(moved);
    } catch (_) {
      return;
    }
    final drag = VertexHandleDrag(
      isSketch: handle.isSketch,
      ringIndex: handle.ringIndex,
      pointIndex: handle.pointIndex,
      position: next,
    );
    _active = drag;
    _publish(drag);
  }

  void _onPanEnd(_VertexHandleTarget handle) {
    final drag = _active;
    _active = null;
    final controller = widget.controller;
    if (drag != null) {
      if (drag.isSketch) {
        controller.moveSketchVertex(drag.pointIndex, drag.position);
        controller.endSketchVertexDrag();
      } else {
        controller.updateVertexPosition(
          drag.ringIndex,
          drag.pointIndex,
          drag.position,
        );
        controller.onDragEnd(persist: false);
      }
    } else if (handle.isSketch) {
      controller.endSketchVertexDrag();
    } else {
      controller.onDragEnd(persist: false);
    }
    controller.vertexDragPreview.clear();
  }

  void _onPanCancel() {
    final wasSketch = _active?.isSketch ?? false;
    _active = null;
    if (wasSketch) {
      widget.controller.endSketchVertexDrag();
    } else {
      widget.controller.onDragEnd(persist: false);
    }
    widget.controller.vertexDragPreview.clear();
  }

  void _publish(VertexHandleDrag drag) {
    final measure = _measure(drag);
    widget.controller.vertexDragPreview.update(
      drag,
      areaHa: measure.$1,
      perimeterKm: measure.$2,
    );
  }

  (double, double) _measure(VertexHandleDrag drag) {
    if (drag.isSketch) {
      final points = List<LatLng>.from(widget.controller.currentPoints);
      if (drag.pointIndex < 0 || drag.pointIndex >= points.length) {
        return (0, 0);
      }
      points[drag.pointIndex] = drag.position;
      if (points.length < 3) return (0, 0);
      final ring = points
          .map((p) => <double>[p.longitude, p.latitude])
          .toList();
      ring.add(List<double>.from(ring.first));
      final geometry = DrawingPolygon(coordinates: [ring]);
      return (
        DrawingUtils.calculateGeometryArea(geometry),
        DrawingUtils.calculatePerimeterKm(geometry),
      );
    }

    final geometry = widget.controller.liveGeometry;
    if (geometry is! DrawingPolygon) return (0, 0);
    final updated = _movedPolygon(geometry, drag);
    return (
      DrawingUtils.calculateGeometryArea(updated),
      DrawingUtils.calculatePerimeterKm(updated),
    );
  }

  DrawingPolygon _movedPolygon(DrawingPolygon original, VertexHandleDrag drag) {
    final coordinates = original.coordinates
        .map((ring) => ring.map((p) => [p[0], p[1]]).toList())
        .toList();
    if (drag.ringIndex < 0 || drag.ringIndex >= coordinates.length) {
      return original;
    }
    final ring = coordinates[drag.ringIndex];
    if (drag.pointIndex < 0 || drag.pointIndex >= ring.length) return original;
    ring[drag.pointIndex] = [drag.position.longitude, drag.position.latitude];
    final isClosed =
        ring.length > 1 &&
        ring.first[0] == ring.last[0] &&
        ring.first[1] == ring.last[1];
    if (isClosed) {
      if (drag.pointIndex == 0) {
        ring[ring.length - 1] = [
          drag.position.longitude,
          drag.position.latitude,
        ];
      }
    }
    return DrawingPolygon(coordinates: coordinates);
  }
}

class _VertexHandleTarget {
  const _VertexHandleTarget({
    required this.key,
    required this.point,
    required this.isSketch,
    required this.ringIndex,
    required this.pointIndex,
  });

  final Key key;
  final LatLng point;
  final bool isSketch;
  final int ringIndex;
  final int pointIndex;
}
