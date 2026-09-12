import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../modules/drawing/presentation/controllers/drawing_controller.dart';

/// Raio em pixels de tela para considerar long press sobre um pin.
const double kMapPinHitTestRadiusPx = 40.0;

/// Retorna true se [point] não cai sobre geometria de desenho ou pin existente.
///
/// Talhão no mapa **não** bloqueia o gesto — o viewport pós-login costuma
/// estar sobre a fazenda (GPS zoom 16 ou fit dos talhões).
bool isEmptyMapArea({
  required LatLng point,
  required MapCamera camera,
  required DrawingController drawingController,
  required Iterable<LatLng> pinPoints,
}) {
  if (drawingController.findFeatureAt(point) != null) {
    return false;
  }

  final press = camera.latLngToScreenPoint(point);
  final radiusSq = kMapPinHitTestRadiusPx * kMapPinHitTestRadiusPx;
  for (final pin in pinPoints) {
    final screen = camera.latLngToScreenPoint(pin);
    final dx = press.x - screen.x;
    final dy = press.y - screen.y;
    if (dx * dx + dy * dy <= radiusSq) return false;
  }

  return true;
}
