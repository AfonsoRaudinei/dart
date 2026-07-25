import 'dart:io';
import 'dart:typed_data';
import '../../../../core/session/local_session_identity.dart';

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../domain/quick_photo_record.dart';

enum QuickPhotoType {
  normal('normal'),
  vegetalFilter('vegetal_filter');

  const QuickPhotoType(this.value);

  final String value;
}

class QuickPhotoRepository {
  static const _bucket = 'quick-photos';
  static const _table = 'quick_photos';

  /// sync_status: 0=synced, 1=pending, 2=deleted_local
  static const syncSynced = 0;
  static const syncPending = 1;
  static const syncDeleted = 2;

  final SupabaseClient _supabase;
  final Uuid _uuid;
  final DatabaseHelper _databaseHelper;

  QuickPhotoRepository({
    SupabaseClient? supabase,
    Uuid? uuid,
    DatabaseHelper? databaseHelper,
  }) : _supabase = supabase ?? Supabase.instance.client,
       _uuid = uuid ?? const Uuid(),
       _databaseHelper = databaseHelper ?? DatabaseHelper.instance;

  Future<QuickPhotoRecord> uploadAndInsert({
    required Uint8List bytes,
    required String localPath,
    double? lat,
    double? lng,
    String? visitSessionId,
    QuickPhotoType type = QuickPhotoType.normal,
  }) async {
    final userId = LocalSessionIdentity.resolveUserId();
    final id = _uuid.v4();
    final createdAt = DateTime.now().toUtc();

    await _insertLocal(
      id: id,
      userId: userId,
      localPath: localPath,
      lat: lat,
      lng: lng,
      visitSessionId: visitSessionId,
      type: type,
      createdAt: createdAt,
    );

    var syncStatus = 1;
    if (userId.isEmpty) {
      AppLogger.warning(
        'Foto rápida salva localmente sem usuário autenticado.',
        tag: 'QuickPhoto',
      );
    } else {
      final remoteSynced = await _tryUploadRemote(
        id: id,
        userId: userId,
        bytes: bytes,
        lat: lat,
        lng: lng,
        createdAt: createdAt,
        type: type,
        visitSessionId: visitSessionId,
      );
      syncStatus = remoteSynced ? 0 : 1;
    }

    AppLogger.debug(
      'Foto rápida salva localmente: $localPath',
      tag: 'QuickPhoto',
    );

    return QuickPhotoRecord(
      id: id,
      imagePath: localPath,
      latitude: lat,
      longitude: lng,
      createdAt: createdAt,
      visitSessionId: visitSessionId,
      type: type.value,
      syncStatus: syncStatus,
    );
  }

  Future<List<QuickPhotoRecord>> getByVisitSessionId(String sessionId) async {
    final db = await _databaseHelper.database;
    final userId = LocalSessionIdentity.resolveUserId();
    final rows = await db.query(
      _table,
      where: 'visit_session_id = ? AND user_id = ?',
      whereArgs: [sessionId, userId],
      orderBy: 'created_at ASC',
    );
    return rows.map(QuickPhotoRecord.fromMap).toList();
  }

  /// Lista fotos do usuário autenticado, mais recentes primeiro.
  /// Exclui soft-deleted (`sync_status = deleted_local`).
  Future<List<QuickPhotoRecord>> getRecentForCurrentUser({int limit = 100}) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return const [];

    final db = await _databaseHelper.database;
    final rows = await db.query(
      _table,
      where: 'user_id = ? AND sync_status != ?',
      whereArgs: [userId, syncDeleted],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return rows.map(QuickPhotoRecord.fromMap).toList();
  }

