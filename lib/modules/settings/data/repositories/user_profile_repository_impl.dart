// ADR-032 — settings/data/repositories/user_profile_repository_impl.dart
//
// Implementação offline-first do repositório de perfil.
// Fonte da verdade: Supabase Auth + tabela `perfis` (remoto) + user_profile_cache (local)
//
// Regras:
// - cache local com sync_status=1 prevalece sobre dados remotos
// - creaNumber vai apenas em userMetadata (sem ALTER em tabela `perfis`)
// - auditoria é gerada mesmo offline (append-only)

import 'package:sqflite/sqflite.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_user_profile_repository.dart';
import '../models/user_profile_audit_entry.dart';

class UserProfileRepositoryImpl implements IUserProfileRepository {
  static const _tag = 'UserProfileRepo';

  @override
  Future<UserProfile?> getCurrentProfile() async {
    final client = Supabase.instance.client;
    final authUser = client.auth.currentUser;
    if (authUser == null) return null;

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toUtc();

    // 1. Ler cache local
    final cached = await _readCache(db, authUser.id);

    // 2. Tentar buscar dados remotos (tabela `perfis`)
    Map<String, dynamic>? remoteProfile;
    try {
      remoteProfile = await client
          .from('perfis')
          .select('name, phone, role, photo_url, updated_at')
          .eq('id', authUser.id)
          .maybeSingle();
    } catch (e) {
      AppLogger.warning('Falha ao buscar perfis remotamente', tag: _tag, error: e);
    }

    // 3. Decidir qual dado prevalece
    final creaNumber =
        authUser.userMetadata?['crea_number']?.toString();

    if (cached != null) {
      final cachedUpdatedAt = DateTime.tryParse(
            (cached['updated_at'] as String?) ?? '',
          )?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final remoteUpdatedAt = remoteProfile != null
          ? DateTime.tryParse(
                (remoteProfile['updated_at'] as String?) ?? '',
              )?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);

      // Cache local prevalece se mais recente (sync pendente)
      if (cachedUpdatedAt.isAfter(remoteUpdatedAt)) {
        return UserProfile.fromCache(cached);
      }
    }

    // 4. Usar dados remotos + sobrescrever cache
    final profile = UserProfile(
      id: authUser.id,
      email: authUser.email ?? '',
      fullName: (remoteProfile?['name'] as String?)?.trim().isNotEmpty == true
          ? (remoteProfile!['name'] as String).trim()
          : (authUser.userMetadata?['full_name'] as String?)?.trim(),
      phone: (remoteProfile?['phone'] as String?)?.trim().isNotEmpty == true
          ? (remoteProfile!['phone'] as String).trim()
          : (authUser.userMetadata?['phone'] as String?)?.trim(),
      role: (remoteProfile?['role'] as String?)?.trim(),
      photoUrl: (remoteProfile?['photo_url'] as String?)?.trim(),
      creaNumber: creaNumber?.trim().isNotEmpty == true ? creaNumber : null,
      createdAt: authUser.createdAt.isNotEmpty
          ? DateTime.tryParse(authUser.createdAt)?.toLocal() ?? now.toLocal()
          : now.toLocal(),
      updatedAt: now.toLocal(),
    );

    await _upsertCache(db, profile, syncStatus: 0);
    return profile;
  }

  @override
  Future<void> updateProfile({
    required UserProfile updated,
    required Map<String, String?> changedFields,
  }) async {
    if (changedFields.isEmpty) return;

    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().toUtc();
    final updatedWithTimestamp = updated.copyWith(updatedAt: now.toLocal());

    // 1. Persistir no cache local com sync_status=1 (offline-first)
    await _upsertCache(db, updatedWithTimestamp, syncStatus: 1);

    // 2. Gerar auditoria — 1 entrada por campo alterado
    for (final entry in changedFields.entries) {
      final auditEntry = UserProfileAuditEntry.create(
        userId: updated.id,
        fieldChanged: entry.key,
        oldValue: entry.value,
        newValue: _fieldValue(updated, entry.key) ?? '',
      );
      await db.insert('user_profile_edits', auditEntry.toMap());
    }

    // 3. Tentar sincronizar com Supabase
    try {
      final client = Supabase.instance.client;

      // Atualizar tabela `perfis` com campos que existem lá
      final perfisUpdate = <String, dynamic>{
        'updated_at': now.toIso8601String(),
      };
      if (changedFields.containsKey('fullName')) {
        perfisUpdate['name'] = updated.fullName ?? '';
      }
      if (changedFields.containsKey('phone')) {
        perfisUpdate['phone'] = updated.phone ?? '';
      }
      if (changedFields.containsKey('photoUrl')) {
        perfisUpdate['photo_url'] = updated.photoUrl ?? '';
      }
      if (perfisUpdate.length > 1) {
        await client.from('perfis').update(perfisUpdate).eq('id', updated.id);
      }

      // creaNumber vai apenas em userMetadata
      if (changedFields.containsKey('creaNumber') &&
          updated.creaNumber != null) {
        await client.auth.updateUser(
          UserAttributes(data: {'crea_number': updated.creaNumber}),
        );
      }

      // Marcar cache como sincronizado
      await db.update(
        'user_profile_cache',
        {'sync_status': 0},
        where: 'id = ?',
        whereArgs: [updated.id],
      );
    } catch (e) {
      // Offline ou erro — sync_status=1 permanece para sincronização posterior
      AppLogger.warning(
        'Perfil salvo localmente. Sync pendente.',
        tag: _tag,
        error: e,
      );
    }
  }

  @override
  Future<List<UserProfileAuditEntry>> getAuditTrail({int limit = 20}) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return [];

    final db = await DatabaseHelper.instance.database;
    final maps = await db.query(
      'user_profile_edits',
      where: 'user_id = ?',
      whereArgs: [authUser.id],
      orderBy: 'changed_at DESC',
      limit: limit,
    );
    return maps.map(UserProfileAuditEntry.fromMap).toList();
  }

  // ─── Helpers ───────────────────────────────────────────────

  Future<Map<String, dynamic>?> _readCache(
    Database db,
    String userId,
  ) async {
    final rows = await db.query(
      'user_profile_cache',
      where: 'id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  Future<void> _upsertCache(
    Database db,
    UserProfile profile, {
    required int syncStatus,
  }) async {
    final map = profile.toCache();
    map['sync_status'] = syncStatus;
    await db.insert(
      'user_profile_cache',
      map,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  String? _fieldValue(UserProfile profile, String fieldName) {
    switch (fieldName) {
      case 'fullName':
        return profile.fullName;
      case 'phone':
        return profile.phone;
      case 'photoUrl':
        return profile.photoUrl;
      case 'creaNumber':
        return profile.creaNumber;
      default:
        return null;
    }
  }
}
