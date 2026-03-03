enum SyncStatus { local_only, pending_sync, synced, sync_error, deleted_local }

class Relatorio {
  final String id;
  final String? clientId; // ADR-017: nullable, retrocompatível
  final String titulo;
  final String descricao;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String createdBy;
  final SyncStatus syncStatus;
  final DateTime? deletedAt;

  final String? visitSessionId;
  final List<String>? occurrenceIds;

  Relatorio({
    required this.id,
    this.clientId,
    required this.titulo,
    required this.descricao,
    required this.createdAt,
    required this.updatedAt,
    required this.createdBy,
    this.syncStatus = SyncStatus.local_only,
    this.deletedAt,
    this.visitSessionId,
    this.occurrenceIds,
  }) : assert(titulo.isNotEmpty, 'O título não pode ser vazio');

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'client_id': clientId,
      'titulo': titulo,
      'descricao': descricao,
      'created_at': createdAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
      'created_by': createdBy,
      'sync_status': syncStatus.name,
      'deleted_at': deletedAt?.toUtc().toIso8601String(),
      'visit_session_id': visitSessionId,
      'occurrence_ids': occurrenceIds?.join(','),
    };
  }

  factory Relatorio.fromMap(Map<String, dynamic> map) {
    return Relatorio(
      id: map['id'],
      clientId: map['client_id'] as String?,
      titulo: map['titulo'],
      descricao: map['descricao'],
      createdAt: DateTime.parse(map['created_at']).toUtc(),
      updatedAt: DateTime.parse(map['updated_at']).toUtc(),
      createdBy: map['created_by'],
      syncStatus: SyncStatus.values.byName(map['sync_status'] ?? 'local_only'),
      deletedAt: map['deleted_at'] != null
          ? DateTime.parse(map['deleted_at']).toUtc()
          : null,
      visitSessionId: map['visit_session_id'],
      occurrenceIds:
          map['occurrence_ids'] != null &&
              (map['occurrence_ids'] as String).isNotEmpty
          ? (map['occurrence_ids'] as String).split(',')
          : null,
    );
  }

  Relatorio copyWith({
    String? id,
    String? clientId,
    String? titulo,
    String? descricao,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    SyncStatus? syncStatus,
    DateTime? deletedAt,
    String? visitSessionId,
    List<String>? occurrenceIds,
  }) {
    return Relatorio(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      titulo: titulo ?? this.titulo,
      descricao: descricao ?? this.descricao,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      syncStatus: syncStatus ?? this.syncStatus,
      deletedAt: deletedAt ?? this.deletedAt,
      visitSessionId: visitSessionId ?? this.visitSessionId,
      occurrenceIds: occurrenceIds ?? this.occurrenceIds,
    );
  }
}
