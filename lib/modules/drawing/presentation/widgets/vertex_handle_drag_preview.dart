import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

/// Arraste local da gota. Não dispara [ChangeNotifier] do controller.
class VertexHandleDrag {
  const VertexHandleDrag({
    required this.isSketch,
    required this.ringIndex,
    required this.pointIndex,
    required this.position,
  });

  final bool isSketch;
  final int ringIndex;
  final int pointIndex;
  final LatLng position;
}

class VertexHandleDragPreview extends ChangeNotifier {
  VertexHandleDrag? _drag;
  double? _areaHa;
  double? _perimeterKm;

  VertexHandleDrag? get drag => _drag;
  double? get areaHa => _areaHa;
  double? get perimeterKm => _perimeterKm;

  void update(
    VertexHandleDrag drag, {
    required double areaHa,
    required double perimeterKm,
  }) {
    _drag = drag;
    _areaHa = areaHa;
    _perimeterKm = perimeterKm;
    notifyListeners();
  }

  void clear() {
    if (_drag == null && _areaHa == null && _perimeterKm == null) return;
    _drag = null;
    _areaHa = null;
    _perimeterKm = null;
    notifyListeners();
  }
}
