import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';

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

  /// Altura reservada para toolbar de desenho + chips de medição (safe area extra).
  static const double _bottomChromeReserve =
      kDrawingBottomToolbarHeight + 56;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(drawingControllerProvider);
    final captureFreehand =
        controller.currentTool == DrawingTool.freehand &&
        (controller.currentState == DrawingState.armed ||
            controller.currentState == DrawingState.drawing);
    final capturePivotRadius =
        controller.currentTool == DrawingTool.pivot &&
        controller.currentState == DrawingState.drawing &&
        controller.pivotCenter != null;

    if (!captureFreehand && !capturePivotRadius) {
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
              if (!isMapReady) return;
              if (_isMapChromePointer(
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
          );
        },
      ),
    );
  }

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

  /// Evita que toques na toolbar inferior ou na coluna direita iniciem freehand.
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
      if (fromBottom <= safeBottom + _bottomChromeReserve &&
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
