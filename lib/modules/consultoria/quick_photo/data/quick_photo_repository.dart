import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/app_logger.dart';
import '../domain/quick_photo_record.dart';

class QuickPhotoRepository {
  static const _bucket = 'quick-photos';
  static const _table = 'quick_photos';

  final SupabaseClient _supabase;
  final Uuid _uuid;

  QuickPhotoRepository({SupabaseClient? supabase, Uuid? uuid})
    : _supabase = supabase ?? Supabase.instance.client,
      _uuid = uuid ?? const Uuid();

  Future<QuickPhotoRecord> uploadAndInsert({
    required Uint8List bytes,
    required String localPath,
    double? lat,
    double? lng,
  }) async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      throw StateError('Usuário não autenticado.');
    }

    final id = _uuid.v4();
    final storagePath = '$userId/$id.jpg';
    final createdAt = DateTime.now().toUtc();

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

    final publicUrl = _supabase.storage.from(_bucket).getPublicUrl(storagePath);

    await _supabase.from(_table).insert({
      'id': id,
      'user_id': userId,
      'storage_path': storagePath,
      'public_url': publicUrl,
      'lat': lat,
      'lng': lng,
      'created_at': createdAt.toIso8601String(),
    });

    AppLogger.debug('Foto rápida enviada: $storagePath', tag: 'QuickPhoto');

    return QuickPhotoRecord(
      id: id,
      imagePath: localPath,
      latitude: lat,
      longitude: lng,
      createdAt: createdAt,
    );
  }
}
