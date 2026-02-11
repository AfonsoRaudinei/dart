// ignore_for_file: constant_identifier_names
// =============================================================================
// ENUMS
// =============================================================================

enum DrawingType {
  talhao,
  zona_manejo,
  exclusao,
  buffer,
  teste,
  outro;

  String toJson() => name;
  static DrawingType fromJson(String json) => values.byName(json);
}

enum DrawingOrigin {
  desenho_manual,
  importacao_kml,
  importacao_kmz,
  gerado_sistema;

  String toJson() => name;
  static DrawingOrigin fromJson(String json) => values.byName(json);
}

enum DrawingStatus {
  rascunho,
  em_revisao,
  aprovado,
  arquivado;

  String toJson() => name;
  static DrawingStatus fromJson(String json) => values.byName(json);
}

enum AuthorType {
  consultor,
  cliente,
  sistema;

  String toJson() => name;
  static AuthorType fromJson(String json) => values.byName(json);
}

enum DrawingInteraction {
  normal,
  importing, // Selecting KML/KMZ
  importPreview, // Viewing imported geometry before confirm
  editing, // Editing existing feature vertices
  unionSelection, // Combining areas
  differenceSelection, // Subtracting area B from A
  intersectionSelection, // Keep only overlapping area
}

// =============================================================================
// GEOMETRY
// =============================================================================

abstract class DrawingGeometry {
  final String type;

  DrawingGeometry(this.type);

  Map<String, dynamic> toJson();

  static DrawingGeometry fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    switch (type) {
      case 'Polygon':
        return DrawingPolygon.fromJson(json);
      case 'MultiPolygon':
        return DrawingMultiPolygon.fromJson(json);
      default:
        throw ArgumentError('Unsupported geometry type: $type');
    }
  }
}

class DrawingPolygon extends DrawingGeometry {
  final List<List<List<double>>> coordinates;

  DrawingPolygon({required this.coordinates}) : super('Polygon') {
    _validateAndFix();
  }

  /// Ensures rings are closed (first point == last point)
  void _validateAndFix() {
    for (var i = 0; i < coordinates.length; i++) {
      final ring = coordinates[i];
      if (ring.isEmpty) continue;

      final first = ring.first;
      final last = ring.last;

      if (first[0] != last[0] || first[1] != last[1]) {
        // Auto-close ring
        coordinates[i] = [...ring, first];
      }
    }
  }

  @override
  Map<String, dynamic> toJson() => {'type': type, 'coordinates': coordinates};

  factory DrawingPolygon.fromJson(Map<String, dynamic> json) {
    final coordsRaw = json['coordinates'] as List;
    final List<List<List<double>>> coords = coordsRaw.map((ring) {
      return (ring as List).map((point) {
        return (point as List)
            .map((coord) => (coord as num).toDouble())
            .toList();
      }).toList();
    }).toList();
    return DrawingPolygon(coordinates: coords);
  }
}

class DrawingMultiPolygon extends DrawingGeometry {
  final List<List<List<List<double>>>> coordinates;

  DrawingMultiPolygon({required this.coordinates}) : super('MultiPolygon');

  @override
  Map<String, dynamic> toJson() => {'type': type, 'coordinates': coordinates};

  factory DrawingMultiPolygon.fromJson(Map<String, dynamic> json) {
    var coordsRaw = json['coordinates'] as List;
    final List<List<List<List<double>>>> coords = coordsRaw.map((polygon) {
      return (polygon as List).map((ring) {
        return (ring as List).map((point) {
          return (point as List)
              .map((coord) => (coord as num).toDouble())
              .toList();
        }).toList();
      }).toList();
    }).toList();
    return DrawingMultiPolygon(coordinates: coords);
  }
}

// =============================================================================
// PROPERTIES
// =============================================================================

enum SyncStatus {
  local_only,
  pending_sync,
  synced,
  conflict;

  String toJson() => name;
  static SyncStatus fromJson(String json) => values.byName(json);
}

class DrawingProperties {
  final String nome;
  final DrawingType tipo;
  final DrawingOrigin origem;
  final DrawingStatus status;
  final String autorId;
  final AuthorType autorTipo;
  final String? operacaoId;
  final String? clienteId;  // 🆕 NOVO CAMPO
  final String? fazendaId;
  final double areaHa;
  final int versao;
  final bool ativo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final SyncStatus syncStatus;

  // Pivot Metadata
  final String? subtipo; // "pivo"
  final double? raioMetros;

  // Versioning
  final String? versaoAnteriorId;

  DrawingProperties({
    required this.nome,
    required this.tipo,
    required this.origem,
    required this.status,
    required this.autorId,
    required this.autorTipo,
    this.operacaoId,
    this.clienteId,     // 🆕 NOVO CAMPO
    this.fazendaId,
    required this.areaHa,
    required this.versao,
    required this.ativo,
    required this.createdAt,
    required this.updatedAt,
    this.syncStatus = SyncStatus.local_only,
    this.subtipo,
    this.raioMetros,
    this.versaoAnteriorId,
  });

