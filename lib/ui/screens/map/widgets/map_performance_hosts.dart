// Fase 1 — hosts isolados para reduzir rebuild cascade no mapa privado.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/state/map_ui_providers.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../modules/drawing/domain/models/drawing_models.dart';
import '../../../../modules/drawing/domain/models/gps_walk_session.dart';
import '../../../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../../../modules/drawing/presentation/providers/gps_walk_providers.dart';
import '../../../../modules/drawing/presentation/widgets/gps_walk_controls_overlay.dart';
import '../../../../modules/drawing/presentation/widgets/gps_tracking_overlay.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/visitas/presentation/controllers/geofence_controller.dart';
import '../../../components/map/map_bottom_sheet.dart';
import '../../../components/map/map_sheet_state.dart';
import '../providers/map_ready_state_provider.dart';

/// Mantém GeofenceController ativo sem rebuildar o orchestrator.
class MapGeofenceLifecycleHost extends ConsumerWidget {
  const MapGeofenceLifecycleHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(geofenceControllerProvider);
    return const SizedBox.shrink();
  }
}

/// Side-effects de viewport inicial — sem rebuild visual.
class MapInitialViewportListener extends ConsumerWidget {
  const MapInitialViewportListener({super.key, required this.applyInitialViewport});

  final VoidCallback applyInitialViewport;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(mapFieldsProvider, (prev, next) {
      final vp = ref.read(viewportStateProvider);
      if (vp != InitialViewportState.applied &&
          vp != InitialViewportState.aborted &&
          ref.read(mapReadyStateProvider)) {
        applyInitialViewport();
      }
    });

    ref.listen(locationStateProvider, (prev, next) {
      final vp = ref.read(viewportStateProvider);
      if (vp != InitialViewportState.applied &&
          vp != InitialViewportState.aborted &&
          ref.read(mapReadyStateProvider)) {
        applyInitialViewport();
      }
    });

    return const SizedBox.shrink();
  }
}

/// Overlays GPS walk / tracking isolados do canvas principal.
class MapGpsOverlaysHost extends ConsumerWidget {
  const MapGpsOverlaysHost({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gpsWalkSession = ref.watch(gpsWalkProvider);
    final drawingState = ref.watch(
      drawingControllerProvider.select((c) => c.currentState),
    );

    if (gpsWalkSession != null) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: RepaintBoundary(
          child: ListenableBuilder(
            listenable: ref.read(drawingControllerProvider),
            builder: (context, _) {
              final points = ref.read(drawingControllerProvider).gpsVertices;
              final session = ref.read(gpsWalkProvider);
              if (session != null &&
                  session.status != GpsWalkStatus.finished &&
                  points.length != session.points.length) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ref.read(gpsWalkProvider.notifier).syncFromController(points);
                });
              }
              return const GpsWalkControlsOverlay();
            },
          ),
        ),
      );
    }

    if (drawingState == DrawingState.gpsTracking) {
      return Positioned(
        left: 0,
        right: 0,
        bottom: 0,
        child: RepaintBoundary(
          child: ListenableBuilder(
            listenable: ref.read(drawingControllerProvider),
            builder: (context, _) => GpsTrackingOverlay(
              controller: ref.read(drawingControllerProvider),
            ),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}

/// Bottom sheet de drawing/ocorrências isolado do stack principal.
class MapBottomSheetOverlayHost extends ConsumerWidget {
  const MapBottomSheetOverlayHost({
    super.key,
    required this.setSheetState,
    required this.onLocationRequested,
    required this.onFocusDrawingFeature,
  });

  final void Function(MapSheetState? state, String reason) setSheetState;
  final VoidCallback onLocationRequested;
  final void Function(DrawingFeature feature) onFocusDrawingFeature;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sheetState = ref.watch(mapSheetStateProvider);
    if (sheetState == null ||
        (sheetState.type != MapSheetType.draw &&
            sheetState.type != MapSheetType.occurrences)) {
      return const SizedBox.shrink();
    }

    final creationLocation = ref.watch(pendingOccurrenceLocationProvider);

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: MapBottomSheet(
        drawingController: ref.read(drawingControllerProvider),
        state: sheetState,
        onStateChange: (newState) {
          setSheetState(newState, 'MapBottomSheet: State Changed');
        },
        onClose: () {
          setSheetState(null, 'MapBottomSheet: onClose');
        },
        creationLocation: creationLocation,
        onLocationRequested: onLocationRequested,
        onFocusDrawingFeature: onFocusDrawingFeature,
      ),
    );
  }
}

/// Foco de câmera em feature de desenho — helper compartilhado.
void focusDrawingFeatureOnMap(
  MapController mapController,
  DrawingFeature feature,
) {
  final points = <LatLng>[];
  final geometry = feature.geometry;
  if (geometry is DrawingPolygon) {
    for (final ring in geometry.coordinates) {
      points.addAll(ring.map((point) => LatLng(point[1], point[0])));
    }
  } else if (geometry is DrawingMultiPolygon) {
    for (final polygon in geometry.coordinates) {
      for (final ring in polygon) {
        points.addAll(ring.map((point) => LatLng(point[1], point[0])));
      }
    }
  }
  if (points.isEmpty) return;
  mapController.fitCamera(
    CameraFit.bounds(
      bounds: LatLngBounds.fromPoints(points),
      padding: const EdgeInsets.all(48),
    ),
  );
}
