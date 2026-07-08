import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../domain/drawing_state.dart';
import '../providers/drawing_provider.dart';

/// Captura gestos contínuos para freehand e preview de raio do pivô.
class DrawingMapGestureOverlay extends ConsumerWidget {
  const DrawingMapGestureOverlay({
    super.key,
    required this.mapController,
    required this.isMapReady,
  });

  final MapController mapController;
  final bool isMapReady;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(drawingControllerProvider);
    final captureFreehand = controller.currentTool == DrawingTool.freehand &&
        (controller.currentState == DrawingState.armed ||
            controller.currentState == DrawingState.drawing);
    final capturePivotRadius = controller.currentTool == DrawingTool.pivot &&
        controller.currentState == DrawingState.drawing &&
        controller.pivotCenter != null &&
        !controller.pivotRadiusFinalized;

    if (!captureFreehand && !capturePivotRadius) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (event) {
          if (!isMapReady) return;
          final point = _toLatLng(event.localPosition);
          if (point == null) return;

          if (captureFreehand) {
            controller.beginFreehandStroke(point);
          }
        },
        onPointerMove: (event) {
          if (!isMapReady) return;
          final point = _toLatLng(event.localPosition);
          if (point == null) return;

          if (captureFreehand && controller.isFreehandStrokeActive) {
            controller.extendFreehandStroke(point);
          } else if (capturePivotRadius) {
            controller.updatePivotEdge(point);
          }
        },
        onPointerUp: (event) {
          if (!isMapReady) return;
          if (captureFreehand && controller.isFreehandStrokeActive) {
            controller.endFreehandStroke();
            return;
          }
          if (capturePivotRadius) {
            final point = _toLatLng(event.localPosition);
            if (point != null) {
              controller.finalizePivotEdge(point);
            }
          }
        },
        onPointerCancel: (event) {
          if (captureFreehand && controller.isFreehandStrokeActive) {
            controller.endFreehandStroke();
            return;
          }
          if (capturePivotRadius) {
            final point = _toLatLng(event.localPosition);
            if (point != null) {
              controller.finalizePivotEdge(point);
            }
          }
        },
      ),
    );
  }

  LatLng? _toLatLng(Offset localPosition) {
    try {
      return mapController.camera.pointToLatLng(
        math.Point<double>(localPosition.dx, localPosition.dy),
      );
    } catch (_) {
      return null;
    }
  }
}
