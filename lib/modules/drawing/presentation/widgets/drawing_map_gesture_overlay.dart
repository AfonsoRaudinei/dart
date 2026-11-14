import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';

import '../../domain/drawing_state.dart';
import '../../domain/drawing_utils.dart';
import '../../domain/models/drawing_models.dart';
import '../providers/drawing_provider.dart';

/// Captura gestos contínuos para freehand, raio do pivô e arraste do círculo.
class DrawingMapGestureOverlay extends ConsumerStatefulWidget {
  const DrawingMapGestureOverlay({
    super.key,
    required this.mapController,
    required this.isMapReady,
  });

  final MapController mapController;
  final bool isMapReady;

  /// Altura reservada para toolbar de desenho + chips de medição (safe area extra).
  static const double bottomChromeReserve = kDrawingBottomToolbarHeight + 56;

  @visibleForTesting
  static bool excludesMapChromePointer(
    Offset local,
    Size size, {
    required double safeBottom,
    DrawingState drawingState = DrawingState.drawing,
  }) =>
      _isMapChromePointer(
        local,
        size,
        safeBottom: safeBottom,
        drawingState: drawingState,
      );

  static bool _isMapChromePointer(
    Offset local,
    Size size, {
    required double safeBottom,
    required DrawingState drawingState,
  }) {
    final fromBottom = size.height - local.dy;
    final showsBottomToolbar =
        drawingState == DrawingState.drawing ||
        drawingState == DrawingState.editing;

    if (showsBottomToolbar) {
      if (fromBottom <= safeBottom + bottomChromeReserve &&
          local.dx >= 16 &&
          local.dx <= size.width - kDrawingBottomToolbarRightInset) {
        return true;
      }
    }

    final columnWidth =
        kMapActionColumnRightInset + kMapActionColumnButtonSize + 8;
    if (local.dx < size.width - columnWidth) {
      return false;
    }

    final drawModeColumn =
        drawingState == DrawingState.drawing ||
        drawingState == DrawingState.editing ||
        drawingState == DrawingState.armed;
    final columnStackHeight = drawModeColumn
        ? kMapActionColumnButtonSize
        : kMapActionColumnButtonSize +
            kMapActionColumnSpacingAboveCheckIn +
            kMapActionColumnButtonSize;
    final columnBottom = safeBottom + kMapActionColumnBottomInset;
    if (fromBottom <= columnBottom + columnStackHeight + 8) {
      return true;
    }

    return false;
  }

  @override
  ConsumerState<DrawingMapGestureOverlay> createState() =>
      _DrawingMapGestureOverlayState();
}

class _DrawingMapGestureOverlayState
    extends ConsumerState<DrawingMapGestureOverlay> {
  bool _pivotBodyDrag = false;

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(drawingControllerProvider);
    final captureFreehand =
        controller.currentTool == DrawingTool.freehand &&
        (controller.currentState == DrawingState.armed ||
            controller.currentState == DrawingState.drawing);
    final capturePivotRadius =
        controller.currentTool == DrawingTool.pivot &&
        controller.currentState == DrawingState.drawing &&
        controller.pivotCenter != null &&
        !controller.pivotRadiusFinalized;
    final capturePivotBodyMove =
        controller.currentTool == DrawingTool.pivot &&
        controller.currentState == DrawingState.drawing &&
        controller.pivotAdjustUiVisible;

    if (!captureFreehand && !capturePivotRadius && !capturePivotBodyMove) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          final safeBottom = MediaQuery.paddingOf(context).bottom;

          return Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (!widget.isMapReady) return;
              if (DrawingMapGestureOverlay._isMapChromePointer(
                event.localPosition,
                size,
                safeBottom: safeBottom,
                drawingState: controller.currentState,
              )) {
                return;
              }
              final point = _toLatLng(event.localPosition);
              if (point == null) return;

              if (captureFreehand) {
                controller.beginFreehandStroke(point);
                return;
              }
              if (capturePivotBodyMove &&
                  _isInsidePivotSketch(controller, point)) {
                setState(() => _pivotBodyDrag = true);
                controller.beginPivotHandleDrag();
              }
            },
            onPointerMove: (event) {
              if (!widget.isMapReady) return;
              final point = _toLatLng(event.localPosition);
              if (point == null) return;

              if (captureFreehand && controller.isFreehandStrokeActive) {
                controller.extendFreehandStroke(point);
              } else if (capturePivotRadius) {
                controller.updatePivotEdge(point);
              } else if (_pivotBodyDrag) {
                controller.movePivotCenter(point);
              }
            },
            onPointerUp: (event) {
              if (!widget.isMapReady) return;
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
              _endPivotBodyDrag(controller);
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
              _endPivotBodyDrag(controller);
            },
          );
        },
      ),
    );
  }

  void _endPivotBodyDrag(DrawingController controller) {
    if (!_pivotBodyDrag) return;
    setState(() => _pivotBodyDrag = false);
    controller.endPivotHandleDrag();
  }

  static bool _isInsidePivotSketch(DrawingController controller, LatLng point) {
    final geometry = controller.liveGeometry;
    if (geometry is! DrawingPolygon) return false;
    if (geometry.coordinates.isEmpty) return false;
    return DrawingUtils.isPointInPolygon(point, geometry.coordinates.first);
  }

  LatLng? _toLatLng(Offset localPosition) {
    try {
      return widget.mapController.camera.pointToLatLng(
        math.Point<double>(localPosition.dx, localPosition.dy),
      );
    } catch (_) {
      return null;
    }
  }
}