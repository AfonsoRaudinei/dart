import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/drawing_state.dart';
import '../../domain/models/drawing_models.dart';
import '../../presentation/controllers/drawing_controller.dart';
import 'drawing_vertex_drag_handle.dart';

/// Handles de vértice para edição e ajuste durante o desenho (sketch).
///
/// Em edição: geometria da feature selecionada.
/// Em desenho: pontos do sketch (polígono/retângulo/círculo), freehand
/// finalizado e pivô (centro/borda).
///
/// Durante o arraste, exibe o pingo d'água azul semi-transparente.
class DrawingEditLayer extends StatefulWidget {
  final DrawingController controller;
  final MapController mapController;
  final VoidCallback? onSketchClosePolygon;

  const DrawingEditLayer({
    super.key,
    required this.controller,
    required this.mapController,
    this.onSketchClosePolygon,
  });

  @override
  State<DrawingEditLayer> createState() => _DrawingEditLayerState();
}

enum _HandleMode { edit, sketchPolygon, sketchFreehand, sketchPivot }

class _DrawingEditLayerState extends State<DrawingEditLayer> {
  int? _draggingVertexIndex;
  int? _draggingRingIndex;
  LatLng? _draggingPosition;
  _HandleMode? _dragMode;
  bool _draggingPivotCenter = false;

  bool get _isDragging =>
      _draggingPosition != null &&
      (_draggingPivotCenter ||
          (_draggingVertexIndex != null && _draggingRingIndex != null));

  _HandleMode? _resolveMode() {
    final state = widget.controller.currentState;
    final tool = widget.controller.currentTool;

    if (state == DrawingState.editing) return _HandleMode.edit;

    final sketching =
        state == DrawingState.drawing || state == DrawingState.armed;
    if (!sketching) return null;

    switch (tool) {
      case DrawingTool.polygon:
      case DrawingTool.rectangle:
      case DrawingTool.circle:
        if (widget.controller.currentPoints.isEmpty) return null;
        return _HandleMode.sketchPolygon;
      case DrawingTool.freehand:
        if (widget.controller.isFreehandStrokeActive) return null;
        if (widget.controller.freehandTrail.length < 3) return null;
        return _HandleMode.sketchFreehand;
      case DrawingTool.pivot:
        if (widget.controller.pivotCenter == null) return null;
        return _HandleMode.sketchPivot;
      case DrawingTool.none:
        return null;
    }
  }

  void _startVertexDrag({
    required _HandleMode mode,
    required int ringIndex,
    required int pointIndex,
    required LatLng point,
  }) {
    setState(() {
      _dragMode = mode;
      _draggingRingIndex = ringIndex;
      _draggingVertexIndex = pointIndex;
      _draggingPosition = point;
      _draggingPivotCenter = false;
    });
    widget.controller.onDragStart(pointIndex);
  }

  void _startPivotCenterDrag(LatLng point) {
    setState(() {
      _dragMode = _HandleMode.sketchPivot;
      _draggingPivotCenter = true;
      _draggingRingIndex = 0;
      _draggingVertexIndex = 0;
      _draggingPosition = point;
    });
    widget.controller.onDragStart(0);
  }

  void _startPivotEdgeDrag(LatLng point) {
    setState(() {
      _dragMode = _HandleMode.sketchPivot;
      _draggingPivotCenter = false;
      _draggingRingIndex = 0;
      _draggingVertexIndex = 1;
      _draggingPosition = point;
    });
    widget.controller.onDragStart(1);
  }

