import 'dart:convert';
import 'package:flutter/painting.dart';
import '../../../../core/domain/occurrence_recomendacao_ordem.dart';
import '../../../../core/services/sync_status_contract.dart';
import '../../../../core/utils/app_logger.dart';
import 'occurrence_andamento.dart';

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
  amostraSolo('Amostra de Solo', '🧪'),
  plantio('Plantio', '🌾'),
  areaVisitada('Área Visitada', '📍');

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
      case 'plantio':
        return OccurrenceCategory.plantio;
      case 'area_visitada':
      case 'area visitada':
      case 'areavisitada':
        return OccurrenceCategory.areaVisitada;
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
    if (this == OccurrenceCategory.plantio) {
      return const Color(0xFF795548);
    }
    if (this == OccurrenceCategory.areaVisitada) {
      return const Color(0xFF607D8B);
    }
    return const Color(0xFF616161);
  }
}

/// Avaliação de plantio persistida em [Occurrence.avaliacaoPlantio].
String? sanitizeAvaliacaoPlantio(String? value) {
  if (value == 'boa' || value == 'ruim') return value;
  return null;
}

/// Valor persistido em [Occurrence.category] para pins de área visitada (A1).
const kOccurrenceAreaVisitadaCategory = 'area_visitada';

/// Parsing de categoria — aceita snake (`area_visitada`) e nome enum (`areaVisitada`).
bool isAreaVisitadaCategory(String? category) {
  if (category == null || category.trim().isEmpty) return false;
  if (category == kOccurrenceAreaVisitadaCategory) return true;
  return OccurrenceCategory.fromString(category) ==
      OccurrenceCategory.areaVisitada;
}

extension OccurrenceAreaVisitadaX on Occurrence {
  bool get isAreaVisitada => isAreaVisitadaCategory(category);

  /// Área visitada sem cliente vinculado — indicador "pendente de vínculo".
  bool get pendingClientLink =>
      isAreaVisitada && (clientId == null || clientId!.trim().isEmpty);
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
  final String? remoteId;
  final String? ownerUserId;
  final String? cachedByUserId;
  final String? externalSource;
  final String? externalAnalysisId;
  final String? analysisPayloadJson;
  final String? deletedAt;

  // ── Campos agronômicos (Schema v14) ─────────────────────────────────
  final String? cultivar;
  final String? dataPlantio; // ISO "yyyy-MM-dd"
  final String? estadioFenologico; // código ex.: "V4", "R5.1"
  final String? tipoOcorrencia; // "sazonal" | "permanente"
  final bool amostraSolo;
  final String? recomendacoes;
  final String? recomendacaoAcao;
  final String? recomendacaoDose;
  final String? recomendacaoQuando;
  final String? metricasJson; // {cat: {metric: valor}}
  final String? nutrientesJson; // lista de símbolos selecionados
  final String? categoriasJson; // lista de categorias ativas
  final String? notasCategoriasJson; // {cat: texto}
  final String? fotosCategoriasJson; // {cat: [paths]}

  // ── Campos de plantio (Schema v47) ──────────────────────────────────
  final String? dataEmergencia; // ISO "yyyy-MM-dd"
  final double? sementesPorMetro;
  final int? estandePlantas;
  final String? avaliacaoPlantio; // "boa" | "ruim"
  final String? objetivoPlantio;

  // ── Término do plantio e ciclo (Schema v51 — ADR-058) ───────────────
  final String? dataFimPlantio; // ISO "yyyy-MM-dd"
  final int? cicloDias;

  // ── Cultura e safra (Schema v52 — ADR-059) ──────────────────────────
  final String? cultura;
  final String? safra; // "AAAA/AAAA+1"

  final String? andamento;
  final String? responsavelNome;
  /// Path local (`media/audio_….m4a`) — gravação de até 30 s.
  final String? audioPath;

  /// Duração gravada em segundos (1–30).
  final int? audioDurationSec;
  // ── Amostra de solo (Schema v49 — GeoData-style) ────────────────────
  final String? amostraCodigo;
  final String? amostraColetor;
  final String? amostraTramite;
  final String? amostraLaudoTexto;