  Map<String, dynamic> toJson() => {
    'nome': nome,
    'tipo': tipo.toJson(),
    'origem': origem.toJson(),
    'status': status.toJson(),
    'autor_id': autorId,
    'autor_tipo': autorTipo.toJson(),
    'operacao_id': operacaoId,
    'cliente_id': clienteId,  // 🆕 NOVO CAMPO
    'fazenda_id': fazendaId,
    'area_ha': areaHa,
    'versao': versao,
    'ativo': ativo,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
    'sync_status': syncStatus.toJson(),
    'subtipo': subtipo,
    'raio_metros': raioMetros,
    'versao_anterior_id': versaoAnteriorId,
  };

  factory DrawingProperties.fromJson(Map<String, dynamic> json) {
    return DrawingProperties(
      nome: json['nome'],
      tipo: DrawingType.fromJson(json['tipo']),
      origem: DrawingOrigin.fromJson(json['origem']),
      status: DrawingStatus.fromJson(json['status']),
      autorId: json['autor_id'],
      autorTipo: AuthorType.fromJson(json['autor_tipo']),
      operacaoId: json['operacao_id'],
      clienteId: json['cliente_id'],  // 🆕 NOVO CAMPO
      fazendaId: json['fazenda_id'],
      areaHa: (json['area_ha'] as num).toDouble(),
      versao: json['versao'],
      ativo: json['ativo'] ?? true,
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      syncStatus: json['sync_status'] != null
          ? SyncStatus.fromJson(json['sync_status'])
          : SyncStatus.local_only,
      subtipo: json['subtipo'],
      raioMetros: json['raio_metros']?.toDouble(),
      versaoAnteriorId: json['versao_anterior_id'],
    );
  }

  DrawingProperties copyWith({
    String? nome,
    DrawingType? tipo,
    DrawingOrigin? origem,
    DrawingStatus? status,
    String? autorId,
    AuthorType? autorTipo,
    String? operacaoId,
    String? clienteId,     // 🆕 NOVO CAMPO
    String? fazendaId,
    double? areaHa,
    int? versao,
    bool? ativo,
    DateTime? createdAt,
    DateTime? updatedAt,
    SyncStatus? syncStatus,
    String? subtipo,
    double? raioMetros,
    String? versaoAnteriorId,
  }) {
    return DrawingProperties(
      nome: nome ?? this.nome,
      tipo: tipo ?? this.tipo,
      origem: origem ?? this.origem,
      status: status ?? this.status,
      autorId: autorId ?? this.autorId,
      autorTipo: autorTipo ?? this.autorTipo,
      operacaoId: operacaoId ?? this.operacaoId,
      clienteId: clienteId ?? this.clienteId,     // 🆕 NOVO CAMPO
      fazendaId: fazendaId ?? this.fazendaId,
      areaHa: areaHa ?? this.areaHa,
      versao: versao ?? this.versao,
      ativo: ativo ?? this.ativo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      syncStatus: syncStatus ?? this.syncStatus,
      subtipo: subtipo ?? this.subtipo,
      raioMetros: raioMetros ?? this.raioMetros,
      versaoAnteriorId: versaoAnteriorId ?? this.versaoAnteriorId,
    );
  }
}

// =============================================================================
// FEATURE
// =============================================================================

class DrawingFeature {
  final String type = 'Feature';
  final String id;
  final DrawingGeometry geometry;
  final DrawingProperties properties;

  DrawingFeature({
    required this.id,
    required this.geometry,
    required this.properties,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'id': id,
    'geometry': geometry.toJson(),
    'properties': properties.toJson(),
  };

  factory DrawingFeature.fromJson(Map<String, dynamic> json) {
    if (json['type'] != 'Feature') {
      throw ArgumentError(
        "Invalid GeoJSON type: ${json['type']}. Expected 'Feature'.",
      );
    }
    return DrawingFeature(
      id: json['id'],
      geometry: DrawingGeometry.fromJson(json['geometry']),
      properties: DrawingProperties.fromJson(json['properties']),
    );
  }

  bool get isPivot => properties.subtipo == 'pivo';

  /// Creates a new version of this feature with updated fields.
  /// Sets the current feature as 'inactive' implicitly by returning a new one
  /// that points to this one as 'previous'.
  /// The caller is responsible for setting the old one's active=false in persistence.
  DrawingFeature createNewVersion({
    required String newId,
    required String newName,
    required DrawingGeometry newGeometry,
    required double newAreaHa,
    required String authorId,
    required AuthorType authorType,
  }) {
    return DrawingFeature(
      id: newId,
      geometry: newGeometry,
      properties: properties.copyWith(
        nome: newName,
        areaHa: newAreaHa,
        versao: properties.versao + 1,
        versaoAnteriorId: id,
        updatedAt: DateTime.now(),
        // Update author to whoever is making the change
        autorId: authorId,
        autorTipo: authorType,
      ),
    );
  }
}
