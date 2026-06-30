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
import '../../../../core/session/profile_role_resolver.dart';
import '../../../../core/session/user_role.dart';
import '../../domain/entities/user_profile.dart';
import '../../domain/repositories/i_user_profile_repository.dart';
import '../models/user_profile_audit_entry.dart';
import '../models/user_profile_remote_patch.dart';

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
      AppLogger.warning(
        'Falha ao buscar perfis remotamente',
        tag: _tag,
        error: e,
      );
    }

    // 3. Decidir qual dado prevalece
    final creaNumber = authUser.userMetadata?['crea_number']?.toString();
    final metadataRole = authUser.userMetadata?['role'] as String?;

    if (cached != null) {
      final cachedUpdatedAt =
          DateTime.tryParse((cached['updated_at'] as String?) ?? '')?.toUtc() ??
          DateTime.fromMillisecondsSinceEpoch(0);

      final remoteUpdatedAt = remoteProfile != null
          ? DateTime.tryParse(
                  (remoteProfile['updated_at'] as String?) ?? '',
                )?.toUtc() ??
                DateTime.fromMillisecondsSinceEpoch(0)
          : DateTime.fromMillisecondsSinceEpoch(0);

      // Cache local prevalece se mais recente (sync pendente)
      if (cachedUpdatedAt.isAfter(remoteUpdatedAt)) {
        final cachedProfile = UserProfile.fromCache(cached);
        final resolvedRole = ProfileRoleResolver.resolve(
          metadataRole: metadataRole,
          profileRole: cachedProfile.role,
        );
        if ((cachedProfile.role ?? '').toUserRole().value != resolvedRole) {
          await db.update(
            'user_profile_cache',
            {'role': resolvedRole},
            where: 'id = ?',
            whereArgs: [authUser.id],
          );
          return _withRole(cachedProfile, resolvedRole);
        }
        return cachedProfile;
      }
    }

    final resolvedRole = ProfileRoleResolver.resolve(
      metadataRole: metadataRole,
      profileRole: remoteProfile?['role'] as String?,
    );

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
      role: resolvedRole,
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

      final remotePatch = UserProfileRemotePatch.fromUpdate(
        updated: updated,
        changedFields: changedFields,
        updatedAt: now,
      );

      if (remotePatch.hasProfileChanges) {
        await client
            .from('perfis')
            .update(remotePatch.profileFields)
            .eq('id', updated.id);
      }

      if (remotePatch.hasUserMetadataChanges) {
        await client.auth.updateUser(
          UserAttributes(data: remotePatch.userMetadata),
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

  Future<Map<String, dynamic>?> _readCache(Database db, String userId) async {
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

  UserProfile _withRole(UserProfile profile, String role) {
    return UserProfile(
      id: profile.id,
      email: profile.email,
      fullName: profile.fullName,
      phone: profile.phone,
      role: role,
      photoUrl: profile.photoUrl,
      creaNumber: profile.creaNumber,
      createdAt: profile.createdAt,
      updatedAt: profile.updatedAt,
    );
  }
}