  /// Soft-delete: marca `deleted_local`, remove arquivo local se existir e
  /// tenta limpar remoto (best-effort). Nunca hard-delete sincronizável.
  Future<void> softDelete(String id) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty || id.isEmpty) return;

    final db = await _databaseHelper.database;
    final rows = await db.query(
      _table,
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final row = rows.first;
    final localPath = row['local_path'] as String?;
    final storagePath = row['storage_path'] as String?;

    if (localPath != null && localPath.isNotEmpty) {
      try {
        final file = File(localPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (error) {
        AppLogger.warning(
          'Falha ao apagar arquivo local da foto rápida.',
          tag: 'QuickPhoto',
          error: error,
        );
      }
    }

    await db.update(
      _table,
      {
        'sync_status': syncDeleted,
        'local_path': '',
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (storagePath != null && storagePath.isNotEmpty) {
      try {
        await _supabase.storage.from(_bucket).remove([storagePath]);
      } catch (error) {
        AppLogger.warning(
          'Foto marcada localmente como excluída; limpeza remota de storage pendente.',
          tag: 'QuickPhoto',
          error: error,
        );
      }
    }

    AppLogger.debug('Foto rápida soft-deleted: $id', tag: 'QuickPhoto');
  }

  /// Atualiza mídia existente in-place (reabrir editor de anotação).
  /// Sobrescreve o arquivo local, atualiza tipo e marca pending_sync.
  Future<QuickPhotoRecord> updateExisting({
    required String id,
    required Uint8List bytes,
    required String localPath,
    QuickPhotoType type = QuickPhotoType.normal,
  }) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty || id.isEmpty) {
      throw StateError('Usuário ou mídia inválidos para atualização.');
    }

    final db = await _databaseHelper.database;
    final rows = await db.query(
      _table,
      where: 'id = ? AND user_id = ? AND sync_status != ?',
      whereArgs: [id, userId, syncDeleted],
      limit: 1,
    );
    if (rows.isEmpty) {
      throw StateError('Mídia não encontrada para edição.');
    }

    final row = rows.first;
    final previousStorage = row['storage_path'] as String?;

    await File(localPath).writeAsBytes(bytes, flush: true);

    await db.update(
      _table,
      {
        'local_path': localPath,
        'photo_type': type.value,
        'sync_status': syncPending,
        'storage_path': null,
        'public_url': null,
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );

    if (previousStorage != null && previousStorage.isNotEmpty) {
      try {
        await _supabase.storage.from(_bucket).remove([previousStorage]);
      } catch (error) {
        AppLogger.warning(
          'Storage antigo da mídia editada não removido.',
          tag: 'QuickPhoto',
          error: error,
        );
      }
    }

    final remoteSynced = await _tryReuploadRemote(
      id: id,
      userId: userId,
      bytes: bytes,
      lat: (row['lat'] as num?)?.toDouble(),
      lng: (row['lng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      type: type,
      visitSessionId: row['visit_session_id'] as String?,
    );

    AppLogger.debug('Foto rápida atualizada in-place: $id', tag: 'QuickPhoto');

    return QuickPhotoRecord(
      id: id,
      imagePath: localPath,
      latitude: (row['lat'] as num?)?.toDouble(),
      longitude: (row['lng'] as num?)?.toDouble(),
      createdAt: DateTime.parse(row['created_at'] as String).toUtc(),
      visitSessionId: row['visit_session_id'] as String?,
      type: type.value,
      syncStatus: remoteSynced ? syncSynced : syncPending,
    );
  }

  static String typeLabel(String type) {
    switch (type) {
      case 'vegetal_filter':
        return 'Inversão vegetal';
      case 'normal':
      default:
        return 'Foto rápida';
    }
  }

  Future<void> _insertLocal({
    required String id,
    required String userId,
    required String localPath,
    required DateTime createdAt,
    required QuickPhotoType type,
    double? lat,
    double? lng,
    String? visitSessionId,
  }) async {
    final db = await _databaseHelper.database;
    await db.insert(_table, {
      'id': id,
      'user_id': userId,
      'visit_session_id': visitSessionId,
      'local_path': localPath,
      'storage_path': null,
      'public_url': null,
      'lat': lat,
      'lng': lng,
      'photo_type': type.value,
      'created_at': createdAt.toIso8601String(),
      'sync_status': 1,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<bool> _tryUploadRemote({
    required String id,
    required String userId,
    required Uint8List bytes,
    required DateTime createdAt,
    required QuickPhotoType type,
    double? lat,
    double? lng,
    String? visitSessionId,
  }) async {
    try {
      final storagePath = '$userId/$id.jpg';

      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage
          .from(_bucket)
          .getPublicUrl(storagePath);

      await _supabase.from(_table).insert({
        'id': id,
        'user_id': userId,
        'storage_path': storagePath,
        'public_url': publicUrl,
        'lat': lat,
        'lng': lng,
        'photo_type': type.value,
        'visit_session_id': visitSessionId,
        'created_at': createdAt.toIso8601String(),
      });

      final db = await _databaseHelper.database;
      await db.update(
        _table,
        {
          'storage_path': storagePath,
          'public_url': publicUrl,
          'sync_status': 0,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );

      AppLogger.debug('Foto rápida enviada: $storagePath', tag: 'QuickPhoto');
      return true;
    } catch (error) {
      AppLogger.warning(
        'Foto rápida salva localmente; envio remoto pendente.',
        tag: 'QuickPhoto',
        error: error,
      );
      return false;
    }
  }

  /// Reenvio após edição: storage com upsert + upsert na tabela remota.
  Future<bool> _tryReuploadRemote({
    required String id,
    required String userId,
    required Uint8List bytes,
    required DateTime createdAt,
    required QuickPhotoType type,
    double? lat,
    double? lng,
    String? visitSessionId,
  }) async {
    try {
      final storagePath = '$userId/$id.jpg';

      await _supabase.storage
          .from(_bucket)
          .uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _supabase.storage
          .from(_bucket)
          .getPublicUrl(storagePath);

      await _supabase.from(_table).upsert({
        'id': id,
        'user_id': userId,
        'storage_path': storagePath,
        'public_url': publicUrl,
        'lat': lat,
        'lng': lng,
        'photo_type': type.value,
        'visit_session_id': visitSessionId,
        'created_at': createdAt.toIso8601String(),
      });

      final db = await _databaseHelper.database;
      await db.update(
        _table,
        {
          'storage_path': storagePath,
          'public_url': publicUrl,
          'sync_status': syncSynced,
        },
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );

      AppLogger.debug(
        'Foto rápida reenviada após edição: $storagePath',
        tag: 'QuickPhoto',
      );
      return true;
    } catch (error) {
      AppLogger.warning(
        'Edição salva localmente; reenvio remoto pendente.',
        tag: 'QuickPhoto',
        error: error,
      );
      return false;
    }
  }
}
