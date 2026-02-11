import 'package:latlong2/latlong.dart';

enum LayerType { standard, satellite, terrain }

enum SyncStatus { pending, synced, error }

class MapLayer {
  final String id;
  final String name;
  final LayerType type;
  final bool isVisible;

  MapLayer({
    required this.id,
    required this.name,
    required this.type,
    this.isVisible = false,
  });

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type.name, 'isVisible': isVisible};
  }

  factory MapLayer.fromJson(Map<String, dynamic> json) {
    return MapLayer(
      id: json['id'],
      name: json['name'],
      type: LayerType.values.byName(json['type']),
      isVisible: json['isVisible'] ?? false,
    );
  }

  MapLayer copyWith({bool? isVisible}) {
    return MapLayer(
      id: id,
      name: name,
      type: type,
      isVisible: isVisible ?? this.isVisible,
    );
  }
}

/// Legacy entity mantida apenas para backward-compatibility de cache.
/// Use [Publicacao] de `core/domain/publicacao.dart` em vez desta.
/// Será removida em versão futura.
@Deprecated('Use Publicacao from core/domain/publicacao.dart — ADR-007')
class Publication {
  final String id;
  final String userName;
  final String userRole;
  final String description;
  final LatLng location;
  final String? imageUrl;
  final DateTime timestamp;
  final DateTime updatedAt;
  final SyncStatus syncStatus;
  final int retryCount;
  final DateTime? lastRetryAt;

  Publication({
    required this.id,
    required this.userName,
    required this.userRole,
    required this.description,
    required this.location,
    this.imageUrl,
    required this.timestamp,
    DateTime? updatedAt,
    this.syncStatus = SyncStatus.synced,
    this.retryCount = 0,
    this.lastRetryAt,
  }) : updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userName': userName,
      'userRole': userRole,
      'description': description,
      'location': {'lat': location.latitude, 'lng': location.longitude},
      'imageUrl': imageUrl,
      'timestamp': timestamp.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'syncStatus': syncStatus.name,
      'retryCount': retryCount,
      'lastRetryAt': lastRetryAt?.toIso8601String(),
    };
  }

  factory Publication.fromJson(Map<String, dynamic> json) {
    return Publication(
      id: json['id'],
      userName: json['userName'],
      userRole: json['userRole'],
      description: json['description'],
      location: LatLng(
        (json['location']['lat'] as num).toDouble(),
        (json['location']['lng'] as num).toDouble(),
      ),
      imageUrl: json['imageUrl'],
      timestamp: DateTime.parse(json['timestamp']),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
      syncStatus: json['syncStatus'] != null
          ? SyncStatus.values.byName(json['syncStatus'])
          : SyncStatus.synced,
      retryCount: json['retryCount'] ?? 0,
      lastRetryAt: json['lastRetryAt'] != null
          ? DateTime.parse(json['lastRetryAt'])
          : null,
    );
  }

  Publication copyWith({
    SyncStatus? syncStatus,
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return Publication(
      id: id,
      userName: userName,
      userRole: userRole,
      description: description,
      location: location,
      imageUrl: imageUrl,
      timestamp: timestamp,
      updatedAt: DateTime.now(),
      syncStatus: syncStatus ?? this.syncStatus,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}

class Occurrence {
  final String id;
  final String title;
  final String
  timeText; // Keeping consistent with UI "Há 2 horas" for now, ideally timestamp
  final String type;
  final int colorValue; // Store color as int
  final SyncStatus syncStatus;

  Occurrence({
    required this.id,
    required this.title,
    required this.timeText,
    required this.type,
    required this.colorValue,
    this.syncStatus = SyncStatus.synced,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'timeText': timeText,
      'type': type,
      'colorValue': colorValue,
      'syncStatus': syncStatus.name,
    };
  }

  factory Occurrence.fromJson(Map<String, dynamic> json) {
    return Occurrence(
      id: json['id'],
      title: json['title'],
      timeText: json['timeText'],
      type: json['type'],
      colorValue: json['colorValue'],
      syncStatus: json['syncStatus'] != null
          ? SyncStatus.values.byName(json['syncStatus'])
          : SyncStatus.synced,
    );
  }
}
