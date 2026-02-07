import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../core/services/notification_service.dart';
import 'package:soloforte_app/modules/visitas/domain/models/geofence_state.dart';
import '../controllers/visit_controller.dart';
import '../../../consultoria/clients/presentation/providers/field_providers.dart';
import '../../../consultoria/services/talhao_map_adapter.dart';
import '../../../consultoria/clients/domain/agronomic_models.dart';
import 'package:latlong2/latlong.dart';

// State Provider for Geofence
final geofenceStateProvider = StateProvider<GeofenceState>((ref) {
  return GeofenceState.initial();
});

class GeofenceController {
  final Ref _ref;
  final NotificationService _notificationService = NotificationService();
  Timer? _checkTimer;
  Timer? _durationTimer; // Timer for 4h alert

  GeofenceController(this._ref) {
    _init();
  }

  void _init() {
    // 1. Listen to location changes (using same stream as LocationController if exposed, or periodic check)
    // For simplicity and to avoid stream conflicts, we'll run a periodic check every 30-60 seconds
    // or when location updates if available.
    // The LocationController in Dashboard handles the stream for the map.
    // We can just listen to the locationStateProvider's last known position if it stored it?
    // Actually LocationController doesn't expose position stream globally as a provider yet, just `locationStateProvider`.
    // Let's create a periodic check which is battery friendly enough for "Assistant".

    _checkTimer = Timer.periodic(const Duration(seconds: 45), (timer) {
      _checkGeofence();
    });

    _durationTimer = Timer.periodic(const Duration(minutes: 15), (timer) {
      _checkDuration();
    });
  }

  void dispose() {
    _checkTimer?.cancel();
    _durationTimer?.cancel();
  }

  Future<void> _checkGeofence() async {
    final visitState = _ref.read(visitControllerProvider);
    final fieldsAsync = _ref.read(mapFieldsProvider);

    // Only proceed if we have valid fields data and GPS permission
    if (!fieldsAsync.hasValue) return;

    // Get current position (single request)
    Position? position;
    try {
      // Check permission without asking
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        position = await Geolocator.getLastKnownPosition();
        if (position == null ||
            DateTime.now().difference(position.timestamp) >
                const Duration(minutes: 5)) {
          // If old, try fresh but with timeout
          position = await Geolocator.getCurrentPosition(
            timeLimit: const Duration(seconds: 10),
          );
        }
      }
    } catch (_) {
      return; // Fail silently
    }

    if (position == null) return;
    final userPoint = LatLng(position.latitude, position.longitude);

    final currentGeofenceState = _ref.read(geofenceStateProvider);
    final activeSession = visitState.value;

    if (activeSession != null) {
      // --- Scenario: Active Session -> Check Exit ---
      // Get the field (talhao) for the active session
      // Assuming visit_sessions stores areaId which corresponds to field.id
      final activeField = fieldsAsync.value!.cast<Talhao?>().firstWhere(
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
      // Iterate all fields to find if inside one
      // Optimization: nearest first? just loop all for now (usually < 100 fields loaded)
      Talhao? enteredField;

      for (final field in fieldsAsync.value!) {
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

  bool _isInsideOrClose(LatLng userPoint, Talhao field) {
    if (field.geometry == null) return false;

    // 1. Check strict polygon contain
    final poly = TalhaoMapAdapter.toPolygon(field);
    bool inside = TalhaoMapAdapter.isPointInside(userPoint, poly.points);

    if (inside) return true;

    // 2. If valid center, check radius (e.g. 300m buffer)
    // We don't have explicit center in Talhao model easily accessible without parsing
    // But we can check standard distance to polygon points (simple approach: min distance to any vertex < 300m)
    // For "Assistant", a simple radius from centroid is cheaper if we pre-calc centroid,
    // but here let's use the Polygon points we already parsed.

    const double bufferMeters = 300.0;
    const Distance distance = Distance();

    for (final point in poly.points) {
      if (distance.as(LengthUnit.Meter, userPoint, point) < bufferMeters) {
        return true;
      }
    }
    return false;
  }

  Future<void> _checkDuration() async {
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

// Provider to keep it alive
final geofenceControllerProvider = Provider<GeofenceController>((ref) {
  return GeofenceController(ref);
});
