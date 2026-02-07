class VisitSession {
  final String id;
  final String producerId;
  final String areaId;
  final String activityType;
  final DateTime startTime;
  final DateTime? endTime;
  final double initialLat;
  final double initialLong;
  final String status; // 'active', 'finished'
  final DateTime createdAt;
  final DateTime updatedAt;
  final int syncStatus; // 0 = synced, 1 = pending

  VisitSession({
    required this.id,
    required this.producerId,
    required this.areaId,
    required this.activityType,
    required this.startTime,
    this.endTime,
    required this.initialLat,
    required this.initialLong,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = 1,
  });

  factory VisitSession.fromMap(Map<String, dynamic> map) {
    return VisitSession(
      id: map['id'],
      producerId: map['producer_id'],
      areaId: map['area_id'],
      activityType: map['activity_type'],
      startTime: DateTime.parse(map['start_time']),
      endTime: map['end_time'] != null ? DateTime.parse(map['end_time']) : null,
      initialLat: map['initial_lat'],
      initialLong: map['initial_long'],
      status: map['status'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncStatus: map['sync_status'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producer_id': producerId,
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
    };
  }

  VisitSession copyWith({
    String? id,
    String? producerId,
    String? areaId,
    String? activityType,
    DateTime? startTime,
    DateTime? endTime,
    double? initialLat,
    double? initialLong,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? syncStatus,
  }) {
    return VisitSession(
      id: id ?? this.id,
      producerId: producerId ?? this.producerId,
      areaId: areaId ?? this.areaId,
      activityType: activityType ?? this.activityType,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      initialLat: initialLat ?? this.initialLat,
      initialLong: initialLong ?? this.initialLong,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
