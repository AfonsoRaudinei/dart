import 'dart:convert';

enum SyncStatus {
  local,
  synced,
  updated,
  deleted;

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

enum OccurrenceStatus {
  draft('Rascunho'),
  confirmed('Confirmada');

  final String label;
  const OccurrenceStatus(this.label);
}

class Occurrence {
  final String id;
  final String? visitSessionId;
  final String type;
  final String description;
  final String? photoPath;
  final double? lat;
  final double? long;
  final String? geometry;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String syncStatus;
  final String? category;
  final String? status;

  Occurrence({
    required this.id,
    this.visitSessionId,
    required this.type,
    required this.description,
    this.photoPath,
    this.lat,
    this.long,
    this.geometry,
    required this.createdAt,
    DateTime? updatedAt,
    this.syncStatus = 'local',
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
      geometry: map['geometry'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      syncStatus: map['sync_status'] ?? 'local',
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
      'geometry': geometry,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sync_status': syncStatus,
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
    String? geometry,
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
      geometry: geometry ?? this.geometry,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      category: category ?? this.category,
      status: status ?? this.status,
    );
  }

  Map<String, double>? getCoordinates() {
    if (geometry != null) {
      try {
        final decoded = jsonDecode(geometry!);
        if (decoded['type'] == 'Point' && decoded['coordinates'] != null) {
          final coords = decoded['coordinates'] as List;
          if (coords.length >= 2) {
            return {
              'lat': (coords[1] as num).toDouble(),
              'long': (coords[0] as num).toDouble(),
            };
          }
        }
      } catch (_) {}
    }

    if (lat != null && long != null) {
      return {'lat': lat!, 'long': long!};
    }

    return null;
  }
}
