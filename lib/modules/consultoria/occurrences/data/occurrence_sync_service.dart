import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:soloforte_app/core/contracts/i_occurrence_access_reader.dart';
import 'package:soloforte_app/core/domain/occurrence_recomendacao_ordem.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';
import 'package:soloforte_app/core/services/sync_retry_runner.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import '../../relatorio_visita/data/occurrence_audio_remote.dart';
import '../domain/occurrence.dart';
import '../domain/occurrence_andamento.dart';

class OccurrenceSyncService {
  OccurrenceSyncService(
    this._supabase,
    this._accessReader, {
    OccurrenceAudioRemote? audioRemote,
  }) : _injectedAudioRemote = audioRemote;

  final SupabaseClient _supabase;
  final IOccurrenceAccessReader _accessReader;
  final OccurrenceAudioRemote? _injectedAudioRemote;
  OccurrenceAudioRemote? _lazyAudioRemote;

  OccurrenceAudioRemote get _audioRemoteClient {
    final injected = _injectedAudioRemote;
    if (injected != null) return injected;
    return _lazyAudioRemote ??= OccurrenceAudioRemote(
      SupabaseOccurrenceAudioObjectStore(_supabase),
    );
  }

  Future<void> syncOccurrences() async {
    try {
      await _syncOccurrencesPush();
    } catch (error, stackTrace) {
      AppLogger.error(
        'OccurrenceSync push stage aborted',
        tag: 'OccurrenceSync',
        error: error,
        stackTrace: stackTrace,
      );
    }

    try {
      await _syncOccurrencesPull();
    } catch (error, stackTrace) {
      AppLogger.error(
        'OccurrenceSync pull stage aborted',
        tag: 'OccurrenceSync',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  Future<void> _syncOccurrencesPush() async {
    final db = await DatabaseHelper.instance.database;
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;

    final pending = await db.query(
      'occurrences',
      where:
          "user_id = ? AND cached_by_user_id IS NULL "
          "AND sync_status IN ('local', 'local_only', 'updated', "
          "'pending_sync', 'deleted', 'deleted_local')",
      whereArgs: [userId],
    );

    for (final row in pending) {
      final occurrence = Occurrence.fromMap(row);
      final remoteId = occurrence.remoteId?.trim() ?? '';
      final occurrenceId = remoteId.isNotEmpty ? remoteId : occurrence.id;
      final owner = occurrence.ownerUserId?.trim() ?? '';
      final allowUpsert = await shouldUpsertOccurrenceAfterAudio(
        audio: _audioRemoteClient,
        userId: owner.isNotEmpty ? owner : userId,
        occurrenceId: occurrenceId,
        syncStatus: occurrence.syncStatus,
        audioPath: occurrence.audioPath,
      );
      if (!allowUpsert) continue;
      try {
        final payload = OccurrenceRemoteMapper.toRemote(occurrence, userId);
        await SyncRetryRunner.execute(
          operation: () => _supabase.from('occurrences').upsert(payload),
          tag: 'OccurrenceSync',
          stage: 'occurrence_push_remote',
          entityId: occurrence.id,
        );
        try {
          await db.update(
            'occurrences',
            {'sync_status': 'synced'},
            where: 'id = ? AND user_id = ?',
            whereArgs: [occurrence.id, userId],
          );
          AppLogger.debug(
            'Occurrence push synced [id=${occurrence.id}]',
            tag: 'OccurrenceSync',
          );
        } catch (error, stackTrace) {
          AppLogger.error(
            'Occurrence push remoto concluido, mas persistencia local falhou '
            '[id=${occurrence.id}]',
            tag: 'OccurrenceSync',
            error: error,
            stackTrace: stackTrace,
          );
        }
      } catch (error) {
        AppLogger.warning(
          'Falha ao enviar ocorrencia ${occurrence.id}; pendencia local preservada: $error',
          tag: 'OccurrenceSync',
          error: error,
        );
      }
    }
  }

  Future<void> _syncOccurrencesPull() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning(
        'Skipping occurrence pull: userId is null',
        tag: 'OccurrenceSync',
      );
      return;
    }

    final activeClientIds = await _accessReader.loadActiveClientIds();
    final activeFieldIds = await _accessReader.loadActiveFieldIdsForOccurrences();
    final ownRows = await SyncRetryRunner.execute(
      operation: () => _supabase
          .from('occurrences')
          .select()
          .eq('user_id', userId)
          .order('updated_at'),
      stage: 'occurrence_pull_owned',
      tag: 'OccurrenceSync',
    );

    final sharedRows = activeClientIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await SyncRetryRunner.execute(
            operation: () => _supabase
                .from('occurrences')
                .select()
                .inFilter('client_id', activeClientIds.toList())
                .order('updated_at'),
            stage: 'occurrence_pull_shared',
            tag: 'OccurrenceSync',
          );

    final sharedByField = activeFieldIds.isEmpty
        ? const <Map<String, dynamic>>[]
        : await SyncRetryRunner.execute(
            operation: () => _supabase
                .from('occurrences')
                .select()
                .inFilter('field_id', activeFieldIds.toList())
                .order('updated_at'),
            stage: 'occurrence_pull_shared_fields',
            tag: 'OccurrenceSync',
          );

    final rowsById = <String, Map<String, dynamic>>{};
    for (final raw in [...ownRows, ...sharedRows, ...sharedByField]) {
      final row = Map<String, dynamic>.from(raw);
      rowsById[row['id'] as String] = row;
    }

    final db = await DatabaseHelper.instance.database;
    final audioDownloads =
        <({String userId, String occurrenceId, String audioPath})>[];
    await db.transaction((txn) async {
      await _removeRevokedCache(txn, userId, activeClientIds);
      for (final remote in rowsById.values) {
        try {
          final audio = await _cacheRemote(txn, remote, userId);
          if (audio != null) audioDownloads.add(audio);
        } catch (error, stackTrace) {
          AppLogger.error(
            'Occurrence pull persist failed [id=${remote['id']}]',
            tag: 'OccurrenceSync',
            error: error,
            stackTrace: stackTrace,
          );
        }
      }
    });
    for (final audio in audioDownloads) {
      await _audioRemoteClient.downloadIfMissing(
        userId: audio.userId,
        occurrenceId: audio.occurrenceId,
        audioPath: audio.audioPath,
      );
    }
    AppLogger.debug(
      'Occurrence pull applied ${rowsById.length} row(s)',
      tag: 'OccurrenceSync',
    );
  }

  Future<({String userId, String occurrenceId, String audioPath})?>
  _cacheRemote(
    DatabaseExecutor db,
    Map<String, dynamic> remote,
    String currentUserId,
  ) async {
    final ownerUserId = remote['user_id'] as String;
    final isOwned = ownerUserId == currentUserId;
    final remoteId = remote['id'] as String;
    final localId = isOwned ? remoteId : '${remoteId}_cache_$currentUserId';

    if (!isOwned) {
      await _removeLegacySharedCache(db, remoteId, currentUserId);
    }

    if (remote['deleted_at'] != null) {
      await db.update(
        'occurrences',
        {
          'sync_status': SyncStatusContract.deletedLocal,
          'deleted_at': remote['deleted_at'],
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [localId],
      );
      return null;
    }

    if (isOwned) {
      final existing = await db.query(
        'occurrences',
        columns: ['sync_status', 'updated_at'],
        where: 'id = ?',
        whereArgs: [localId],
        limit: 1,
      );
      if (existing.isNotEmpty &&
          !OccurrenceCachePolicy.shouldReplaceOwnedLocal(
            existing.single,
            remote,
          )) {
        AppLogger.warning(
          'Occurrence pull conflict avoided for owned local '
          '[id=$localId sync_status=${existing.single['sync_status']}]',
          tag: 'OccurrenceSync',
        );
        return null;
      }
    }

    final localData = OccurrenceRemoteMapper.fromRemote(
      remote,
      localId: localId,
      cachedByUserId: isOwned ? null : currentUserId,
    );
    await OccurrenceCachePolicy.writePulledRow(db, localData);
    return _audioPullAfterWrite(remote, localData);
  }

  /// Só depois da linha gravada. userId é o dono (`remote.user_id`).
  ({String userId, String occurrenceId, String audioPath})?
  _audioPullAfterWrite(
    Map<String, dynamic> remote,
    Map<String, dynamic> localData,
  ) {
    final audioPath = (localData['audio_path'] as String?)?.trim() ?? '';
    if (audioPath.isEmpty) return null;
    final owner = (remote['user_id'] as String?)?.trim() ?? '';
    final occurrenceId = (remote['id'] as String?)?.trim() ?? '';
    if (owner.isEmpty || occurrenceId.isEmpty) return null;
    return (userId: owner, occurrenceId: occurrenceId, audioPath: audioPath);
  }

  Future<void> _removeLegacySharedCache(
    DatabaseExecutor db,
    String remoteId,
    String currentUserId,
  ) async {
    await db.delete(
      'occurrences',
      where:
          'id = ? AND user_id = ? AND cached_by_user_id IS NULL '
          "AND sync_status = 'synced'",
      whereArgs: [remoteId, currentUserId],
    );
  }

  Future<void> _removeRevokedCache(
    DatabaseExecutor db,
    String userId,
    Set<String> activeClientIds,
  ) async {
    final cached = await db.query(
      'occurrences',
      columns: ['id', 'client_id'],
      where: 'cached_by_user_id = ?',
      whereArgs: [userId],
    );
    final revokedIds = OccurrenceCachePolicy.revokedLocalIds(
      cached,
      activeClientIds,
    );
    for (final id in revokedIds) {
      await db.update(
        'occurrences',
        {
          'sync_status': SyncStatusContract.deletedLocal,
          'deleted_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
  }
}

/// `true` quando o upsert da linha pode seguir.
/// Upload que lança devolve `false`: a pendência local permanece.
Future<bool> shouldUpsertOccurrenceAfterAudio({
  required OccurrenceAudioRemote audio,
  required String userId,
  required String occurrenceId,
  required String syncStatus,
  String? audioPath,
}) async {
  if (syncStatus == 'deleted' ||
      syncStatus == SyncStatusContract.deletedLocal) {
    await audio.removeObject(userId: userId, occurrenceId: occurrenceId);
    return true;
  }
  final stored = audioPath?.trim() ?? '';
  if (stored.isEmpty) return true;
  try {
    await audio.uploadIfLocal(
      userId: userId,
      occurrenceId: occurrenceId,
      audioPath: stored,
    );
    return true;
  } catch (error) {
    AppLogger.warning(
      'Falha ao enviar áudio da ocorrência $occurrenceId; upsert adiado',
      tag: 'OccurrenceSync',
      error: error,
    );
    return false;
  }
}

class OccurrenceCachePolicy {
  const OccurrenceCachePolicy._();

  static List<String> revokedLocalIds(
    Iterable<Map<String, Object?>> cachedRows,
    Set<String> activeClientIds,
  ) {
    return cachedRows
        .where((row) {
          final clientId = row['client_id'] as String?;
          return clientId == null || !activeClientIds.contains(clientId);
        })
        .map((row) => row['id'] as String)
        .toList(growable: false);
  }

  static bool shouldReplaceOwnedLocal(
    Map<String, Object?> local,
    Map<String, dynamic> remote,
  ) {
    const pendingStatuses = {
      'local',
      'local_only',
      'updated',
      'pending_sync',
      'deleted',
      'deleted_local',
    };
    if (pendingStatuses.contains(local['sync_status'])) return false;

    final localUpdatedAt = DateTime.tryParse(
      local['updated_at']?.toString() ?? '',
    );
    final remoteUpdatedAt = DateTime.tryParse(
      remote['updated_at']?.toString() ?? '',
    );
    if (localUpdatedAt == null || remoteUpdatedAt == null) return true;
    return remoteUpdatedAt.isAfter(localUpdatedAt);
  }

  /// `field_id` é só local (v49) e não vem do Supabase: o replace do pull
  /// mantém o valor já gravado em vez de zerá-lo.
  static Future<void> writePulledRow(
    DatabaseExecutor db,
    Map<String, dynamic> localData,
  ) async {
    final preservedFieldId = await _localFieldId(db, localData['id'] as String);
    final row = preservedFieldId == null
        ? localData
        : {...localData, 'field_id': preservedFieldId};
    await db.insert(
      'occurrences',
      row,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<String?> _localFieldId(
    DatabaseExecutor db,
    String localId,
  ) async {
    if (!await DatabaseSchemaUtils.columnExists(
      db,
      'occurrences',
      'field_id',
    )) {
      return null;
    }
    final prior = await db.query(
      'occurrences',
      columns: ['field_id'],
      where: 'id = ?',
      whereArgs: [localId],
      limit: 1,
    );
    if (prior.isEmpty) return null;
    final value = prior.single['field_id']?.toString().trim() ?? '';
    return value.isEmpty ? null : value;
  }
}

class OccurrenceRemoteMapper {
  const OccurrenceRemoteMapper._();

  static Map<String, dynamic> toRemote(
    Occurrence occurrence,
    String ownerUserId,
  ) {
    final coordinates = resolveCoordinates(
      latitude: occurrence.lat,
      longitude: occurrence.long,
      geometry: occurrence.geometry,
    );
    final isDeleted =
        occurrence.syncStatus == 'deleted_local' ||
        occurrence.syncStatus == 'deleted';
    return {
      'id': occurrence.remoteId ?? occurrence.id,
      'user_id': ownerUserId,
      'visit_session_id': occurrence.visitSessionId,
      'client_id': occurrence.clientId,
      'type': occurrence.type,
      'description': occurrence.description,
      'photo_path': occurrence.photoPath,
      'latitude': coordinates?.latitude,
      'longitude': coordinates?.longitude,
      'lat': coordinates?.latitude,
      'long': coordinates?.longitude,
      'geometry': coordinates?.geometry,
      'updated_at': occurrence.updatedAt.toUtc().toIso8601String(),
      'category': occurrence.category,
      'status': occurrence.status,
      'cultivar': occurrence.cultivar,
      'data_plantio': occurrence.dataPlantio,
      'estadio_fenologico': occurrence.estadioFenologico,
      'tipo_ocorrencia': occurrence.tipoOcorrencia,
      'amostra_solo': occurrence.amostraSolo,
      'recomendacoes': OccurrenceRecomendacaoOrdem.mirrorLegacy(
        acao: occurrence.recomendacaoAcao,
        dose: occurrence.recomendacaoDose,
        quando: occurrence.recomendacaoQuando,
        legacy: occurrence.recomendacoes,
      ),
      'recomendacao_acao': occurrence.recomendacaoAcao,
      'recomendacao_dose': occurrence.recomendacaoDose,
      'recomendacao_quando': occurrence.recomendacaoQuando,
      'metricas_json': _decodeJson(occurrence.metricasJson),
      'nutrientes_json': _decodeJson(occurrence.nutrientesJson),
      'categorias_json': _decodeJson(occurrence.categoriasJson),
      'notas_categorias_json': _decodeJson(occurrence.notasCategoriasJson),
      'fotos_categorias_json': _decodeJson(occurrence.fotosCategoriasJson),
      'data_emergencia': occurrence.dataEmergencia,
      'sementes_por_metro': occurrence.sementesPorMetro,
      'estande_plantas': occurrence.estandePlantas,
      'avaliacao_plantio': occurrence.avaliacaoPlantio,
      'objetivo_plantio': occurrence.objetivoPlantio,
      'data_fim_plantio': occurrence.dataFimPlantio,
      'ciclo_dias': occurrence.cicloDias,
      'cultura': occurrence.cultura,
      'safra': occurrence.safra,
      'andamento':
          occurrence.andamento ?? OccurrenceAndamento.aberta.storageValue,
      'responsavel_nome': occurrence.responsavelNome,
      'audio_path': occurrence.audioPath,
      'audio_duration_sec': occurrence.audioDurationSec,
      'amostra_codigo': occurrence.amostraCodigo,
      'amostra_coletor': occurrence.amostraColetor,
      'amostra_tramite': occurrence.amostraTramite,
      'amostra_laudo_texto': occurrence.amostraLaudoTexto,
      'amostra_analises_json': _decodeJson(occurrence.amostraAnalisesJson),
      'external_source': occurrence.externalSource,
      'external_analysis_id': occurrence.externalAnalysisId,
      'analysis_payload': _decodeJson(occurrence.analysisPayloadJson),
      'deleted_at': isDeleted ? DateTime.now().toUtc().toIso8601String() : null,
    };
  }

  static Map<String, dynamic> fromRemote(
    Map<String, dynamic> remote, {
    required String localId,
    required String? cachedByUserId,
  }) {
    final geometry = _geometryJson(remote['geometry']);
    final coordinates = resolveCoordinates(
      latitude: _asDouble(_first(remote, ['latitude', 'lat'])),
      longitude: _asDouble(_first(remote, ['longitude', 'long'])),
      geometry: geometry,
    );
    return {
      'id': localId,
      'remote_id': remote['id'],
      'user_id': remote['user_id'],
      'cached_by_user_id': cachedByUserId,
      'visit_session_id': remote['visit_session_id'],
      'client_id': remote['client_id'],
      'type': remote['type'] ?? 'Info',
      'description': remote['description'] ?? '',
      'photo_path': remote['photo_path'],
      'lat': coordinates?.latitude,
      'long': coordinates?.longitude,
      'geometry': geometry,
      'created_at': remote['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': remote['updated_at'] ?? DateTime.now().toIso8601String(),
      'sync_status': 'synced',
      'category': remote['category'],
      'status': remote['status'] ?? 'confirmed',
      'cultivar': remote['cultivar'],
      'data_plantio': remote['data_plantio'],
      'estadio_fenologico': remote['estadio_fenologico'],
      'tipo_ocorrencia': remote['tipo_ocorrencia'],
      'amostra_solo': _asSqliteBool(remote['amostra_solo']),
      'recomendacoes': remote['recomendacoes'],
      'recomendacao_acao': remote['recomendacao_acao'],
      'recomendacao_dose': remote['recomendacao_dose'],
      'recomendacao_quando': remote['recomendacao_quando'],
      'metricas_json': _encodeJson(remote['metricas_json']),
      'nutrientes_json': _encodeJson(remote['nutrientes_json']),
      'categorias_json': _encodeJson(remote['categorias_json']),
      'notas_categorias_json': _encodeJson(remote['notas_categorias_json']),
      'fotos_categorias_json': _encodeJson(remote['fotos_categorias_json']),
      'data_emergencia': remote['data_emergencia'] as String?,
      'sementes_por_metro': (remote['sementes_por_metro'] as num?)?.toDouble(),
      'estande_plantas': (remote['estande_plantas'] as num?)?.toInt(),
      'avaliacao_plantio': remote['avaliacao_plantio'] as String?,
      'objetivo_plantio': remote['objetivo_plantio'] as String?,
      'data_fim_plantio': remote['data_fim_plantio'] as String?,
      'ciclo_dias': (remote['ciclo_dias'] as num?)?.toInt(),
      'cultura': remote['cultura'] as String?,
      'safra': remote['safra'] as String?,
      'andamento':
          remote['andamento'] as String? ??
          OccurrenceAndamento.aberta.storageValue,
      'responsavel_nome': remote['responsavel_nome'] as String?,
      'audio_path': remote['audio_path'] as String?,
      'audio_duration_sec': (remote['audio_duration_sec'] as num?)?.toInt(),
      'amostra_codigo': remote['amostra_codigo'] as String?,
      'amostra_coletor': remote['amostra_coletor'] as String?,
      'amostra_tramite': remote['amostra_tramite'] as String?,
      'amostra_laudo_texto': remote['amostra_laudo_texto'] as String?,
      'amostra_analises_json': _encodeJson(remote['amostra_analises_json']),
      'external_source': remote['external_source'],
      'external_analysis_id': remote['external_analysis_id'],
      'analysis_payload_json': _encodeJson(remote['analysis_payload']),
      'deleted_at': remote['deleted_at'],
    };
  }

  static OccurrenceCoordinates? resolveCoordinates({
    required double? latitude,
    required double? longitude,
    required String? geometry,
  }) {
    if (_valid(latitude, longitude)) {
      return OccurrenceCoordinates(latitude: latitude!, longitude: longitude!);
    }
    if (geometry == null || geometry.isEmpty) return null;
    try {
      final decoded = jsonDecode(geometry);
      final coordinates = decoded is Map && decoded['type'] == 'Point'
          ? decoded['coordinates']
          : null;
      if (coordinates is! List || coordinates.length < 2) return null;
      final fallbackLongitude = _asDouble(coordinates[0]);
      final fallbackLatitude = _asDouble(coordinates[1]);
      if (!_valid(fallbackLatitude, fallbackLongitude)) return null;
      return OccurrenceCoordinates(
        latitude: fallbackLatitude!,
        longitude: fallbackLongitude!,
      );
    } catch (_) {
      return null;
    }
  }

  static bool _valid(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) return false;
    if (!latitude.isFinite || !longitude.isFinite) return false;
    if (latitude < -90 || latitude > 90) return false;
    if (longitude < -180 || longitude > 180) return false;
    return latitude != 0 || longitude != 0;
  }

  static Object? _decodeJson(String? value) {
    if (value == null || value.isEmpty) return null;
    try {
      return jsonDecode(value);
    } catch (_) {
      return value;
    }
  }

  static String? _encodeJson(Object? value) {
    if (value == null) return null;
    return value is String ? value : jsonEncode(value);
  }

  static String? _geometryJson(Object? value) {
    if (value == null) return null;
    return value is String ? value : jsonEncode(value);
  }

  static Object? _first(Map<String, dynamic> row, List<String> keys) {
    for (final key in keys) {
      final value = row[key];
      if (value != null) return value;
    }
    return null;
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int _asSqliteBool(Object? value) {
    return value == true || value == 1 ? 1 : 0;
  }
}

class OccurrenceCoordinates {
  OccurrenceCoordinates({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  Map<String, dynamic> get geometry => {
    'type': 'Point',
    'coordinates': [longitude, latitude],
  };
}
