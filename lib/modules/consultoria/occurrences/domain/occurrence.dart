import 'dart:convert';
import 'package:flutter/painting.dart';
import '../../../../core/utils/app_logger.dart';

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
  agua('Água', '💧'),
  amostraSolo('Amostra de Solo', '🧪');

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
      case 'ervas_daninhas':
        return OccurrenceCategory.daninhas;
      case 'nutricional':
      case 'nutrientes':
        return OccurrenceCategory.nutricional;
      case 'agua':
      case 'água':
      case 'estresse hídrico':
        return OccurrenceCategory.agua;
      case 'amostra_solo':
      case 'amostra solo':
      case 'amostra de solo':
        return OccurrenceCategory.amostraSolo;
      default:
        return OccurrenceCategory.doenca;
    }
  }
}

extension OccurrenceCategoryColor on OccurrenceCategory {
  Color get markerColor {
    if (this == OccurrenceCategory.doenca) {
      return const Color(0xFFE53935);
    }
    if (this == OccurrenceCategory.insetos) {
      return const Color(0xFFF59E0B);
    }
    if (this == OccurrenceCategory.daninhas) {
      return const Color(0xFF7CB342);
    }
    if (this == OccurrenceCategory.nutricional) {
      return const Color(0xFF1E88E5);
    }
    if (this == OccurrenceCategory.agua) {
      return const Color(0xFF00ACC1);
    }
    if (this == OccurrenceCategory.amostraSolo) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF616161);
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
  final String? clientId;
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

  // ── Campos agronômicos (Schema v14) ─────────────────────────────────
  final String? cultivar;
  final String? dataPlantio; // ISO "yyyy-MM-dd"
  final String? estadioFenologico; // código ex.: "V4", "R5.1"
  final String? tipoOcorrencia; // "sazonal" | "permanente"
  final bool amostraSolo;
  final String? recomendacoes;
  final String? metricasJson; // {cat: {metric: valor}}
  final String? nutrientesJson; // lista de símbolos selecionados
  final String? categoriasJson; // lista de categorias ativas
  final String? notasCategoriasJson; // {cat: texto}
  final String? fotosCategoriasJson; // {cat: [paths]}

  Occurrence({
    required this.id,
    this.visitSessionId,
    this.clientId,
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
    // v14 agronômico
    this.cultivar,
    this.dataPlantio,
    this.estadioFenologico,
    this.tipoOcorrencia,
    this.amostraSolo = false,
    this.recomendacoes,
    this.metricasJson,
    this.nutrientesJson,
    this.categoriasJson,
    this.notasCategoriasJson,
    this.fotosCategoriasJson,
  }) : updatedAt = updatedAt ?? DateTime.now();

  factory Occurrence.fromMap(Map<String, dynamic> map) {
    final category = map['category'] as String?;
    final amostraSoloDb = (map['amostra_solo'] as int? ?? 0) == 1;
    final amostraSoloByCategory =
        (category ?? '').toLowerCase() == 'amostra_solo' ||
        (category ?? '').toLowerCase() == 'amostra solo' ||
        (category ?? '').toLowerCase() == 'amostra de solo';

    return Occurrence(
      id: map['id'],
      visitSessionId: map['visit_session_id'],
      clientId: map['client_id'] as String?,
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
      category: category,
      status: map['status'] ?? 'draft',
      // v14 agronômico
      cultivar: map['cultivar'],
      dataPlantio: map['data_plantio'],
      estadioFenologico: map['estadio_fenologico'],
      tipoOcorrencia: map['tipo_ocorrencia'],
      // Back-compat: alguns fluxos antigos salvavam apenas `category`
      // e deixavam `amostra_solo` como 0. Garantimos consistência.
      amostraSolo: amostraSoloDb || amostraSoloByCategory,
      recomendacoes: map['recomendacoes'],
      metricasJson: map['metricas_json'],
      nutrientesJson: map['nutrientes_json'],
      categoriasJson: map['categorias_json'],
      notasCategoriasJson: map['notas_categorias_json'],
      fotosCategoriasJson: map['fotos_categorias_json'],
    );
  }

  Map<String, dynamic> toMap() {
    final categoryLower = (category ?? '').toLowerCase();
    final isAmostraSoloCategory =
        categoryLower == 'amostra_solo' ||
        categoryLower == 'amostra solo' ||
        categoryLower == 'amostra de solo';

    return {
      'id': id,
      'visit_session_id': visitSessionId,
      'client_id': clientId,
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
      // v14 agronômico
      'cultivar': cultivar,
      'data_plantio': dataPlantio,
      'estadio_fenologico': estadioFenologico,
      'tipo_ocorrencia': tipoOcorrencia,
      // Consistência: se a categoria indica amostra de solo,
      // garantimos flag = 1 mesmo que amostraSolo esteja false.
      'amostra_solo': (amostraSolo || isAmostraSoloCategory) ? 1 : 0,
      'recomendacoes': recomendacoes,
      'metricas_json': metricasJson,
      'nutrientes_json': nutrientesJson,
      'categorias_json': categoriasJson,
      'notas_categorias_json': notasCategoriasJson,
      'fotos_categorias_json': fotosCategoriasJson,
    };
  }

  Occurrence copyWith({
    String? id,
    String? visitSessionId,
    String? clientId,
    bool clearClientId = false,
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
    // v14 agronômico
    String? cultivar,
    String? dataPlantio,
    String? estadioFenologico,
    String? tipoOcorrencia,
    bool? amostraSolo,
    String? recomendacoes,
    String? metricasJson,
    String? nutrientesJson,
    String? categoriasJson,
    String? notasCategoriasJson,
    String? fotosCategoriasJson,
  }) {
    return Occurrence(
      id: id ?? this.id,
      visitSessionId: visitSessionId ?? this.visitSessionId,
      clientId: clearClientId ? null : (clientId ?? this.clientId),
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
      // v14 agronômico
      cultivar: cultivar ?? this.cultivar,
      dataPlantio: dataPlantio ?? this.dataPlantio,
      estadioFenologico: estadioFenologico ?? this.estadioFenologico,
      tipoOcorrencia: tipoOcorrencia ?? this.tipoOcorrencia,
      amostraSolo: amostraSolo ?? this.amostraSolo,
      recomendacoes: recomendacoes ?? this.recomendacoes,
      metricasJson: metricasJson ?? this.metricasJson,
      nutrientesJson: nutrientesJson ?? this.nutrientesJson,
      categoriasJson: categoriasJson ?? this.categoriasJson,
      notasCategoriasJson: notasCategoriasJson ?? this.notasCategoriasJson,
      fotosCategoriasJson: fotosCategoriasJson ?? this.fotosCategoriasJson,
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
      } catch (e) {
        AppLogger.debug(
          'Falha ao parsear geometry da ocorrência — $e',
          tag: 'Occurrence',
        );
      }
    }

    if (lat != null && long != null) {
      return {'lat': lat!, 'long': long!};
    }

    return null;
  }
}
