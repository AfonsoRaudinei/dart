import 'visit_route_stop.dart';

class VisitSession {
  final String id;
  final String producerId;
  // Nullable: check-in pode ser feito apenas com produtor.
  final String? farmId;
  final String? areaId;
  final String? activityType;
  final DateTime startTime;
  final DateTime? endTime;
  final double initialLat;
  final double initialLong;
  final String status; // 'active', 'finished'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus; // 0 = synced, 1 = pending
  /// JSON local da rota sugerida. Não sincroniza com o Supabase (ADR-057).
  final String? routeStopsJson;

  /// Índice 1-based da próxima parada pendente. Null sem rota ou rota concluída.
  final int? routeCurrentIndex;

  VisitSession({
    required this.id,
    required this.producerId,
    this.farmId,
    this.areaId,
    this.activityType,
    required this.startTime,
    this.endTime,
    required this.initialLat,
    required this.initialLong,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 1,
    this.routeStopsJson,
    this.routeCurrentIndex,
  });

  List<VisitRouteStop> get routeStops =>
      VisitRouteStop.decodeList(routeStopsJson);

  VisitRouteStop? get currentRouteStop {
    final index = routeCurrentIndex;
    if (index == null) return null;
    for (final stop in routeStops) {
      if (stop.index == index && stop.status == VisitRouteStopStatus.pending) {
        return stop;
      }
    }
    return null;
  }

  factory VisitSession.fromMap(Map<String, dynamic> map) {
    return VisitSession(
      id: map['id'],
      producerId: map['producer_id'],
      farmId: map['farm_id'] as String?,
      areaId: map['area_id'] as String?,
      activityType: map['activity_type'] as String?,
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      initialLat: map['initial_lat'],
      initialLong: map['initial_long'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncStatus: map['sync_status'] ?? 1,
      routeStopsJson: map['route_stops_json'] as String?,
      routeCurrentIndex: (map['route_current_index'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producer_id': producerId,
      'farm_id': farmId,
      'area_id': areaId,
      'activity_type': activityType,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'initial_lat': initialLat,
      'initial_long': initialLong,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
      'route_stops_json': routeStopsJson,
      'route_current_index': routeCurrentIndex,
    };
  }

  VisitSession copyWith({
    String? id,
    String? producerId,
    String? farmId,
    String? areaId,
    bool clearAreaId = false,
    String? activityType,
    DateTime? startTime,
    DateTime? endTime,
    double? initialLat,
    double? initialLong,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
    String? routeStopsJson,
    int? routeCurrentIndex,
    bool clearRoute = false,
  }) {
    return VisitSession(
      id: id ?? this.id,
      producerId: producerId ?? this.producerId,
      farmId: farmId ?? this.farmId,
      areaId: clearAreaId ? null : (areaId ?? this.areaId),
      activityType: activityType ?? this.activityType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      initialLat: initialLat ?? this.initialLat,
      initialLong: initialLong ?? this.initialLong,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      routeStopsJson: clearRoute
          ? null
          : (routeStopsJson ?? this.routeStopsJson),
      routeCurrentIndex: clearRoute
          ? null
          : (routeCurrentIndex ?? this.routeCurrentIndex),
    );
  }

  /// Grava a rota local sem mexer em `updated_at` / `sync_status`.
  VisitSession copyWithRoute({
    required String? routeStopsJson,
    required int? routeCurrentIndex,
  }) {
    return VisitSession(
      id: id,
      producerId: producerId,
      farmId: farmId,
      areaId: areaId,
      activityType: activityType,
      startTime: startTime,
      endTime: endTime,
      initialLat: initialLat,
      initialLong: initialLong,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      syncStatus: syncStatus,
      routeStopsJson: routeStopsJson,
      routeCurrentIndex: routeCurrentIndex,
    );
  }
}
