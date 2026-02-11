import 'package:latlong2/latlong.dart';

// ════════════════════════════════════════════════════════════════════
// ENTIDADE CANÔNICA: Publicacao (ADR-007)
// Conteúdo georreferenciado, nativo do mapa (/map, L0).
// Não é módulo. Não é L1/L2. Vive exclusivamente no mapa.
// ════════════════════════════════════════════════════════════════════

/// Tipos de publicação — enum fechado.
/// Tipo classifica conteúdo, NÃO altera fluxo de navegação.
enum PublicacaoType {
  institucional,
  tecnico,
  resultado,
  comparativo,
  caseSucesso,
}

/// Item de mídia associado a uma Publicacao.
class MediaItem {
  final String id;
  final String path;
  final String? caption;
  final bool isCover;

  const MediaItem({
    required this.id,
    required this.path,
    this.caption,
    this.isCover = false,
  });

  MediaItem copyWith({String? path, String? caption, bool? isCover}) {
    return MediaItem(
      id: id,
      path: path ?? this.path,
      caption: caption ?? this.caption,
      isCover: isCover ?? this.isCover,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'caption': caption,
        'isCover': isCover,
      };

  factory MediaItem.fromJson(Map<String, dynamic> json) => MediaItem(
        id: json['id'] as String,
        path: json['path'] as String,
        caption: json['caption'] as String?,
        isCover: json['isCover'] as bool? ?? false,
      );
}

/// Entidade canônica de Publicação (ADR-007).
///
/// Campos obrigatórios: id, latitude, longitude, createdAt, status,
/// isVisible, media, coverMedia (derivado).
class Publicacao {
  final String id;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final String status; // ex: 'draft', 'published'
  final bool isVisible;
  final PublicacaoType type;
  final String? title;
  final String? description;
  final String? clientName;
  final String? areaName;
  final List<MediaItem> media;

  const Publicacao({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.status,
    required this.isVisible,
    required this.type,
    this.title,
    this.description,
    this.clientName,
    this.areaName,
    this.media = const [],
  });

  /// Coordenada LatLng derivada.
  LatLng get location => LatLng(latitude, longitude);

  /// coverMedia derivada — NUNCA opcional.
  /// Se nenhuma mídia está marcada como capa, usa a primeira.
  /// Se não há mídia, retorna placeholder defensivo.
  MediaItem get coverMedia {
    if (media.isEmpty) {
      return const MediaItem(
        id: '__placeholder__',
        path: '',
        isCover: true,
      );
    }
    final covers = media.where((m) => m.isCover);
    return covers.isNotEmpty ? covers.first : media.first;
  }

  /// Garante que sempre exista uma capa marcada.
  Publicacao ensureCover() {
    if (media.isEmpty) return this;
    if (media.any((m) => m.isCover)) return this;
    final updated = media
        .asMap()
        .entries
        .map(
          (entry) => entry.key == 0
              ? entry.value.copyWith(isCover: true)
              : entry.value,
        )
        .toList();
    return copyWith(media: updated);
  }

  Publicacao copyWith({
    String? id,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    String? status,
    bool? isVisible,
    PublicacaoType? type,
    String? title,
    String? description,
    String? clientName,
    String? areaName,
    List<MediaItem>? media,
  }) {
    return Publicacao(
      id: id ?? this.id,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      isVisible: isVisible ?? this.isVisible,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      clientName: clientName ?? this.clientName,
      areaName: areaName ?? this.areaName,
      media: media ?? this.media,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': createdAt.toIso8601String(),
        'status': status,
        'isVisible': isVisible,
        'type': type.name,
        'title': title,
        'description': description,
        'clientName': clientName,
        'areaName': areaName,
        'media': media.map((m) => m.toJson()).toList(),
      };

  factory Publicacao.fromJson(Map<String, dynamic> json) => Publicacao(
        id: json['id'] as String,
        latitude: (json['latitude'] as num).toDouble(),
        longitude: (json['longitude'] as num).toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: json['status'] as String,
        isVisible: json['isVisible'] as bool? ?? true,
        type: PublicacaoType.values.byName(json['type'] as String),
        title: json['title'] as String?,
        description: json['description'] as String?,
        clientName: json['clientName'] as String?,
        areaName: json['areaName'] as String?,
        media: (json['media'] as List<dynamic>?)
                ?.map(
                    (m) => MediaItem.fromJson(m as Map<String, dynamic>))
                .toList() ??
            const [],
      );
}
