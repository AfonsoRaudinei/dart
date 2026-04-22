import 'package:geolocator/geolocator.dart';

/// Serializa solicitações de permissão de localização para evitar erro:
/// "A request for location permissions is already running".
class LocationPermissionGate {
  static Future<LocationPermission>? _inFlight;

  static Future<LocationPermission> request() {
    final pending = _inFlight;
    if (pending != null) return pending;

    final future = Geolocator.requestPermission();
    _inFlight = future;

    future.whenComplete(() {
      if (identical(_inFlight, future)) {
        _inFlight = null;
      }
    });

    return future;
  }
}
