import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/drawing_state.dart';
import '../../domain/models/drawing_models.dart';
import '../../presentation/controllers/drawing_controller.dart';

class DrawingEditLayer extends StatefulWidget {
  final DrawingController controller;
  final MapController mapController;

  /// Fecha o polígono em sketch (2º toque no vértice inicial selecionado).
  final VoidCallback? onPolygonClose;

  const DrawingEditLayer({
    super.key,
    required this.controller,
    required this.mapController,
    this.onPolygonClose,
  });

  @override
  State<DrawingEditLayer> createState() => _DrawingEditLayerState();
}

class _DrawingEditLayerState extends State<DrawingEditLayer> {
  int? _draggingVertexIndex;
  int? _draggingRingIndex;
  LatLng? _draggingPosition;
  bool _isSketchDrag = false;

  bool get _isDragging =>
      _draggingVertexIndex != null &&
      _draggingRingIndex != null &&
      _draggingPosition != null;

  void _startVertexDrag({
    required int ringIndex,
    required int pointIndex,
    required LatLng point,
  }) {
    setState(() {
      _draggingRingIndex = ringIndex;
      _draggingVertexIndex = pointIndex;
      _draggingPosition = point;
    });
    widget.controller.onDragStart(pointIndex);
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
  }

  void _endVertexDrag() {
    final ringIndex = _draggingRingIndex;
    final pointIndex = _draggingVertexIndex;
    final position = _draggingPosition;
    final wasSketch = _isSketchDrag;

    if (ringIndex != null && pointIndex != null && position != null) {
      if (wasSketch) {
        widget.controller.moveSketchVertex(pointIndex, position);
        widget.controller.endSketchVertexDrag();
      } else {
        widget.controller.updateVertexPosition(ringIndex, pointIndex, position);
        widget.controller.onDragEnd(persist: false);
      }
    } else if (wasSketch) {
      widget.controller.endSketchVertexDrag();
    } else {
      widget.controller.onDragEnd(persist: false);
    }

    setState(() {
      _draggingRingIndex = null;
      _draggingVertexIndex = null;
      _draggingPosition = null;
      _isSketchDrag = false;
    });
  }

  void _cancelVertexDrag() {
    if (_isSketchDrag) {
      widget.controller.endSketchVertexDrag();
    } else {
      widget.controller.onDragEnd(persist: false);
    }
    setState(() {
      _draggingRingIndex = null;
      _draggingVertexIndex = null;
      _draggingPosition = null;
      _isSketchDrag = false;
    });
  }

  void _startSketchVertexDrag({
    required int pointIndex,
    required LatLng point,
  }) {
    setState(() {
      _isSketchDrag = true;
      _draggingRingIndex = 0;
      _draggingVertexIndex = pointIndex;
      _draggingPosition = point;
    });
    widget.controller.beginSketchVertexDrag(pointIndex);
  }

  void _updateSketchVertexDrag(DragUpdateDetails details, LatLng fallbackPoint) {
    if (!_isDragging || !_isSketchDrag) return;

    final basePoint = _draggingPosition ?? fallbackPoint;
    final screenPoint = widget.mapController.camera.latLngToScreenPoint(
      basePoint,
    );
    final movedPoint = math.Point<double>(
      screenPoint.x + details.delta.dx,
      screenPoint.y + details.delta.dy,
    );
    final newLatLng = widget.mapController.camera.pointToLatLng(movedPoint);
    // Só estado local durante o pan — evitar notify do controller (cancela gesto).
    setState(() => _draggingPosition = newLatLng);
  }

  List<LatLng> _sketchDisplayPoints() {
    final points = List<LatLng>.from(widget.controller.currentPoints);
    if (_isSketchDrag &&
        _draggingVertexIndex != null &&
        _draggingPosition != null &&
        _draggingVertexIndex! >= 0 &&
        _draggingVertexIndex! < points.length) {
      points[_draggingVertexIndex!] = _draggingPosition!;
    }
    return points;
  }

  List<Polyline> _buildSketchDragPreview(List<LatLng> points) {
    if (!_isSketchDrag || points.length < 2) return const [];
    final preview = List<LatLng>.from(points);
    if (preview.length >= 3) {
      preview.add(preview.first);
    }
    return [
      Polyline(
        points: preview,
        color: const Color(0xE6E53935),
        strokeWidth: 3,
      ),
    ];
  }

  void _onSketchVertexTap(int index) {
    final controller = widget.controller;
    final alreadySelected = controller.selectedSketchVertexIndex == index;
    if (index == 0 &&
        alreadySelected &&
        controller.canFinishDrawing &&
        !controller.hasSelfIntersection) {
      widget.onPolygonClose?.call();
      return;
    }
    controller.selectSketchVertex(index);
  }

