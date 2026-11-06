import 'models/visit_route_stop.dart';

/// Deep link já existente do mapa: `/map?modo=foco&lat=&lng=`.
///
/// Não cria sub-rota. O toque na notificação só reabre o mapa nesse ponto.
String visitRouteMapFocusLocation({required double lat, required double lng}) {
  return Uri(
    path: '/map',
    queryParameters: {
      'modo': 'foco',
      'lat': lat.toStringAsFixed(6),
      'lng': lng.toStringAsFixed(6),
    },
  ).toString();
}

String visitRouteMapFocusLocationFor(VisitRouteStop stop) {
  return visitRouteMapFocusLocation(lat: stop.lat, lng: stop.lng);
}

/// Aceita só o foco do mapa. Payload vazio ou de outro tipo não navega.
String? mapFocusLocationFromNotificationPayload(String? payload) {
  if (payload == null || payload.trim().isEmpty) return null;
  final uri = Uri.tryParse(payload.trim());
  if (uri == null || uri.path != '/map') return null;
  if (uri.queryParameters['modo'] != 'foco') return null;
  final lat = double.tryParse(uri.queryParameters['lat'] ?? '');
  final lng = double.tryParse(uri.queryParameters['lng'] ?? '');
  if (lat == null || lng == null) return null;
  if (!lat.isFinite || !lng.isFinite) return null;
  if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
  if (lat == 0 && lng == 0) return null;
  return uri.toString();
}

/// Ids estáveis. Geofence usa 100/200/300 — a rota fica acima disso.
int visitRouteNextStopNotificationId(int index) => 400 + index;

const int visitRouteCompletedNotificationId = 490;

int visitRouteApproachNotificationId(int index) => 520 + index;
