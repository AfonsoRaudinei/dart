// ADR-030 F6 — Controlador extraído de private_map_screen.dart (B2)
// Lógica de viewport inicial do mapa.
// Migrada linha a linha de _applyInitialViewport() — sem simplificação.
// Determinístico. Idempotente. Sem race loops.

import 'package:flutter/widgets.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../../../modules/dashboard/domain/location_state.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/dashboard/services/location_service.dart';
import '../../../../modules/drawing/domain/models/drawing_models.dart';

class MapViewportController {
  MapViewportController._();

  /// Aplica o viewport inicial do mapa.
  ///
  /// Estratégia A (produtor): encaixa câmera nos bounds dos talhões.
  /// Estratégia B (consumidor): move câmera para posição GPS.
  ///
  /// Requer [isMapReady] e [isMounted] como guards de ciclo de vida,
  /// pois o método é assíncrono e pode executar após dispose.
  static Future<void> apply({
    required WidgetRef ref,
    required MapController mapController,
    required bool isMapReady,
    required bool isMounted,
  }) async {
    // 🛡 LIFECYCLE GUARD: método async pode executar após dispose.
    if (!isMounted) return;

    // 🔒 Gate 0: Se já aplicado ou abortado, TERMINAR IMEDIATAMENTE.
    final vp = ref.read(viewportStateProvider);
    if (vp == InitialViewportState.applied ||
        vp == InitialViewportState.aborted) {
      return;
    }

    // 🔒 Gate 1: Map Ready
    if (!isMapReady) {
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForMap;
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    // 🔒 Gate 2: Role Ready
    if (user == null) {
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForData;
      return;
    }

    final role = user.userMetadata?['role'] as String?;
    final isProducer = role == 'produtor';

    // 🔒 Gate 3: Decisão de Estratégia
    if (isProducer) {
      // 🚜 ESTRATÉGIA PRODUTOR
      final fieldsState = ref.read(mapFieldsProvider);

      if (fieldsState.isLoading) {
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.waitingForData;
        return;
      }

      if (fieldsState.hasError ||
          !fieldsState.hasValue ||
          fieldsState.value == null ||
          fieldsState.value!.isEmpty) {
        // Sem talhão disponível no primeiro acesso do produtor: usar GPS.
        await _applyGpsViewport(
          ref: ref,
          mapController: mapController,
          isMounted: isMounted,
        );
        return;
      }

      // Sucesso: Aplicar Viewport
      final fields = fieldsState.value!;
      final allPoints = fields
          .expand((f) => TalhaoMapAdapter.toPolygon(f).points)
          .toList();

      if (allPoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(allPoints);
        try {
          mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
          ref.read(viewportStateProvider.notifier).state =
              InitialViewportState.applied; // ✅ FINALIZADO
        } catch (_) {
          await _applyGpsViewport(
            ref: ref,
            mapController: mapController,
            isMounted: isMounted,
          );
        }
      } else {
        await _applyGpsViewport(
          ref: ref,
          mapController: mapController,
          isMounted: isMounted,
        );
      }
    } else {
      // 👤 ESTRATÉGIA CONSUMIDOR (GPS)
      await _applyGpsViewport(
        ref: ref,
        mapController: mapController,
        isMounted: isMounted,
      );
    }
  }

  static Future<void> _applyGpsViewport({
    required WidgetRef ref,
    required MapController mapController,
    required bool isMounted,
  }) async {
    final locationState = ref.read(locationStateProvider);

    if (locationState == LocationState.checking) {
      // Ainda verificando → Aguardar
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForData;
      return;
    }

    if (locationState == LocationState.permissionDenied ||
        locationState == LocationState.serviceDisabled) {
      // Erro permanente → Abortar (evita loop)
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.aborted;
      return;
    }

    if (locationState == LocationState.available) {
      final locationService = LocationService();
      final position = await locationService.getCurrentPosition();

      if (position != null && isMounted) {
        // Mesmo zoom do mapa público / overview — pins permanecem no contexto.
        mapController.move(position.position, MapConfig.defaultZoom);
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.applied; // ✅ FINALIZADO
      } else if (isMounted) {
        // Disponível mas posição nula? Aguardar.
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.waitingForData;
      }
    }
  }

  /// Recentra no usuário com a mesma estratégia do viewport inicial:
  /// - Com talhões: fitCamera nos polígonos + posição do usuário (pins/talhões visíveis)
  /// - Sem talhões: move no usuário com [MapConfig.defaultZoom] (13)
  static void recenterOnUser({
    required WidgetRef ref,
    required MapController mapController,
    required LatLng userPosition,
  }) {
    final fieldsState = ref.read(mapFieldsProvider);
    final fields = fieldsState.asData?.value;
    if (fields != null && fields.isNotEmpty) {
      final allPoints = fields
          .expand((f) => TalhaoMapAdapter.toPolygon(f).points)
          .toList(growable: true);
      allPoints.add(userPosition);
      if (allPoints.length >= 2) {
        try {
          mapController.fitCamera(
            CameraFit.bounds(
              bounds: LatLngBounds.fromPoints(allPoints),
              padding: const EdgeInsets.all(50),
            ),
          );
          return;
        } catch (_) {
          // fallback abaixo
        }
      }
    }

    mapController.move(userPosition, MapConfig.defaultZoom);
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
