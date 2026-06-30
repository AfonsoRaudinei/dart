import '../../../../core/sync/occurrence_sync_mapper.dart';

// 🔄 Estados de sincronização offline-first
enum SyncStatus {
  local, // Criado offline, nunca sincronizado
  synced, // Espelhado no backend
  updated, // Alterado localmente após sync
  deleted; // Exclusão lógica pendente

  static SyncStatus fromString(String? value) {
    if (value == null) return SyncStatus.local;
    switch (value) {
      case 'local':
        return SyncStatus.local;
      case 'synced':
        return SyncStatus.synced;
      case 'updated':
        return SyncStatus.updated;
      case 'deleted':
        return SyncStatus.deleted;
      default:
        return SyncStatus.local;
    }
  }
}

// Categorias agronômicas de ocorrências
enum OccurrenceCategory {
  doenca('Doença', '🦠'),
  insetos('Insetos', '🐛'),
  daninhas('Ervas Daninhas', '🌿'),
  nutricional('Nutrientes', '⚗️'),
  agua('Água', '💧');

  final String label;
  final String emoji;
  const OccurrenceCategory(this.label, this.emoji);

  static OccurrenceCategory fromString(String? value) {
    if (value == null) return OccurrenceCategory.doenca;
    switch (value.toLowerCase()) {
      case 'doenca':
      case 'doença':
        return OccurrenceCategory.doenca;
      case 'insetos':
      case 'pragas':
        return OccurrenceCategory.insetos;
      case 'daninhas':
      case 'ervas daninhas':
        return OccurrenceCategory.daninhas;
      case 'nutricional':
      case 'nutrientes':
        return OccurrenceCategory.nutricional;
      case 'agua':
      case 'água':
      case 'estresse hídrico':
        return OccurrenceCategory.agua;
      default:
        return OccurrenceCategory.doenca;
    }
  }
}

// Status da ocorrência
enum OccurrenceStatus {
  draft('Rascunho'),
  confirmed('Confirmada');

  final String label;
  const OccurrenceStatus(this.label);
}

class Occurrence {
  final String id;
  final String? visitSessionId;
  final String type; // 'Urgente', 'Aviso', 'Info' (urgência/prioridade)
  final String description;
  final String? photoPath;
  final double? lat;
  final double? long;
  final DateTime createdAt;
  final DateTime
  updatedAt; // 🔄 Para resolver conflitos (local sempre ganha se mais recente)
  final String syncStatus; // 🔄 'local' | 'synced' | 'updated' | 'deleted'
  final String? category; // Categoria agronômica: 'doenca', 'insetos', etc
  final String? status; // 'draft' ou 'confirmed'

  Occurrence({
    required this.id,
    this.visitSessionId,
    required this.type,
    required this.description,
    this.photoPath,
    this.lat,
    this.long,
    required this.createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'local', // 🔄 Default: criado offline
    this.category,
    this.status = 'draft',
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory Occurrence.fromMap(Map<String, dynamic> map) {
    return Occurrence(
      id: map['id'],
      visitSessionId: map['visit_session_id'],
      type: map['type'],
      description: map['description'],
      photoPath: map['photo_path'],
      lat: map['lat'],
      long: map['long'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      syncStatus: OccurrenceSyncMapper.fromDb(map['sync_status']),
      category: map['category'],
      status: map['status'] ?? 'draft',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'visit_session_id': visitSessionId,
      'type': type,
      'description': description,
      'photo_path': photoPath,
      'lat': lat,
      'long': long,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': OccurrenceSyncMapper.toDb(syncStatus),
      'category': category,
      'status': status,
    };
  }

  Occurrence copyWith({
    String? id,
    String? visitSessionId,
    String? type,
    String? description,
    String? photoPath,
    double? lat,
    double? long,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? syncStatus,
    String? category,
    String? status,
  }) {
    return Occurrence(
      id: id ?? this.id,
      visitSessionId: visitSessionId ?? this.visitSessionId,
      type: type ?? this.type,
      description: description ?? this.description,
      photoPath: photoPath ?? this.photoPath,
      lat: lat ?? this.lat,
      long: long ?? this.long,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }
}
