import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/drawing_state.dart';
import '../../domain/models/drawing_models.dart';
import '../../presentation/controllers/drawing_controller.dart';
import 'vertex_handle_drag_preview.dart';

class DrawingEditLayer extends StatefulWidget {
  final DrawingController controller;
  final MapController mapController;

  const DrawingEditLayer({
    super.key,
    required this.controller,
    required this.mapController,
  });

  @override
  State<DrawingEditLayer> createState() => _DrawingEditLayerState();
}

class _DrawingEditLayerState extends State<DrawingEditLayer> {
  VertexHandleDrag? get _drag => widget.controller.vertexDragPreview.drag;

  List<LatLng> _sketchDisplayPoints() {
    final points = List<LatLng>.from(widget.controller.currentPoints);
    final drag = _drag;
    if (drag != null &&
        drag.isSketch &&
        drag.pointIndex >= 0 &&
        drag.pointIndex < points.length) {
      points[drag.pointIndex] = drag.position;
    }
    return points;
  }

  List<Polyline> _buildSketchDragPreview(List<LatLng> points) {
    final drag = _drag;
    if (drag == null || !drag.isSketch || points.length < 2) return const [];
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

  DrawingGeometry? _resolveDisplayGeometry(DrawingGeometry? original) {
    final drag = _drag;
    if (drag == null || drag.isSketch || original is! DrawingPolygon) {
      return original;
    }

    final ringIndex = drag.ringIndex;
    final pointIndex = drag.pointIndex;
    final pos = drag.position;

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
    final drag = _drag;
    if (drag == null || drag.isSketch || geometry is! DrawingPolygon) {
      return const [];
    }
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
    final drag = _drag;
    if (drag == null || drag.isSketch || geometry is! DrawingPolygon) {
      return const [];
    }

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
      listenable: Listenable.merge([
        widget.controller,
        widget.controller.vertexDragPreview,
      ]),
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

        if (!isEditing) {
          if (widget.controller.selectedEditRingIndex != null ||
              widget.controller.selectedEditPointIndex != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              widget.controller.clearEditVertexSelection();
            });
          }
          return const SizedBox.shrink();
        }

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
      final isDragging =
          _drag != null && _drag!.isSketch && _drag!.pointIndex == i;
      final isStart = i == 0;
      final showGota = isSelected || isDragging;
      final dotSize = isStart ? 20.0 : 16.0;