  void _updateVertexDrag(DragUpdateDetails details, LatLng fallbackPoint) {
    if (!_isDragging) return;

    final basePoint = _draggingPosition ?? fallbackPoint;
    final screenPoint = widget.mapController.camera.latLngToScreenPoint(
      basePoint,
    );
    final movedPoint = math.Point<double>(
      screenPoint.x + details.delta.dx,
      screenPoint.y + details.delta.dy,
    );

    final newLatLng = widget.mapController.camera.pointToLatLng(movedPoint);
    setState(() => _draggingPosition = newLatLng);

    // Preview ao vivo no controller durante o sketch (sem persistir).
    final mode = _dragMode;
    if (mode == _HandleMode.sketchPolygon && _draggingVertexIndex != null) {
      widget.controller.moveSketchVertex(_draggingVertexIndex!, newLatLng);
    } else if (mode == _HandleMode.sketchFreehand &&
        _draggingVertexIndex != null) {
      widget.controller.moveFreehandVertex(_draggingVertexIndex!, newLatLng);
    } else if (mode == _HandleMode.sketchPivot) {
      if (_draggingPivotCenter) {
        widget.controller.movePivotCenter(newLatLng);
      } else {
        widget.controller.updatePivotEdge(newLatLng);
      }
    }
  }

  void _endVertexDrag() {
    final mode = _dragMode;
    final ringIndex = _draggingRingIndex;
    final pointIndex = _draggingVertexIndex;
    final position = _draggingPosition;
    final pivotCenter = _draggingPivotCenter;

    if (mode == _HandleMode.edit &&
        ringIndex != null &&
        pointIndex != null &&
        position != null) {
      widget.controller.updateVertexPosition(ringIndex, pointIndex, position);
    } else if (mode == _HandleMode.sketchPolygon &&
        pointIndex != null &&
        position != null) {
      widget.controller.moveSketchVertex(pointIndex, position);
    } else if (mode == _HandleMode.sketchFreehand &&
        pointIndex != null &&
        position != null) {
      widget.controller.moveFreehandVertex(pointIndex, position);
    } else if (mode == _HandleMode.sketchPivot && position != null) {
      if (pivotCenter) {
        widget.controller.movePivotCenter(position);
      } else {
        widget.controller.finalizePivotEdge(position);
      }
    }

    widget.controller.onDragEnd(persist: false);
    setState(() {
      _dragMode = null;
      _draggingRingIndex = null;
      _draggingVertexIndex = null;
      _draggingPosition = null;
      _draggingPivotCenter = false;
    });
  }

  void _cancelVertexDrag() {
    widget.controller.onDragEnd(persist: false);
    setState(() {
      _dragMode = null;
      _draggingRingIndex = null;
      _draggingVertexIndex = null;
      _draggingPosition = null;
      _draggingPivotCenter = false;
    });
  }

  DrawingGeometry? _resolveDisplayGeometry(DrawingGeometry? original) {
    if (!_isDragging || original is! DrawingPolygon) return original;
    if (_dragMode != _HandleMode.edit) return original;

    final ringIndex = _draggingRingIndex!;
    final pointIndex = _draggingVertexIndex!;
    final pos = _draggingPosition!;

    if (ringIndex < 0 || ringIndex >= original.coordinates.length) {
      return original;
    }

    final newCoordinates = original.coordinates
        .map((ring) => ring.map((p) => [p[0], p[1]]).toList())
        .toList();

    final ring = newCoordinates[ringIndex];
    if (pointIndex < 0 || pointIndex >= ring.length) return original;

    ring[pointIndex] = [pos.longitude, pos.latitude];

    final isClosed =
        ring.length > 1 &&
        ring.first[0] == ring.last[0] &&
        ring.first[1] == ring.last[1];

    if (isClosed) {
      if (pointIndex == 0) {
        ring[ring.length - 1] = [pos.longitude, pos.latitude];
      } else if (pointIndex == ring.length - 1) {
        ring[0] = [pos.longitude, pos.latitude];
      }
    }

    return DrawingPolygon(coordinates: newCoordinates);
  }