  DrawingGeometry? _resolveDisplayGeometry(DrawingGeometry? original) {
    if (!_isDragging || original is! DrawingPolygon) return original;

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
        color: const Color(0xFFFF6B00).withValues(alpha: 0.12),
        borderColor: const Color(0xFFFF6B00),
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
          color: const Color(0xFFFF6B00),
          strokeWidth: 3,
        ),
      );
    }
    return lines;
  }

  bool get _isSketchVertexMode {
    final c = widget.controller;
    return c.currentTool == DrawingTool.polygon &&
        (c.currentState == DrawingState.drawing ||
            c.currentState == DrawingState.armed) &&
        c.currentPoints.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.currentState;
        final isEditing = state == DrawingState.editing;

        if (_isSketchVertexMode) {
          final sketchPoints = _sketchDisplayPoints();
          final preview = _buildSketchDragPreview(sketchPoints);
          return Stack(
            children: [
              if (preview.isNotEmpty) PolylineLayer(polylines: preview),
              MarkerLayer(markers: _buildSketchMarkers(sketchPoints)),
            ],
          );
        }

        if (!isEditing) return const SizedBox.shrink();

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
            MarkerLayer(markers: _buildMarkers(displayGeometry)),
          ],
        );
      },
    );
  }

  List<Marker> _buildSketchMarkers(List<LatLng> points) {
    final selected = widget.controller.selectedSketchVertexIndex;
    final markers = <Marker>[];

    for (var i = 0; i < points.length; i++) {
      final point = points[i];
      final isSelected = selected == i;
      final isDragging = _isSketchDrag && _draggingVertexIndex == i;
      final isStart = i == 0;
      final showGota = isSelected || isDragging;

      // Tamanho/alignment fixos: trocar layout no panStart cancela o gesto.
      markers.add(
        Marker(
          point: point,
          width: 56,
          height: 72,
          alignment: Alignment.bottomCenter,
          child: _SketchVertexHandle(
            index: i,
            isStart: isStart,
            isSelected: showGota,
            hasSelfIntersection:
                isStart && widget.controller.hasSelfIntersection,
            onTap: () => _onSketchVertexTap(i),
            onPanStart: () => _startSketchVertexDrag(
              pointIndex: i,
              point: point,
            ),
            onPanUpdate: (details) => _updateSketchVertexDrag(details, point),
            onPanEnd: _endVertexDrag,
            onPanCancel: _cancelVertexDrag,
          ),
        ),
      );
    }

    return markers;
  }

  List<Marker> _buildMarkers(DrawingGeometry? geometry) {
    if (geometry == null) return [];

    final markers = <Marker>[];

    if (geometry is DrawingPolygon) {
      for (int ringIdx = 0; ringIdx < geometry.coordinates.length; ringIdx++) {
        final ringRaw = geometry.coordinates[ringIdx];

        // Convert raw to LatLng list for easier handling
        final ring = ringRaw.map((p) => LatLng(p[1], p[0])).toList();

        final isClosed =
            ring.isNotEmpty &&
            ring.first.latitude == ring.last.latitude &&
            ring.first.longitude == ring.last.longitude;

        final logicalLength = isClosed ? ring.length - 1 : ring.length;
        for (int i = 0; i < logicalLength; i++) {
          final p = ring[i];
          final isDragging =
              _draggingRingIndex == ringIdx && _draggingVertexIndex == i;

          // Vertex Handle
          markers.add(
            Marker(
              point: p,
              width: isDragging ? 28 : 20,
              height: isDragging ? 28 : 20,
              child: _VertexHandle(
                index: i,
                ringIndex: ringIdx,
                isDragging: isDragging,
                onPanStart: () => _startVertexDrag(
                  ringIndex: ringIdx,
                  pointIndex: i,
                  point: p,
                ),
                onPanUpdate: (details) => _updateVertexDrag(details, p),
                onPanEnd: _endVertexDrag,
                onPanCancel: _cancelVertexDrag,
                onDoubleTap: () => widget.controller.removeVertex(ringIdx, i),
              ),
              alignment: Alignment.center,
            ),
          );

          // Midpoint Handle (Insertion point)
          // Look ahead to next point (or wrap to first if closed)
          LatLng? nextP;

          if (i < logicalLength - 1) {
            nextP = ring[i + 1];
          } else if (isClosed) {
            // If closed, the last point IS the first.
            // So segment (last-1) -> (last) is effectively (last-1) -> (first).
            // Since we skipped loop for 'last', the segment from 'last-1' needs coverage.
            // i is last-1. next is last (which is same as first).
            nextP = ring.first;
          }

          if (nextP != null) {
            final midLat = (p.latitude + nextP.latitude) / 2;
            final midLng = (p.longitude + nextP.longitude) / 2;
            final mid = LatLng(midLat, midLng);

            // Midpoint Insert Handle
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

            // Segment Distance Label
            final dist = const Distance().as(LengthUnit.Meter, p, nextP);
            final distText = dist >= 1000
                ? '${(dist / 1000).toStringAsFixed(2)} km'
                : '${dist.toStringAsFixed(0)} m';

            markers.add(
              Marker(
                point: mid,
                width: 80,
                height: 30, // Enough for text
                alignment: Alignment.topCenter,
                child: IgnorePointer(
                  child: Transform.translate(
                    offset: const Offset(0, 10), // Push below midpoint
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

class _VertexHandle extends StatelessWidget {
  final int index;
  final int ringIndex;
  final bool isDragging;
  final VoidCallback onPanStart;
  final ValueChanged<DragUpdateDetails> onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onPanCancel;
  final VoidCallback onDoubleTap;

  const _VertexHandle({
    required this.index,
    required this.ringIndex,
    required this.isDragging,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: Key('drawing_vertex_${ringIndex}_$index'),
      // TODO(drawing): V2 bloquear pan/zoom do mapa durante drag de vértice.
      // V1: GestureDetector do marker já permite arraste funcional.
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => onPanStart(),
      onPanUpdate: onPanUpdate,
      onPanEnd: (_) => onPanEnd(),
      onPanCancel: onPanCancel,
      onDoubleTap: onDoubleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: isDragging ? 28 : 20,
        height: isDragging ? 28 : 20,
        decoration: BoxDecoration(
          color: isDragging ? const Color(0xFFFF6B00) : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDragging ? const Color(0xFFCC5500) : Colors.grey.shade400,
            width: isDragging ? 2.5 : 1.5,
          ),
          boxShadow: isDragging
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6B00).withValues(alpha: 0.4),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ]
              : [
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

/// Handle mid-draw: círculo branco, ou gota + cruz quando selecionado.
class _SketchVertexHandle extends StatelessWidget {
  final int index;
  final bool isStart;
  final bool isSelected;
  final bool hasSelfIntersection;
  final VoidCallback onTap;
  final VoidCallback onPanStart;
  final ValueChanged<DragUpdateDetails> onPanUpdate;
  final VoidCallback onPanEnd;
  final VoidCallback onPanCancel;

  const _SketchVertexHandle({
    required this.index,
    required this.isStart,
    required this.isSelected,
    required this.hasSelfIntersection,
    required this.onTap,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
    required this.onPanCancel,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isStart && hasSelfIntersection
        ? Colors.red.withValues(alpha: 0.5)
        : Colors.white;
    final borderColor = isStart
        ? (hasSelfIntersection ? Colors.red : Colors.green)
        : Colors.black26;

    return GestureDetector(
      key: Key('drawing_sketch_vertex_$index'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      onPanStart: (_) => onPanStart(),
      onPanUpdate: onPanUpdate,
      onPanEnd: (_) => onPanEnd(),
      onPanCancel: onPanCancel,
      child: SizedBox(
        width: 56,
        height: 72,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            // Mesma árvore sempre — só opacidade muda (preserva gesto de pan).
            Opacity(
              opacity: isSelected ? 1 : 0,
              child: const IgnorePointer(
                child: CustomPaint(
                  size: Size(56, 72),
                  painter: _TeardropPainter(color: Color(0xE6E53935)),
                  child: Align(
                    alignment: Alignment(0, -0.22),
                    child: Icon(
                      Icons.open_with,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),
            ),
            Opacity(
              opacity: isSelected ? 0 : 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Container(
                  width: isStart ? 20 : 16,
                  height: isStart ? 20 : 16,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: borderColor,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _TeardropPainter extends CustomPainter {
  final Color color;

  const _TeardropPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final w = size.width;
    final h = size.height;
    final cx = w / 2;
    final r = w * 0.42;
    final cy = h * 0.38;

    final path = ui.Path()
      ..moveTo(cx, h * 0.96)
      ..quadraticBezierTo(cx + r * 0.15, cy + r * 0.85, cx + r, cy)
      ..arcToPoint(
        Offset(cx - r, cy),
        radius: Radius.circular(r),
        largeArc: true,
        clockwise: true,
      )
      ..quadraticBezierTo(cx - r * 0.15, cy + r * 0.85, cx, h * 0.96)
      ..close();

    canvas.drawShadow(path, Colors.black54, 4, true);
    canvas.drawPath(path, paint);
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _TeardropPainter oldDelegate) =>
      oldDelegate.color != color;
}
