import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/layout_constants.dart';
import '../../../core/state/map_ui_providers.dart';
import '../../../modules/drawing/domain/drawing_feature_actions_mode.dart';
import '../../../modules/drawing/domain/drawing_state.dart';
import '../../../modules/drawing/domain/models/drawing_models.dart';
import '../../../modules/drawing/presentation/drawing_compact_selection_actions.dart';
import '../../../modules/drawing/presentation/providers/drawing_provider.dart';
import 'map_sheet_state.dart';

/// Toolbar contextual (ícone + label curto) ancorada na feature selecionada
/// no fluxo compact — espírito Apple Maps.
class MapTalhaoSelectionToolbar extends ConsumerWidget {
  const MapTalhaoSelectionToolbar({
    super.key,
    required this.mapController,
    required this.setSheetState,
    this.onCollapseDrawSheet,
  });

  final MapController mapController;
  final void Function(MapSheetState? state, String reason) setSheetState;
  final VoidCallback? onCollapseDrawSheet;

  static const double toolbarHeight = 52;
  static const double horizontalPadding = 12;
  static const double edgeMargin = 8;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(drawingControllerProvider);
    final sheetIsDraw = ref.watch(
      mapSheetStateProvider.select((s) => s?.type == MapSheetType.draw),
    );

    if (!_shouldShow(controller, sheetIsDraw)) {
      return const SizedBox.shrink();
    }

    final feature = controller.selectedFeature!;
    ref.watch(mapCameraSnapshotProvider);

    final anchor = drawingFeatureAnchorLatLng(feature);
    if (anchor == null) return const SizedBox.shrink();

    final screenPoint = mapController.camera.latLngToScreenPoint(anchor);
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final toolbarWidth = _estimateToolbarWidth(feature);
    final offset = clampMapToolbarOffset(
      screenPoint: Offset(screenPoint.x, screenPoint.y),
      viewportSize: size,
      toolbarWidth: toolbarWidth,
      toolbarHeight: toolbarHeight,
      topInset: topInset,
      bottomInset: bottomInset,
      edgeMargin: edgeMargin,
    );

    final showNdvi = feature.id.isNotEmpty;

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Material(
        elevation: 6,
        shadowColor: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(14),
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xF2FFFFFF),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.08),
                ),
              ),
              child: SizedBox(
                height: toolbarHeight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ToolbarChip(
                      key: const Key('map_talhao_toolbar_edit_geometry'),
                      icon: Icons.edit_location_alt_outlined,
                      label: 'Geometria',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        DrawingCompactSelectionActions.editGeometry(controller);
                      },
                    ),
                    _divider,
                    _ToolbarChip(
                      key: const Key('map_talhao_toolbar_edit_metadata'),
                      icon: Icons.edit_note_outlined,
                      label: 'Dados',
                      onTap: () {
                        HapticFeedback.lightImpact();
                        DrawingCompactSelectionActions.requestMetadataSheet(ref);
                        setSheetState(
                          const MapSheetState(type: MapSheetType.draw),
                          'compact toolbar: edit metadata',
                        );
                      },
                    ),
                    if (showNdvi) ...[
                      _divider,
                      _ToolbarChip(
                        key: const Key('map_talhao_toolbar_ndvi'),
                        icon: Icons.grass_rounded,
                        label: 'NDVI',
                        onTap: () {
                          HapticFeedback.lightImpact();
                          DrawingCompactSelectionActions.showNdviMap(
                            ref,
                            feature,
                            onCollapseWhileEditing: onCollapseDrawSheet,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const Widget _divider = SizedBox(
    width: 1,
    height: 28,
    child: DecoratedBox(
      decoration: BoxDecoration(color: Color(0x1A000000)),
    ),
  );

  static bool _shouldShow(DrawingController controller, bool sheetIsDraw) {
    if (sheetIsDraw) return false;
    if (controller.isMultiSelectEnabled) return false;
    if (controller.featureActionsMode != DrawingFeatureActionsMode.compact) {
      return false;
    }
    if (controller.currentState != DrawingState.selected) return false;
    if (controller.interactionMode != DrawingInteraction.normal) return false;
    return controller.selectedFeature != null;
  }

  static double _estimateToolbarWidth(DrawingFeature feature) {
    const chipWidth = 76.0;
    final chips = feature.id.isNotEmpty ? 3 : 2;
    return chips * chipWidth + (chips - 1);
  }
}

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1D1D1F)),
              const SizedBox(height: 2),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1D1D1F),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Centroide simples do polígono para ancorar a toolbar.
LatLng? drawingFeatureAnchorLatLng(DrawingFeature feature) {
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

  if (points.isEmpty) return null;

  var sumLat = 0.0;
  var sumLng = 0.0;
  for (final p in points) {
    sumLat += p.latitude;
    sumLng += p.longitude;
  }
  return LatLng(sumLat / points.length, sumLng / points.length);
}

/// Posiciona a toolbar acima do ponto de ancoragem, com clamp nas bordas.
Offset clampMapToolbarOffset({
  required Offset screenPoint,
  required Size viewportSize,
  required double toolbarWidth,
  required double toolbarHeight,
  double topInset = 0,
  double bottomInset = 0,
  double edgeMargin = MapTalhaoSelectionToolbar.edgeMargin,
  double anchorGap = 12,
}) {
  var left = screenPoint.dx - toolbarWidth / 2;
  var top = screenPoint.dy - toolbarHeight - anchorGap;

  final minLeft = edgeMargin;
  final rightColumnReserve =
      kMapActionColumnRightInset + kMapActionColumnButtonSize;
  final maxLeft = math.max(
    edgeMargin,
    viewportSize.width -
        toolbarWidth -
        edgeMargin -
        rightColumnReserve,
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

  left = left.clamp(minLeft, maxLeft);
  top = top.clamp(minTop, maxTop);

  return Offset(left, top);
}