  /// JSON reservado para resultados analíticos (fase 2).
  final String? amostraAnalisesJson;
  /// Talhão resolvido na criação (SQLite v49). Nulo em registros legados.
  final String? fieldId;

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
    this.syncStatus = SyncStatusContract.localOnly,
    this.category,
    this.status = 'draft',
    this.remoteId,
    this.ownerUserId,
    this.cachedByUserId,
    this.externalSource,
    this.externalAnalysisId,
    this.analysisPayloadJson,
    this.deletedAt,
    // v14 agronômico
    this.cultivar,
    this.dataPlantio,
    this.estadioFenologico,
    this.tipoOcorrencia,
    this.amostraSolo = false,
    this.recomendacoes,
    this.recomendacaoAcao,
    this.recomendacaoDose,
    this.recomendacaoQuando,
    this.metricasJson,
    this.nutrientesJson,
    this.categoriasJson,
    this.notasCategoriasJson,
    this.fotosCategoriasJson,
    this.dataEmergencia,
    this.sementesPorMetro,
    this.estandePlantas,
    this.avaliacaoPlantio,
    this.objetivoPlantio,
    this.dataFimPlantio,
    this.cicloDias,
    this.cultura,
    this.safra,
    this.andamento = 'aberta',
    this.responsavelNome,
    this.audioPath,
    this.audioDurationSec,
    this.amostraCodigo,
    this.amostraColetor,
    this.amostraTramite,
    this.amostraLaudoTexto,
    this.amostraAnalisesJson,
    this.fieldId,
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
      syncStatus: SyncStatusContract.normalize(map['sync_status'] as String?),
      category: category,
      status: map['status'] ?? 'draft',
      remoteId: map['remote_id'] as String?,
      ownerUserId: map['user_id'] as String?,
      cachedByUserId: map['cached_by_user_id'] as String?,
      externalSource: map['external_source'] as String?,
      externalAnalysisId: map['external_analysis_id'] as String?,
      analysisPayloadJson: map['analysis_payload_json'] as String?,
      deletedAt: map['deleted_at'] as String?,
      // v14 agronômico
      cultivar: map['cultivar'],
      dataPlantio: map['data_plantio'],
      estadioFenologico: map['estadio_fenologico'],
      tipoOcorrencia: map['tipo_ocorrencia'],
      // Back-compat: alguns fluxos antigos salvavam apenas `category`
      // e deixavam `amostra_solo` como 0. Garantimos consistência.
      amostraSolo: amostraSoloDb || amostraSoloByCategory,
      recomendacoes: OccurrenceRecomendacaoOrdem.normalize(
        map['recomendacoes'] as String?,
      ),
      recomendacaoAcao: OccurrenceRecomendacaoOrdem.normalize(
        map['recomendacao_acao'] as String?,
      ),
      recomendacaoDose: OccurrenceRecomendacaoOrdem.normalize(
        map['recomendacao_dose'] as String?,
      ),
      recomendacaoQuando: OccurrenceRecomendacaoOrdem.normalize(
        map['recomendacao_quando'] as String?,
      ),
      metricasJson: map['metricas_json'],
      nutrientesJson: map['nutrientes_json'],
      categoriasJson: map['categorias_json'],
      notasCategoriasJson: map['notas_categorias_json'],
      fotosCategoriasJson: map['fotos_categorias_json'],
      dataEmergencia: map['data_emergencia'] as String?,
      sementesPorMetro: (map['sementes_por_metro'] as num?)?.toDouble(),
      estandePlantas: (map['estande_plantas'] as num?)?.toInt(),
      avaliacaoPlantio: sanitizeAvaliacaoPlantio(
        map['avaliacao_plantio'] as String?,
      ),
      objetivoPlantio: map['objetivo_plantio'] as String?,
      dataFimPlantio: map['data_fim_plantio'] as String?,
      cicloDias: (map['ciclo_dias'] as num?)?.toInt(),
      cultura: map['cultura'] as String?,
      safra: map['safra'] as String?,
      andamento: OccurrenceAndamento.normalizeStorage(
            map['andamento'] as String?,
          ) ??
          OccurrenceAndamento.aberta.storageValue,
      responsavelNome: map['responsavel_nome'] as String?,
      audioPath: map['audio_path'] as String?,
      audioDurationSec: (map['audio_duration_sec'] as num?)?.toInt(),
      amostraCodigo: map['amostra_codigo'] as String?,
      amostraColetor: map['amostra_coletor'] as String?,
      amostraTramite: map['amostra_tramite'] as String?,
      amostraLaudoTexto: map['amostra_laudo_texto'] as String?,
      amostraAnalisesJson: map['amostra_analises_json'] as String?,
      fieldId: map['field_id'] as String?,
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
      'sync_status': SyncStatusContract.normalize(syncStatus),
      'category': category,
      'status': status,
      'remote_id': remoteId,
      'cached_by_user_id': cachedByUserId,
      'external_source': externalSource,
      'external_analysis_id': externalAnalysisId,
      'analysis_payload_json': analysisPayloadJson,
      'deleted_at': deletedAt,
      // v14 agronômico
      'cultivar': cultivar,
      'data_plantio': dataPlantio,
      'estadio_fenologico': estadioFenologico,
      'tipo_ocorrencia': tipoOcorrencia,
      // Consistência: se a categoria indica amostra de solo,
      // garantimos flag = 1 mesmo que amostraSolo esteja false.
      'amostra_solo': (amostraSolo || isAmostraSoloCategory) ? 1 : 0,
      'recomendacoes': OccurrenceRecomendacaoOrdem.mirrorLegacy(
        acao: recomendacaoAcao,
        dose: recomendacaoDose,
        quando: recomendacaoQuando,
        legacy: recomendacoes,
      ),
      'recomendacao_acao': recomendacaoAcao,
      'recomendacao_dose': recomendacaoDose,
      'recomendacao_quando': recomendacaoQuando,
      'metricas_json': metricasJson,
      'nutrientes_json': nutrientesJson,
      'categorias_json': categoriasJson,
      'notas_categorias_json': notasCategoriasJson,
      'fotos_categorias_json': fotosCategoriasJson,
      'data_emergencia': dataEmergencia,
      'sementes_por_metro': sementesPorMetro,
      'estande_plantas': estandePlantas,
      'avaliacao_plantio': avaliacaoPlantio,
      'objetivo_plantio': objetivoPlantio,
      'data_fim_plantio': dataFimPlantio,
      'ciclo_dias': cicloDias,
      'cultura': cultura,
      'safra': safra,
      'andamento': andamento ?? OccurrenceAndamento.aberta.storageValue,
      'responsavel_nome': responsavelNome,
      'audio_path': audioPath,
      'audio_duration_sec': audioDurationSec,
      'amostra_codigo': amostraCodigo,
      'amostra_coletor': amostraColetor,
      'amostra_tramite': amostraTramite,
      'amostra_laudo_texto': amostraLaudoTexto,
      'amostra_analises_json': amostraAnalisesJson,
      'field_id': fieldId,
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
    String? remoteId,
    String? ownerUserId,
    String? cachedByUserId,
    String? externalSource,
    String? externalAnalysisId,
    String? analysisPayloadJson,
    String? deletedAt,
    // v14 agronômico
    String? cultivar,
    bool clearCultivar = false,
    String? dataPlantio,
    bool clearDataPlantio = false,
    String? estadioFenologico,
    String? tipoOcorrencia,
    bool? amostraSolo,
    String? recomendacoes,
    String? recomendacaoAcao,
    String? recomendacaoDose,
    String? recomendacaoQuando,
    bool replaceRecomendacaoOrdem = false,
    String? metricasJson,
    String? nutrientesJson,
    String? categoriasJson,
    String? notasCategoriasJson,
    String? fotosCategoriasJson,
    String? dataEmergencia,
    bool clearDataEmergencia = false,
    double? sementesPorMetro,
    bool clearSementesPorMetro = false,
    int? estandePlantas,
    bool clearEstandePlantas = false,
    String? avaliacaoPlantio,
    bool clearAvaliacaoPlantio = false,
    String? objetivoPlantio,
    bool clearObjetivoPlantio = false,
    String? dataFimPlantio,
    bool clearDataFimPlantio = false,
    int? cicloDias,
    bool clearCicloDias = false,
    String? cultura,
    bool clearCultura = false,
    String? safra,
    bool clearSafra = false,
    String? andamento,
    String? responsavelNome,
    bool clearResponsavelNome = false,
    String? audioPath,
    bool clearAudioPath = false,
    int? audioDurationSec,
    bool clearAudioDurationSec = false,
    String? amostraCodigo,
    bool clearAmostraCodigo = false,
    String? amostraColetor,
    bool clearAmostraColetor = false,
    String? amostraTramite,
    bool clearAmostraTramite = false,
    String? amostraLaudoTexto,
    bool clearAmostraLaudoTexto = false,
    String? amostraAnalisesJson,
    String? fieldId,
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
      remoteId: remoteId ?? this.remoteId,
      ownerUserId: ownerUserId ?? this.ownerUserId,
      cachedByUserId: cachedByUserId ?? this.cachedByUserId,
      externalSource: externalSource ?? this.externalSource,
      externalAnalysisId: externalAnalysisId ?? this.externalAnalysisId,
      analysisPayloadJson: analysisPayloadJson ?? this.analysisPayloadJson,
      deletedAt: deletedAt ?? this.deletedAt,
      // v14 agronômico
      cultivar: clearCultivar ? null : (cultivar ?? this.cultivar),
      dataPlantio:
          clearDataPlantio ? null : (dataPlantio ?? this.dataPlantio),
      estadioFenologico: estadioFenologico ?? this.estadioFenologico,
      tipoOcorrencia: tipoOcorrencia ?? this.tipoOcorrencia,
      amostraSolo: amostraSolo ?? this.amostraSolo,
      recomendacoes: replaceRecomendacaoOrdem
          ? recomendacoes
          : (recomendacoes ?? this.recomendacoes),
      recomendacaoAcao: replaceRecomendacaoOrdem
          ? recomendacaoAcao
          : (recomendacaoAcao ?? this.recomendacaoAcao),
      recomendacaoDose: replaceRecomendacaoOrdem
          ? recomendacaoDose
          : (recomendacaoDose ?? this.recomendacaoDose),
      recomendacaoQuando: replaceRecomendacaoOrdem
          ? recomendacaoQuando
          : (recomendacaoQuando ?? this.recomendacaoQuando),
      metricasJson: metricasJson ?? this.metricasJson,
      nutrientesJson: nutrientesJson ?? this.nutrientesJson,
      categoriasJson: categoriasJson ?? this.categoriasJson,
      notasCategoriasJson: notasCategoriasJson ?? this.notasCategoriasJson,
      fotosCategoriasJson: fotosCategoriasJson ?? this.fotosCategoriasJson,
      dataEmergencia: clearDataEmergencia
          ? null
          : (dataEmergencia ?? this.dataEmergencia),
      sementesPorMetro: clearSementesPorMetro
          ? null
          : (sementesPorMetro ?? this.sementesPorMetro),
      estandePlantas: clearEstandePlantas
          ? null
          : (estandePlantas ?? this.estandePlantas),
      avaliacaoPlantio: clearAvaliacaoPlantio
          ? null
          : (avaliacaoPlantio ?? this.avaliacaoPlantio),
      objetivoPlantio: clearObjetivoPlantio
          ? null
          : (objetivoPlantio ?? this.objetivoPlantio),
      dataFimPlantio: clearDataFimPlantio
          ? null
          : (dataFimPlantio ?? this.dataFimPlantio),
      cicloDias: clearCicloDias ? null : (cicloDias ?? this.cicloDias),
      cultura: clearCultura ? null : (cultura ?? this.cultura),
      safra: clearSafra ? null : (safra ?? this.safra),
      andamento: andamento ?? this.andamento,
      responsavelNome: clearResponsavelNome
          ? null
          : (responsavelNome ?? this.responsavelNome),
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      audioDurationSec: clearAudioDurationSec
          ? null
          : (audioDurationSec ?? this.audioDurationSec),
      amostraCodigo:
          clearAmostraCodigo ? null : (amostraCodigo ?? this.amostraCodigo),
      amostraColetor:
          clearAmostraColetor ? null : (amostraColetor ?? this.amostraColetor),
      amostraTramite:
          clearAmostraTramite ? null : (amostraTramite ?? this.amostraTramite),
      amostraLaudoTexto: clearAmostraLaudoTexto
          ? null
          : (amostraLaudoTexto ?? this.amostraLaudoTexto),
      amostraAnalisesJson: amostraAnalisesJson ?? this.amostraAnalisesJson,
      fieldId: fieldId ?? this.fieldId,
    );
  }

  OccurrenceAndamento get andamentoEnum =>
      OccurrenceAndamento.fromStorage(andamento);

  String get andamentoLabel => andamentoEnum.label;

  /// Substitui a ordem de aplicação, inclusive com campos vazios.
  ///
  /// Grava o espelho em [recomendacoes]. Sem texto nos três campos, o legado
  /// também sai — senão a próxima leitura devolveria a ação antiga.
  Occurrence applyRecomendacaoOrdem({
    String? acao,
    String? dose,
    String? quando,
  }) {
    final ordem = OccurrenceRecomendacaoOrdem.resolve(
      acao: acao,
      dose: dose,
      quando: quando,
    );
    return copyWith(
      replaceRecomendacaoOrdem: true,
      recomendacaoAcao: ordem.acao,
      recomendacaoDose: ordem.dose,
      recomendacaoQuando: ordem.quando,
      recomendacoes: ordem.legacyText,
    );
  }

  Map<String, double>? getCoordinates() {
    if (_validCoordinates(lat, long)) {
      return {'lat': lat!, 'long': long!};
    }

    if (geometry != null) {
      try {
        final decoded = jsonDecode(geometry!);
        if (decoded['type'] == 'Point' && decoded['coordinates'] != null) {
          final coords = decoded['coordinates'] as List;
          if (coords.length >= 2) {
            final geometryLat = (coords[1] as num).toDouble();
            final geometryLong = (coords[0] as num).toDouble();
            if (_validCoordinates(geometryLat, geometryLong)) {
              return {'lat': geometryLat, 'long': geometryLong};
            }
          }
        }
      } catch (e) {
        AppLogger.debug(
          'Falha ao parsear geometry da ocorrência — $e',
          tag: 'Occurrence',
        );
      }
    }

    return null;
  }

  static bool _validCoordinates(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return latitude != 0 || longitude != 0;
  }
}
