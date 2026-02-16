import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'dart:math' as math; // For Point
import '../../presentation/controllers/drawing_controller.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/drawing_state.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

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
  // To avoid creating too many objects, we can optimize here if needed.
  // For now, reactive rebuild is fine for typical field sizes (< 100 points).

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final state = widget.controller.currentState;
        final isEditing = state == DrawingState.editing;

        // Only show handles if editing
        if (!isEditing) return const SizedBox.shrink();

        final geometry = widget.controller.liveGeometry;
        return MarkerLayer(markers: _buildMarkers(geometry));
      },
    );
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

        for (int i = 0; i < ring.length; i++) {
          // Skip last point if closed (duplicate of first)
          if (isClosed && i == ring.length - 1) continue;

          final p = ring[i];

          // Vertex Handle
          markers.add(
            Marker(
              point: p,
              width: 24,
              height: 24,
              child: _VertexHandle(
                index: i,
                ringIndex: ringIdx,
                point: p,
                controller: widget.controller,
                mapController: widget.mapController,
              ),
              alignment: Alignment.center,
            ),
          );

          // Midpoint Handle (Insertion point)
          // Look ahead to next point (or wrap to first if closed)
          LatLng? nextP;

          if (i < ring.length - 1) {
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
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      textAlign: TextAlign.center,
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
  final LatLng point;
  final DrawingController controller;
  final MapController mapController;

  const _VertexHandle({
    required this.index,
    required this.ringIndex,
    required this.point,
    required this.controller,
    required this.mapController,
  });

  @override
  Widget build(BuildContext context) {
    // Detect if this specific vertex is being dragged
    final isDragging =
        controller.isDraggingVertex && controller.draggedVertexIndex == index;

    return GestureDetector(
      // 1. Enable Dragging
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) => controller.onDragStart(index),
      onPanUpdate: (details) {
        // Current point on screen
        final pointScreen = mapController.camera.latLngToScreenPoint(point);
        // Add delta
        final newScreen = math.Point(
          pointScreen.x + details.delta.dx,
          pointScreen.y + details.delta.dy,
        );
        // Back to LatLng
        final newLatLng = mapController.camera.pointToLatLng(newScreen);

        controller.moveVertex(ringIndex, index, newLatLng);
      },
      onPanEnd: (_) => controller.onDragEnd(),
      onPanCancel: () => controller.onDragEnd(),
      onDoubleTap: () {
        controller.removeVertex(ringIndex, index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        width: isDragging ? 32 : 24,
        height: isDragging ? 32 : 24,
        decoration: BoxDecoration(
          color: isDragging ? SoloForteColors.primary : Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: isDragging ? Colors.white : Colors.black26,
            width: isDragging ? 3 : 2,
          ),
          boxShadow: [
            BoxShadow(
              color: isDragging
                  ? SoloForteColors.primary.withOpacity(0.4)
                  : Colors.black.withOpacity(0.3),
              blurRadius: isDragging ? 10 : 4,
              offset: Offset(0, isDragging ? 4 : 2),
              spreadRadius: isDragging ? 2 : 0,
            ),
          ],
        ),
        child: isDragging
            ? const Center(
                child: Icon(Icons.open_with, size: 14, color: Colors.white),
              )
            : null,
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
          color: Colors.white.withOpacity(0.8),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black26, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }
}
