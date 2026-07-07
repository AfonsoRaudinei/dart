import 'dart:async';
import 'dart:convert'; // para jsonDecode do GeoJSON — ADR-024
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/notification_service.dart';
import 'package:soloforte_app/modules/visitas/domain/models/geofence_state.dart';
import 'package:soloforte_app/modules/dashboard/domain/user_location_fix.dart';
import 'package:soloforte_app/modules/dashboard/providers/location_providers.dart';
import '../controllers/visit_controller.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_geofence_provider.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/app_logger.dart';

// State Provider for Geofence
final geofenceStateProvider = StateProvider<GeofenceState>((ref) {
  return GeofenceState.initial();
});

class GeofenceController {
  final Ref _ref;
  final NotificationService _notificationService = NotificationService();
  Timer? _durationTimer; // Timer for 4h alert
  bool _isDisposed = false;
  bool _isChecking = false;
  DateTime? _lastEvaluationAt;

  static const _evaluationThrottle = Duration(seconds: 15);

  GeofenceController(this._ref) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<UserLocationFix>>(locationStreamProvider, (
      previous,
      next,
    ) {
      next.whenData((fix) => _handlePosition(fix.position));
    }, fireImmediately: true);

    _durationTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkDuration();
    });
  }

  void _cancelAllTimers() {
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    _cancelAllTimers();
  }

  void _handlePosition(LatLng userPoint) {
    if (_isDisposed || _isChecking) return;
    final now = DateTime.now();
    final lastEvaluationAt = _lastEvaluationAt;
    if (lastEvaluationAt != null &&
        now.difference(lastEvaluationAt) < _evaluationThrottle) {
      return;
    }
    _lastEvaluationAt = now;
    _isChecking = true;
    unawaited(
      _checkGeofence(userPoint)
          .catchError((Object error) {
            AppLogger.warning(
              'Falha ao avaliar geofence',
              tag: 'Geofence',
              error: error,
            );
          })
          .whenComplete(() => _isChecking = false),
    );
  }

  Future<void> _checkGeofence(LatLng userPoint) async {
    if (_isDisposed) return;

    final visitState = _ref.read(visitControllerProvider);

    final fieldLookup = _ref.read(iFieldLookupGeofenceProvider);
    List<FieldSummary> fields;
    try {
      fields = await fieldLookup.listAll();
    } catch (e) {
      AppLogger.warning(
        'Falha ao carregar talhões para geofence',
        tag: 'Geofence',
        error: e,
      );
      return;
    }
    if (fields.isEmpty) return;

    final currentGeofenceState = _ref.read(geofenceStateProvider);
    final activeSession = visitState.value;

    if (activeSession != null) {
      // --- Scenario: Active Session -> Check Exit ---
      final FieldSummary? activeField = fields.cast<FieldSummary?>().firstWhere(
        (f) => f?.id == activeSession.areaId,
        orElse: () => null,
      );

      if (activeField != null) {
        // Check distance/contains
        final isInside = _isInsideOrClose(userPoint, activeField);

        if (!isInside && currentGeofenceState.inside) {
          // Transitioned to OUT
          _notificationService.showNotification(
            id: 200,
            title: 'Saiu da área?',
            body:
                'Você parece ter saído de ${activeField.name}. Toque para encerrar a visita.',
          );

          _ref.read(geofenceStateProvider.notifier).state = currentGeofenceState
              .copyWith(inside: false, lastTransition: DateTime.now());
        } else if (isInside && !currentGeofenceState.inside) {
          // Back IN
          _ref.read(geofenceStateProvider.notifier).state = currentGeofenceState
              .copyWith(inside: true, lastTransition: DateTime.now());
        }
      }
    } else {
      // --- Scenario: No Session -> Check Entry ---
      FieldSummary? enteredField;

      for (final field in fields) {
        if (_isInsideOrClose(userPoint, field)) {
          enteredField = field;
          break; // Assume first match
        }
      }

      if (enteredField != null) {
        // entered a field
        if (currentGeofenceState.areaId != enteredField.id ||
            !currentGeofenceState.inside) {
          // New entry or re-entry
          _notificationService.showNotification(
            id: 100,
            title: 'Chegou em ${enteredField.name}?',
            body: 'Toque para iniciar uma visita técnica neste talhão.',
          );

          _ref.read(geofenceStateProvider.notifier).state = GeofenceState(
            areaId: enteredField.id,
            inside: true,
            lastTransition: DateTime.now(),
          );
        }
      } else {
        // Outside all
        if (currentGeofenceState.inside) {
          _ref.read(geofenceStateProvider.notifier).state = currentGeofenceState
              .copyWith(inside: false, lastTransition: DateTime.now());
        }
      }
    }
  }

  /// Verifica se o ponto está dentro ou a menos de 300m do talhão.
  /// ADR-024: usa FieldSummary.geometry (GeoJSON String) em vez de Talhao.
  bool _isInsideOrClose(LatLng userPoint, FieldSummary field) {
    if (field.geometry == null) return false;

    // 1. Parse GeoJSON string → pontos do polígono
    final points = _geoJsonToLatLngs(field.geometry!);
    if (points.isEmpty) return false;

    // 2. Contenção estrita via ray-casting
    bool inside = _isPointInPolygon(userPoint, points);
    if (inside) return true;

    // 3. Buffer de 300m — distância mínima a qualquer vértice
    const double bufferMeters = 300.0;
    const Distance distance = Distance();

    for (final point in points) {
      if (distance.as(LengthUnit.Meter, userPoint, point) < bufferMeters) {
        return true;
      }
    }
    return false;
  }

  /// Converte GeoJSON serializado como String em lista de pontos LatLng.
  /// Suporta Polygon (anel externo). Algoritmo inlinado de TalhaoMapAdapter — ADR-024.
  static List<LatLng> _geoJsonToLatLngs(String geoJsonStr) {
    try {
      final geometry = jsonDecode(geoJsonStr) as Map<String, dynamic>;
      final type = geometry['type'];
      if (type == 'Polygon') {
        final coordinates = geometry['coordinates'] as List;
        if (coordinates.isNotEmpty) {
          final ring = coordinates[0] as List;
          return ring.map((coord) {
            // GeoJSON é [lon, lat]
            final double lng = (coord[0] as num).toDouble();
            final double lat = (coord[1] as num).toDouble();
            return LatLng(lat, lng);
          }).toList();
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Erro ao parsear geometry do talhão',
        tag: 'Geofence',
        error: e,
      );
    }
    return [];
  }

  /// Ray-casting algorithm — ponto dentro do polígono?
  static bool _isPointInPolygon(LatLng point, List<LatLng> polygon) {
    int intersectCount = 0;
    for (int j = 0; j < polygon.length - 1; j++) {
      if (_rayCastIntersect(point, polygon[j], polygon[j + 1])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1;
  }

  static bool _rayCastIntersect(LatLng point, LatLng vertA, LatLng vertB) {
    double aY = vertA.latitude;
    double bY = vertB.latitude;
    double aX = vertA.longitude;
    double bX = vertB.longitude;
    double pY = point.latitude;
    double pX = point.longitude;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      return false;
    }
    if (aY == bY) return false;

    double m = (bX - aX) / (bY - aY);
    double bee = -aY * m + aX;
    double x = pY * m + bee;
    return x > pX;
  }

  Future<void> _checkDuration() async {
    if (_isDisposed) return;

    final visitState = _ref.read(visitControllerProvider);
    final activeSession = visitState.value;

    if (activeSession != null && activeSession.status == 'active') {
      final duration = DateTime.now().difference(activeSession.startTime);
      if (duration.inHours >= 4) {
        // Check if we already notified recently?
        // Implementation detail: NotificationService handles dedupe by ID if we reuse ID 300
        // Or we can check lastTransition. For now, just notify.
        _notificationService.showNotification(
          id: 300,
          title: 'Visita Longa',
          body: 'Sua visita já dura ${duration.inHours} horas. Tudo certo?',
        );
      }
    }
  }
}

// AutoDispose com teardown explícito dos timers para evitar vazamento fora da tela.
final geofenceControllerProvider = Provider.autoDispose<GeofenceController>((
  ref,
) {
  final controller = GeofenceController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});
