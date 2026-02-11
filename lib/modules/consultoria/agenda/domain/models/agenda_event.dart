enum AgendaStatus {
  planned,
  // Mantém snake_case para compatibilidade com o backend.
  // ignore: constant_identifier_names
  in_progress,
  realized,
  cancelled,
}

class AgendaEvent {
  final String id;
  final String producerId;
  final String areaId;
  final String activityType;
  final DateTime scheduledDate;
  final String? description;
  final String? visitSessionId;
  final AgendaStatus status;
  final DateTime? realizedAt;
  final DateTime createdAt;
  final int syncStatus;

  AgendaEvent({
    required this.id,
    required this.producerId,
    required this.areaId,
    required this.activityType,
    required this.scheduledDate,
    this.description,
    this.visitSessionId,
    this.status = AgendaStatus.planned,
    this.realizedAt,
    required this.createdAt,
    this.syncStatus = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'producer_id': producerId,
      'area_id': areaId,
      'activity_type': activityType,
      'scheduled_date': scheduledDate.toIso8601String(),
      'description': description,
      'visit_session_id': visitSessionId,
      'status': status.name,
      'realized_at': realizedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'sync_status': syncStatus,
    };
  }

  factory AgendaEvent.fromMap(Map<String, dynamic> map) {
    return AgendaEvent(
      id: map['id'],
      producerId: map['producer_id'],
      areaId: map['area_id'],
      activityType: map['activity_type'],
      scheduledDate: DateTime.parse(map['scheduled_date']),
      description: map['description'],
      visitSessionId: map['visit_session_id'],
      status: AgendaStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => AgendaStatus.planned,
      ),
      realizedAt: map['realized_at'] != null
          ? DateTime.parse(map['realized_at'])
          : null,
      createdAt: DateTime.parse(map['created_at']),
      syncStatus: map['sync_status'] ?? 1,
    );
  }

  AgendaEvent copyWith({
    String? id,
    String? producerId,
    String? areaId,
    String? activityType,
    DateTime? scheduledDate,
    String? description,
    String? visitSessionId,
    AgendaStatus? status,
    DateTime? realizedAt,
    DateTime? createdAt,
    int? syncStatus,
  }) {
    return AgendaEvent(
      id: id ?? this.id,
      producerId: producerId ?? this.producerId,
      areaId: areaId ?? this.areaId,
      activityType: activityType ?? this.activityType,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      description: description ?? this.description,
      visitSessionId: visitSessionId ?? this.visitSessionId,
      status: status ?? this.status,
      realizedAt: realizedAt ?? this.realizedAt,
      createdAt: createdAt ?? this.createdAt,
      syncStatus: syncStatus ?? this.syncStatus,
    );
  }
}
