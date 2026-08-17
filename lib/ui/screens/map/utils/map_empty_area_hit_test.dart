import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../../../modules/drawing/presentation/controllers/drawing_controller.dart';
import 'field_hit_index.dart';

/// Raio em pixels de tela para considerar long press sobre um pin.
const double kMapPinHitTestRadiusPx = 40.0;

/// Retorna true se [point] não cai sobre talhão, geometria de desenho ou pin.
bool isEmptyMapArea({
  required LatLng point,
  required MapCamera camera,
  required DrawingController drawingController,
  required FieldHitIndex? fieldHitIndex,
  required Iterable<LatLng> pinPoints,
}) {
  if (drawingController.findFeatureAt(point) != null) {
    return false;
  }

  if (fieldHitIndex != null) {
    final fieldId = fieldHitIndex.hitTest(
      point,
      TalhaoMapAdapter.isPointInside,
    );
    if (fieldId != null) return false;
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
