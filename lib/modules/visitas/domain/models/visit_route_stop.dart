import 'dart:convert';

/// Parada da rota sugerida de uma visita ativa.
///
/// Persistida em `visit_sessions.route_stops_json` (ADR-057). Estado local:
/// não entra no payload do Supabase.
enum VisitRouteStopStatus { pending, done }

class VisitRouteStop {
  final int index;
  final double lat;
  final double lng;
  final VisitRouteStopStatus status;
  final String? occurrenceId;

  const VisitRouteStop({
    required this.index,
    required this.lat,
    required this.lng,
    required this.status,
    this.occurrenceId,
  });

  bool get isDone => status == VisitRouteStopStatus.done;

  VisitRouteStop copyWith({
    VisitRouteStopStatus? status,
    String? occurrenceId,
  }) {
    return VisitRouteStop(
      index: index,
      lat: lat,
      lng: lng,
      status: status ?? this.status,
      occurrenceId: occurrenceId ?? this.occurrenceId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'index': index,
      'lat': lat,
      'lng': lng,
      'status': status.name,
      if (occurrenceId != null && occurrenceId!.trim().isNotEmpty)
        'occurrenceId': occurrenceId,
    };
  }

  static VisitRouteStop? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final index = raw['index'];
    final lat = raw['lat'];
    final lng = raw['lng'];
    if (index is! num || lat is! num || lng is! num) return null;
    if (!lat.isFinite || !lng.isFinite) return null;
    final statusName = raw['status'];
    final status = statusName == VisitRouteStopStatus.done.name
        ? VisitRouteStopStatus.done
        : VisitRouteStopStatus.pending;
    final occurrence = raw['occurrenceId'];
    return VisitRouteStop(
      index: index.toInt(),
      lat: lat.toDouble(),
      lng: lng.toDouble(),
      status: status,
      occurrenceId: occurrence is String && occurrence.trim().isNotEmpty
          ? occurrence
          : null,
    );
  }

  static String encodeList(List<VisitRouteStop> stops) {
    return jsonEncode(stops.map((stop) => stop.toJson()).toList());
  }

  static List<VisitRouteStop> decodeList(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const [];
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return const [];
    }
    if (decoded is! List) return const [];
    final stops = <VisitRouteStop>[];
    for (final item in decoded) {
      final stop = tryParse(item);
      if (stop != null) stops.add(stop);
    }
    stops.sort((a, b) => a.index.compareTo(b.index));
    return stops;
  }
}
