// ADR-030 F6 — Controlador extraído de private_map_screen.dart (B2)
// Lógica de viewport inicial do mapa.
// Migrada linha a linha de _applyInitialViewport() — sem simplificação.
// Determinístico. Idempotente. Sem race loops.

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../modules/consultoria/clients/domain/agronomic_models.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/dashboard/services/location_service.dart';
import '../../../../modules/drawing/domain/models/drawing_models.dart';

/// Produtor com papel conhecido encaixa nos talhões. Sem usuário, o mapa
/// segue o GPS — e, se o fix não chega, as coordenadas já salvas da fazenda.
@visibleForTesting
bool viewportUsesProducerStrategy(User? user) {
  return user?.userMetadata?['role'] == 'produtor';
}

/// Pontos do polígono já persistido em `fields.bordadura_geo`.
@visibleForTesting
List<LatLng> polygonPointsFromFields(List<Talhao>? fields) {
  if (fields == null) return const [];
  final points = <LatLng>[];
  for (final field in fields) {
    points.addAll(TalhaoMapAdapter.toPolygon(field).points);
  }
  return points;
}

enum OfflineCameraChoice { storedFarm, gps, wait }

/// Produtor abre na fazenda salva. Sem fix GNSS, a fazenda do produtor
/// ainda é a coordenada — o GPS só entra quando não há polígono local.
@visibleForTesting
OfflineCameraChoice resolveOfflineCamera({
  required bool isProducer,
  required bool hasStoredFarmPoints,
  required bool fieldsLoading,
  required bool gpsFixAvailable,
}) {
  if (isProducer && hasStoredFarmPoints) {
    return OfflineCameraChoice.storedFarm;
  }
  if (isProducer && fieldsLoading) return OfflineCameraChoice.wait;
  if (gpsFixAvailable) return OfflineCameraChoice.gps;
  if (hasStoredFarmPoints) return OfflineCameraChoice.storedFarm;
  if (fieldsLoading) return OfflineCameraChoice.wait;
  return OfflineCameraChoice.gps;
}

/// GPS que chega depois do foco do talhão (ou de intent explícito) não move.
@visibleForTesting
bool shouldCommitGpsMove({
  required InitialViewportState viewport,
  required bool explicitCameraIntent,
}) {
  if (explicitCameraIntent) return false;
  return viewport != InitialViewportState.applied &&
      viewport != InitialViewportState.aborted;
}

class MapViewportController {
  MapViewportController._();

  /// Aplica o viewport inicial do mapa.
  ///
  /// Estratégia A (produtor): encaixa câmera nos bounds dos talhões.
  /// Estratégia B (consumidor): move câmera para posição GPS e, sem fix,
  /// usa o polígono da fazenda já salvo no aparelho.
  ///
  /// Requer [isMapReady] e [isMounted] como guards de ciclo de vida,
  /// pois o método é assíncrono e pode executar após dispose.
  static Future<void> apply({
    required WidgetRef ref,
    required MapController mapController,
    required bool isMapReady,
    required bool isMounted,
  }) async {
    if (!isMounted) return;

    if (ref.read(explicitMapCameraIntentProvider)) return;

    final vp = ref.read(viewportStateProvider);
    if (vp == InitialViewportState.applied ||
        vp == InitialViewportState.aborted) {
      return;
    }

    if (!isMapReady) {
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForMap;
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    final isProducer = viewportUsesProducerStrategy(user);
    final fieldsState = ref.read(mapFieldsProvider);
    final farmPoints = polygonPointsFromFields(fieldsState.valueOrNull);
    final choice = resolveOfflineCamera(
      isProducer: isProducer,
      hasStoredFarmPoints: farmPoints.isNotEmpty,
      fieldsLoading: fieldsState.isLoading,
      gpsFixAvailable: true,
    );

    if (choice == OfflineCameraChoice.storedFarm) {
      if (_fitFarmPoints(
        ref: ref,
        mapController: mapController,
        isMounted: isMounted,
        points: farmPoints,
      )) {
        return;
      }
    }

    if (choice == OfflineCameraChoice.wait) {
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForData;
      return;
    }

    await _applyGpsViewport(
      ref: ref,
      mapController: mapController,
      isMounted: isMounted,
      farmPoints: farmPoints,
      fieldsLoading: fieldsState.isLoading,
    );
  }

  static bool _fitFarmPoints({
    required WidgetRef ref,
    required MapController mapController,
    required bool isMounted,
    required List<LatLng> points,
  }) {
    if (!isMounted || points.isEmpty) return false;
    try {
      mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(points),
          padding: const EdgeInsets.all(50),
        ),
      );
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.applied;
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> _applyGpsViewport({
    required WidgetRef ref,
    required MapController mapController,
    required bool isMounted,
    required List<LatLng> farmPoints,
    required bool fieldsLoading,
  }) async {
    final locationState = ref.read(locationStateProvider);

    if (locationState == LocationState.checking) {
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForData;
      return;
    }

    if (locationState == LocationState.permissionDenied ||
        locationState == LocationState.serviceDisabled) {
      if (_fitFarmPoints(
        ref: ref,
        mapController: mapController,
        isMounted: isMounted,
        points: farmPoints,
      )) {
        return;
      }
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.aborted;
      return;
    }

    if (locationState == LocationState.available) {
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForData;
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      if (!isMounted) return;

      final stillAllowed = shouldCommitGpsMove(
        viewport: ref.read(viewportStateProvider),
        explicitCameraIntent: ref.read(explicitMapCameraIntentProvider),
      );
      if (!stillAllowed) return;

      if (position != null) {
        mapController.move(position.position, 16.0);
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.applied;
        return;
      }
      final fallback = resolveOfflineCamera(
        isProducer: false,
        hasStoredFarmPoints: farmPoints.isNotEmpty,
        fieldsLoading: fieldsLoading,
        gpsFixAvailable: false,
      );
      if (fallback == OfflineCameraChoice.storedFarm &&
          _fitFarmPoints(
            ref: ref,
            mapController: mapController,
            isMounted: isMounted,
            points: farmPoints,
          )) {
        return;
      }
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForData;
    }
  }

  static bool focusDrawingFeature({
    required MapController mapController,
    required DrawingFeature feature,
  }) {
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

    if (points.isEmpty) return false;

    mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(48),
      ),
    );
    return true;
  }
}