  List<Polygon> _buildDragPreviewPolygons(DrawingGeometry? geometry) {
    if (!_isDragging || geometry is! DrawingPolygon) return const [];
    if (geometry.coordinates.isEmpty || geometry.coordinates.first.isEmpty) {
      return const [];
    }

    final outer = geometry.coordinates.first
        .map((p) => LatLng(p[1], p[0]))
        .toList();
    final holes = geometry.coordinates.length > 1
        ? geometry.coordinates.skip(1).map((ring) {
            return ring.map((p) => LatLng(p[1], p[0])).toList();
          }).toList()
        : null;

    return [
      Polygon(
        points: outer,
        holePointsList: holes,
        color: const Color(0x990078D7).withValues(alpha: 0.12),
        borderColor: const Color(0xFF0078D7),
        borderStrokeWidth: 3,
      ),
    ];
  }

  List<Polyline> _buildDragPreviewPolylines(DrawingGeometry? geometry) {
    if (!_isDragging || geometry is! DrawingPolygon) return const [];

    final lines = <Polyline>[];
    for (final ring in geometry.coordinates) {
      if (ring.length < 2) continue;
      lines.add(
        Polyline(
          points: ring.map((p) => LatLng(p[1], p[0])).toList(),
          color: const Color(0xFF0078D7),
          strokeWidth: 3,
        ),
      );
    }
    return lines;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final mode = _resolveMode();
        if (mode == null) return const SizedBox.shrink();

        switch (mode) {
          case _HandleMode.edit:
            return _buildEditStack();
          case _HandleMode.sketchPolygon:
            return _buildSketchPolygonHandles();
          case _HandleMode.sketchFreehand:
            return _buildSketchFreehandHandles();
          case _HandleMode.sketchPivot:
            return _buildSketchPivotHandles();
        }
      },
    );
  }

  Widget _buildEditStack() {
    final geometry = widget.controller.liveGeometry;
    final displayGeometry = _resolveDisplayGeometry(geometry);
    final previewPolygons = _buildDragPreviewPolygons(displayGeometry);
    final previewPolylines = _buildDragPreviewPolylines(displayGeometry);

    return Stack(
      children: [
        if (previewPolygons.isNotEmpty)
          PolygonLayer(polygons: previewPolygons),
        if (previewPolylines.isNotEmpty)
          PolylineLayer(polylines: previewPolylines),
        MarkerLayer(markers: _buildEditMarkers(displayGeometry)),
      ],
    );
  }

  Widget _buildSketchPolygonHandles() {
    final points = widget.controller.currentPoints;
    return MarkerLayer(markers: _buildPointHandles(
      points: points,
      mode: _HandleMode.sketchPolygon,
      allowCloseOnFirst: true,
    ));
  }

  Widget _buildSketchFreehandHandles() {
    final points = widget.controller.freehandTrail;
    final indices = <int>[];
    if (points.length <= 28) {
      for (var i = 0; i < points.length; i++) {
        indices.add(i);
      }
    } else {
      final step = (points.length / 24).ceil();
      for (var i = 0; i < points.length; i += step) {
        indices.add(i);
      }
      if (indices.last != points.length - 1) {
        indices.add(points.length - 1);
      }
    }

    final sampled = indices.map((i) => points[i]).toList(growable: false);
    return MarkerLayer(
      markers: _buildPointHandles(
        points: sampled,
        mode: _HandleMode.sketchFreehand,
        allowCloseOnFirst: false,
        indexMapper: (displayIndex) => indices[displayIndex],
      ),
    );
  }

  Widget _buildSketchPivotHandles() {
    final center = widget.controller.pivotCenter;
    final edge = widget.controller.pivotEdgePoint;
    if (center == null) return const SizedBox.shrink();

    final markers = <Marker>[];
    final centerDragging =
        _isDragging && _draggingPivotCenter && _dragMode == _HandleMode.sketchPivot;
    final centerPos =
        centerDragging && _draggingPosition != null ? _draggingPosition! : center;

    markers.add(
      Marker(
        point: centerPos,
        width: centerDragging ? 56 : 24,
        height: centerDragging ? 56 : 24,
        alignment: centerDragging ? Alignment.bottomCenter : Alignment.center,
        child: _InteractiveVertexHandle(
          keyId: 'drawing_sketch_pivot_center',
          isDragging: centerDragging,
          isStart: true,
          onPanStart: () => _startPivotCenterDrag(center),
          onPanUpdate: (d) => _updateVertexDrag(d, center),
          onPanEnd: _endVertexDrag,
          onPanCancel: _cancelVertexDrag,
        ),
      ),
    );

    if (edge != null) {
      final edgeDragging =
          _isDragging && !_draggingPivotCenter && _dragMode == _HandleMode.sketchPivot;
      final edgePos =
          edgeDragging && _draggingPosition != null ? _draggingPosition! : edge;
      markers.add(
        Marker(
          point: edgePos,
          width: edgeDragging ? 56 : 20,
          height: edgeDragging ? 56 : 20,
          alignment: edgeDragging ? Alignment.bottomCenter : Alignment.center,
          child: _InteractiveVertexHandle(
            keyId: 'drawing_sketch_pivot_edge',
            isDragging: edgeDragging,
            isStart: false,
            onPanStart: () => _startPivotEdgeDrag(edge),
            onPanUpdate: (d) => _updateVertexDrag(d, edge),
            onPanEnd: _endVertexDrag,
            onPanCancel: _cancelVertexDrag,
          ),
        ),
      );
    }

    return MarkerLayer(markers: markers);
  }

  List<Marker> _buildPointHandles({
    required List<LatLng> points,
    required _HandleMode mode,
    required bool allowCloseOnFirst,
    int Function(int displayIndex)? indexMapper,
  }) {
    final markers = <Marker>[];
    for (var i = 0; i < points.length; i++) {
      final logicalIndex = indexMapper?.call(i) ?? i;
      final p = points[i];
      final isDragging =
          _dragMode == mode &&
          _draggingRingIndex == 0 &&
          _draggingVertexIndex == logicalIndex;
      final displayPoint =
          isDragging && _draggingPosition != null ? _draggingPosition! : p;
      final isStart = i == 0;

      markers.add(
        Marker(
          point: displayPoint,
          width: isDragging ? 56 : (isStart ? 22 : 18),
          height: isDragging ? 56 : (isStart ? 22 : 18),
          alignment: isDragging ? Alignment.bottomCenter : Alignment.center,
          child: _InteractiveVertexHandle(
            keyId: 'drawing_vertex_0_$logicalIndex',
            isDragging: isDragging,
            isStart: isStart,
            onPanStart: () => _startVertexDrag(
              mode: mode,
              ringIndex: 0,
              pointIndex: logicalIndex,
              point: p,
            ),
            onPanUpdate: (d) => _updateVertexDrag(d, p),
            onPanEnd: _endVertexDrag,
            onPanCancel: _cancelVertexDrag,
            onTap: allowCloseOnFirst &&
                    isStart &&
                    points.length >= 3 &&
                    !widget.controller.hasSelfIntersection
                ? widget.onSketchClosePolygon
                : null,
            onDoubleTap: mode == _HandleMode.edit
                ? () => widget.controller.removeVertex(0, logicalIndex)
                : null,
          ),
        ),
      );

      if (i < points.length - 1 || (allowCloseOnFirst && points.length >= 3)) {
        final next = i < points.length - 1 ? points[i + 1] : points.first;
        final mid = LatLng(
          (p.latitude + next.latitude) / 2,
          (p.longitude + next.longitude) / 2,
        );
        final dist = const Distance().as(LengthUnit.Meter, p, next);
        final distText = dist >= 1000
            ? '${(dist / 1000).toStringAsFixed(2)} km'
            : '${dist.toStringAsFixed(0)} m';

        markers.add(
          Marker(
            point: mid,
            width: 80,
            height: 24,
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, 8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withAlpha(150),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    distText,
                    style: const TextStyle(color: Colors.white, fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        );
      }
    }
    return markers;
  }

  List<Marker> _buildEditMarkers(DrawingGeometry? geometry) {
    if (geometry == null) return [];

    final markers = <Marker>[];

    if (geometry is DrawingPolygon) {
      for (int ringIdx = 0; ringIdx < geometry.coordinates.length; ringIdx++) {
        final ringRaw = geometry.coordinates[ringIdx];
        final ring = ringRaw.map((p) => LatLng(p[1], p[0])).toList();

        final isClosed =
            ring.isNotEmpty &&
            ring.first.latitude == ring.last.latitude &&
            ring.first.longitude == ring.last.longitude;

        final logicalLength = isClosed ? ring.length - 1 : ring.length;
        for (int i = 0; i < logicalLength; i++) {
          final p = ring[i];
          final isDragging =
              _dragMode == _HandleMode.edit &&
              _draggingRingIndex == ringIdx &&
              _draggingVertexIndex == i;
          final displayPoint =
              isDragging && _draggingPosition != null ? _draggingPosition! : p;

          markers.add(
            Marker(
              point: displayPoint,
              width: isDragging ? 56 : 20,
              height: isDragging ? 56 : 20,
              alignment:
                  isDragging ? Alignment.bottomCenter : Alignment.center,
              child: _InteractiveVertexHandle(
                keyId: 'drawing_vertex_${ringIdx}_$i',
                isDragging: isDragging,
                isStart: false,
                onPanStart: () => _startVertexDrag(
                  mode: _HandleMode.edit,
                  ringIndex: ringIdx,
                  pointIndex: i,
                  point: p,
                ),
                onPanUpdate: (details) => _updateVertexDrag(details, p),
                onPanEnd: _endVertexDrag,
                onPanCancel: _cancelVertexDrag,
                onDoubleTap: () => widget.controller.removeVertex(ringIdx, i),
              ),
            ),
          );

          LatLng? nextP;
          if (i < logicalLength - 1) {
            nextP = ring[i + 1];
          } else if (isClosed) {
            nextP = ring.first;
          }

          if (nextP != null) {
            final midLat = (p.latitude + nextP.latitude) / 2;
            final midLng = (p.longitude + nextP.longitude) / 2;
            final mid = LatLng(midLat, midLng);

            markers.add(
              Marker(
                point: mid,
                width: 16,
                height: 16,
                child: _MidpointHandle(
                  segmentIndex: i,
                  ringIndex: ringIdx,
                  point: mid,
                  controller: widget.controller,
                ),
                alignment: Alignment.center,
              ),
            );

            final dist = const Distance().as(LengthUnit.Meter, p, nextP);
            final distText = dist >= 1000
                ? '${(dist / 1000).toStringAsFixed(2)} km'
                : '${dist.toStringAsFixed(0)} m';

            markers.add(
              Marker(
                point: mid,
                width: 80,
                height: 30,
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: const Offset(0, 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(150),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        distText,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }
        }
      }
    }

    return markers;
  }
}

class _InteractiveVertexHandle extends StatelessWidget {
  final String keyId;
  final bool isDragging;
  final bool isStart;
  final VoidCallback onPanStart;
  final ValueChanged<DragUpdateDetails> onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onPanCancel;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;

  const _InteractiveVertexHandle({
    required this.keyId,
    required this.isDragging,
    required this.isStart,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
    this.onTap,
    this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key(keyId),
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onPanStart(),
      onPanUpdate: onPanUpdate,
      onPanEnd: (_) => onPanEnd(),
      onPanCancel: onPanCancel,
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      child: isDragging
          ? const DrawingVertexDragHandle()
          : AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: isStart ? 22 : 18,
              height: isStart ? 22 : 18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isStart ? Colors.green : Colors.grey.shade400,
                  width: isStart ? 2.5 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
    );
  }
}

class _MidpointHandle extends StatelessWidget {
  final int segmentIndex;
  final int ringIndex;
  final LatLng point;
  final DrawingController controller;

  const _MidpointHandle({
    required this.segmentIndex,
    required this.ringIndex,
    required this.point,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        controller.insertVertex(ringIndex, segmentIndex, point);
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
