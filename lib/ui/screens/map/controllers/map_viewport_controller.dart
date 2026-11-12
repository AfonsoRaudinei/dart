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
import '../../../../modules/produtor/data/linked_consultant_geometry.dart';
import '../../../../modules/produtor/data/producer_link_models.dart';
import '../../../../modules/produtor/data/producer_link_repository.dart';
import '../../../../modules/produtor/data/producer_property_repository.dart';
import '../../../components/map/widgets/producer_map_context_card.dart';
import '../handlers/visit_check_in_map_focus.dart';
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

/// A fazenda própria do produtor manda na câmera. Sem polígono local,
/// o mapa abre nos talhões que o consultor liberou.
@visibleForTesting
List<LatLng> producerCameraPoints({
  required List<LatLng> ownPoints,
  required List<LatLng> linkedPoints,
}) {
  if (ownPoints.isNotEmpty) return ownPoints;
  return linkedPoints;
}

/// Pontos do polígono já persistido em `fields.bordadura_geo`.
@visibleForTesting
List<LatLng> polygonPointsFromFields(List<Talhao>? fields) {
  if (fields == null) return const [];
  final points = <LatLng>[];
  for (final field in fields) {
    points.addAll(TalhaoMapAdapter.boundsSamplePoints(field));
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
  bool producerPropertyLoading = false,
}) {
  if (isProducer && producerPropertyLoading) {
    return OfflineCameraChoice.wait;
  }
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

/// Alinha filtros do mapa com a fazenda do produtor (mesma regra do context card).
@visibleForTesting
void syncProducerMapFarmSelection(
  WidgetRef ref,
  List<ProducerOwnFarm> farms,
  String? selectedFarmId,
) {
  if (farms.isEmpty) return;
  final selectedExists = farms.any((farm) => farm.id == selectedFarmId);
  if (selectedFarmId != null && selectedExists) {
    ref.read(selectedFarmIdProvider.notifier).state = selectedFarmId;
    return;
  }

  final farm = farms.first;
  ref.read(producerMapSelectedFarmIdProvider.notifier).state = farm.id;
  ref.read(producerMapSelectedFieldIdProvider.notifier).state = null;
  ref.read(selectedFarmIdProvider.notifier).state = farm.id;
  ref.read(selectedTalhaoIdProvider.notifier).state = null;
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

    var producerPropertyLoading = false;
    if (isProducer) {
      final dashboardAsync = ref.read(producerPropertyDashboardProvider);
      producerPropertyLoading = dashboardAsync.isLoading;
      if (dashboardAsync.isLoading) {
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.waitingForData;
        return;
      }
      if (dashboardAsync.hasValue) {
        final dashboard = dashboardAsync.value!;
        final farms = dashboard.ownProperty.farms;
        syncProducerMapFarmSelection(
          ref,
          farms,
          ref.read(producerMapSelectedFarmIdProvider),
        );
        if (farms.isNotEmpty) {
          final farmId = ref.read(selectedFarmIdProvider);
          final focusPoints = await resolveVisitCheckInMapFocusPoints(
            ref: ref,
            clientId: dashboard.ownProperty.clientId,
            farmId: farmId,
            talhaoId: null,
          );
          if (!isMounted) return;
          if (ref.read(explicitMapCameraIntentProvider)) return;
          final vpFocus = ref.read(viewportStateProvider);
          if (vpFocus == InitialViewportState.applied ||
              vpFocus == InitialViewportState.aborted) {
            return;
          }
          if (focusPoints.isNotEmpty &&
              fitVisitFocusPointsOnMap(mapController, focusPoints)) {
            ref.read(viewportStateProvider.notifier).state =
                InitialViewportState.applied;
            return;
          }
        }
      }
    }

    AsyncValue<List<Talhao>> fieldsState;
    if (isProducer) {
      try {
        final fields = await ref.read(mapFieldsProvider.future);
        if (!isMounted) return;
        fieldsState = AsyncData(fields);
      } catch (error, stackTrace) {
        fieldsState = AsyncError(error, stackTrace);
      }
    } else {
      fieldsState = ref.read(mapFieldsProvider);
    }

    var farmPoints = polygonPointsFromFields(fieldsState.valueOrNull);
    if (farmPoints.isEmpty && !fieldsState.isLoading) {
      farmPoints = await _linkedConsultantCameraPoints(
        ref: ref,
        isMounted: isMounted,
        ownPoints: farmPoints,
      );
      if (!isMounted) return;
      final vpAfterLink = ref.read(viewportStateProvider);
      if (vpAfterLink == InitialViewportState.applied ||
          vpAfterLink == InitialViewportState.aborted) {
        return;
      }
      if (ref.read(explicitMapCameraIntentProvider)) return;
    }
    final choice = resolveOfflineCamera(
      isProducer: isProducer,
      hasStoredFarmPoints: farmPoints.isNotEmpty,
      fieldsLoading: fieldsState.isLoading,
      gpsFixAvailable: !isProducer || !producerPropertyLoading,
      producerPropertyLoading: producerPropertyLoading,
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

  static Future<List<LatLng>> _linkedConsultantCameraPoints({
    required WidgetRef ref,
    required bool isMounted,
    required List<LatLng> ownPoints,
  }) async {
    try {
      final linked = await ref
          .read(producerLinkRepositoryProvider)
          .loadLinkedConsultantData();
      if (!isMounted) return ownPoints;
      return producerCameraPoints(
        ownPoints: ownPoints,
        linkedPoints: focusPointsForLinkedClients(linked),
      );
    } catch (_) {
      return ownPoints;
    }
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