      // Marker tamanho fixo + ponta no LatLng (bottomCenter no flutter_map 7:
      // LatLng = topo do widget; gota/círculo idle descem a partir do vértice).
      // O pan mora no overlay acima do mapa — o marker só desenha.
      markers.add(
        Marker(
          point: point,
          width: _VertexGotaMetrics.width,
          height: _VertexGotaMetrics.height,
          alignment: Alignment.bottomCenter,
          child: IgnorePointer(
            child: _SketchVertexHandle(
              index: i,
              isStart: isStart,
              isSelected: showGota,
              isDragging: isDragging,
              dotSize: dotSize,
              hasSelfIntersection:
                  isStart && widget.controller.hasSelfIntersection,
            ),
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
              _drag != null &&
              !_drag!.isSketch &&
              _drag!.ringIndex == ringIdx &&
              _drag!.pointIndex == i;
          final isSelected =
              widget.controller.selectedEditRingIndex == ringIdx &&
              widget.controller.selectedEditPointIndex == i;
          final showGota = isSelected || isDragging;

          // Marker tamanho fixo (gota) para não recriar o hit-target no meio
          // do pan quando o visual troca ponto → gota.
          markers.add(
            Marker(
              point: p,
              width: _VertexGotaMetrics.width,
              height: _VertexGotaMetrics.height,
              alignment: Alignment.bottomCenter,
              child: IgnorePointer(
                child: _EditVertexGotaHandle(
                  ringIndex: ringIdx,
                  index: i,
                  isSelected: showGota,
                  isDragging: isDragging,
                ),
              ),
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
                alignment: Alignment.bottomCenter,
                child: IgnorePointer(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
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

class _EditVertexGotaHandle extends StatelessWidget {
  final int index;
  final int ringIndex;
  final bool isSelected;
  final bool isDragging;

  const _EditVertexGotaHandle({
    required this.index,
    required this.ringIndex,
    required this.isSelected,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: Key('drawing_vertex_${ringIndex}_$index'),
      width: _VertexGotaMetrics.width,
      height: _VertexGotaMetrics.height,
      child: isSelected
          ? _VertexGotaVisual(
              key: Key('drawing_vertex_drag_${ringIndex}_$index'),
              isDragging: isDragging,
            )
          : const _VertexIdleDot(),
    );
  }
}

/// Dimensões canônicas da gota ponta-cima (LatLng = topo do marker via bottomCenter).
class _VertexGotaMetrics {
  static const double width = 56;
  static const double height = 78;
  static const Color fill = Color(0xB3C62828);
  static const Color fillDragging = Color(0xD9E53935);
}

/// Ponto branco idle centrado no vértice (topo do marker = LatLng via bottomCenter).
class _VertexIdleDot extends StatelessWidget {
  final double size;
  final Color color;
  final Color borderColor;
  final double borderWidth;

  const _VertexIdleDot({
    this.size = 20,
    this.color = Colors.white,
    this.borderColor = const Color(0xFFBDBDBD),
    this.borderWidth = 1.5,
  });

  @override
  Widget build(BuildContext context) {
    // Topo do círculo no vértice (y ≈ 0.5, mesma referência da ponta da gota).
    // Centro em Offset(0, size/2) — corpo inteiro dentro do hitbox do marker.
    return Align(
      alignment: Alignment.topCenter,
      child: Padding(
        padding: const EdgeInsets.only(top: 0.5),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: borderWidth),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Visual compartilhado: gota invertida (ponta no mapa, cruz no corpo).
class _VertexGotaVisual extends StatelessWidget {
  final bool isDragging;

  const _VertexGotaVisual({
    super.key,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GotaCruzPainter(
        color: isDragging
            ? _VertexGotaMetrics.fillDragging
            : _VertexGotaMetrics.fill,
      ),
      child: const Align(
        // Cruz no corpo (abaixo da ponta) — onde fica o dedo.
        alignment: Alignment(0, 0.42),
        child: Icon(
          Icons.open_with,
          color: Colors.white,
          size: 22,
        ),
      ),
    );
  }
}

/// Gota com ponta para cima ancorada no vértice (ref. app exemplo img 2).
///
/// No flutter_map 7, `Alignment.bottomCenter` ancora o LatLng no topo do widget;
/// a ponta da gota e o ponto idle coincidem com o vértice. O corpo fica abaixo
/// para o dedo não cobrir o ponto do mapa enquanto arrasta.
class _GotaCruzPainter extends CustomPainter {
  final Color color;

  const _GotaCruzPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final path = ui.Path();
    // Ponta afiada no topo = ponto do mapa (visível sem soltar o dedo).
    final tip = Offset(size.width / 2, 0.5);
    final bodyCy = size.height * 0.68;
    final bodyR = size.width * 0.40;

    path.moveTo(tip.dx, tip.dy);
    path.quadraticBezierTo(
      size.width * 0.08,
      size.height * 0.22,
      tip.dx - bodyR,
      bodyCy,
    );
    path.arcToPoint(
      Offset(tip.dx + bodyR, bodyCy),
      radius: Radius.circular(bodyR),
      clockwise: false,
    );
    path.quadraticBezierTo(
      size.width * 0.92,
      size.height * 0.22,
      tip.dx,
      tip.dy,
    );
    path.close();

    canvas.drawShadow(path, Colors.black.withValues(alpha: 0.4), 8, true);
    canvas.drawPath(path, paint);

    final border = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..isAntiAlias = true;
    canvas.drawPath(path, border);
  }

  @override
  bool shouldRepaint(covariant _GotaCruzPainter oldDelegate) =>
      oldDelegate.color != color;
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

/// Handle mid-draw: idle = ponto; selecionado = gota ponta-cima (mesmo contrato da edição).
class _SketchVertexHandle extends StatelessWidget {
  final int index;
  final bool isStart;
  final bool isSelected;
  final bool isDragging;
  final double dotSize;
  final bool hasSelfIntersection;

  const _SketchVertexHandle({
    required this.index,
    required this.isStart,
    required this.isSelected,
    required this.isDragging,
    required this.dotSize,
    required this.hasSelfIntersection,
  });

  @override
  Widget build(BuildContext context) {
    final dotColor = isStart && hasSelfIntersection
        ? Colors.red.withValues(alpha: 0.5)
        : Colors.white;
    final borderColor = isStart
        ? (hasSelfIntersection ? Colors.red : Colors.green)
        : Colors.grey.shade400;

    return SizedBox(
      key: Key('drawing_sketch_vertex_$index'),
      width: _VertexGotaMetrics.width,
      height: _VertexGotaMetrics.height,
      child: isSelected
          ? _VertexGotaVisual(
              key: Key('drawing_sketch_vertex_drag_$index'),
              isDragging: isDragging,
            )
          : _VertexIdleDot(
              size: dotSize,
              color: dotColor,
              borderColor: borderColor,
              borderWidth: isStart ? 2 : 1.5,
            ),
    );
  }
}
