import 'dart:typed_data';

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
    final userId = _supabase.auth.currentUser?.id;
    final id = _uuid.v4();
    final createdAt = DateTime.now().toUtc();

    await _insertLocal(
      id: id,
      userId: userId ?? '',
      localPath: localPath,
      lat: lat,
      lng: lng,
      visitSessionId: visitSessionId,
      type: type,
      createdAt: createdAt,
    );

    var syncStatus = 1;
    if (userId == null || userId.isEmpty) {
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
    final userId = _supabase.auth.currentUser?.id ?? '';
    final rows = await db.query(
      _table,
      where: 'visit_session_id = ? AND user_id = ?',
      whereArgs: [sessionId, userId],
      orderBy: 'created_at ASC',
    );
    return rows.map(QuickPhotoRecord.fromMap).toList();
  }

  /// Lista fotos do usuário autenticado, mais recentes primeiro.
  Future<List<QuickPhotoRecord>> getRecentForCurrentUser({int limit = 100}) async {
    final userId = _supabase.auth.currentUser?.id ?? '';
    if (userId.isEmpty) return const [];

    final db = await _databaseHelper.database;
    final rows = await db.query(
      _table,
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'created_at DESC',
      limit: limit,
    );

    return rows
        .map(QuickPhotoRecord.fromMap)
        .where((photo) => photo.imagePath?.isNotEmpty == true)
        .toList();
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
}
