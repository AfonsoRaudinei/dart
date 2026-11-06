import 'dart:math' as math;

import 'models/visit_route_stop.dart';

/// Resultado de concluir a parada atual.
class VisitRouteAdvance {
  final List<VisitRouteStop> stops;
  final int? currentIndex;
  final VisitRouteStop completed;
  final VisitRouteStop? next;

  const VisitRouteAdvance({
    required this.stops,
    required this.currentIndex,
    required this.completed,
    required this.next,
  });
}

/// Marca a parada corrente como feita e aponta a próxima pendente.
///
/// [currentIndex] é 1-based (`route_current_index`). Sem parada pendente,
/// devolve null.
VisitRouteAdvance? advanceVisitRoute({
  required List<VisitRouteStop> stops,
  required int? currentIndex,
  String? occurrenceId,
}) {
  if (stops.isEmpty || currentIndex == null) return null;
  final target = stops.indexWhere(
    (stop) =>
        stop.index == currentIndex &&
        stop.status == VisitRouteStopStatus.pending,
  );
  if (target < 0) return null;

  final updated = List<VisitRouteStop>.from(stops);
  final done = stops[target].copyWith(
    status: VisitRouteStopStatus.done,
    occurrenceId: occurrenceId,
  );
  updated[target] = done;

  VisitRouteStop? next;
  for (final stop in updated) {
    if (stop.status == VisitRouteStopStatus.pending) {
      next = stop;
      break;
    }
  }

  return VisitRouteAdvance(
    stops: updated,
    currentIndex: next?.index,
    completed: done,
    next: next,
  );
}

/// Raio (metros) do aviso de proximidade com o app em primeiro plano.
const double visitRouteApproachRadiusMeters = 80;

double visitRouteDistanceMeters({
  required double fromLat,
  required double fromLng,
  required double toLat,
  required double toLng,
}) {
  const earth = 6371000.0;
  final dLat = _rad(toLat - fromLat);
  final dLng = _rad(toLng - fromLng);
  final lat1 = _rad(fromLat);
  final lat2 = _rad(toLat);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(lat1) * math.cos(lat2) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return earth * 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
}

double _rad(double degrees) => degrees * math.pi / 180;
