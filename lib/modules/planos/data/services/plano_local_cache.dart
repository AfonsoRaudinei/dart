import 'dart:convert';

import '../../../../core/infra/preferences_service.dart';
import '../../domain/entities/user_plan.dart';

/// Cache de leitura do último [UserPlan] verificado online.
///
/// ADR-012 Adendo 1: PreferencesService (não SQLite / não `database_helper`).
/// Fonte da verdade continua sendo o Supabase; este cache só cobre offline
/// ou timeout dentro de [ttl] (24h por padrão).
class PlanoLocalCache {
  PlanoLocalCache(
    this._prefs, {
    DateTime Function()? now,
    this.ttl = const Duration(hours: 24),
  }) : _now = now ?? DateTime.now;

  static const _keyPrefix = 'plano_cache_v1_';

  final PreferencesService _prefs;
  final DateTime Function() _now;

  /// TTL configurável (produção = 24h; testes injetam valor menor se quiserem).
  final Duration ttl;

  Future<void> save(UserPlan plan) async {
    final userId = plan.userId;
    if (userId.isEmpty) return;
    await _prefs.setString(_jsonKey(userId), jsonEncode(plan.toJson()));
    await _prefs.setInt(
      _verifiedAtKey(userId),
      _now().millisecondsSinceEpoch,
    );
  }

  /// Plano ainda dentro do TTL, ou `null` se ausente / expirado / JSON corrompido.
  UserPlan? readValid(String userId) {
    if (userId.isEmpty) return null;
    if (isExpired(userId)) return null;
    return _decode(userId);
  }

  /// `true` somente quando existe registro de verificação e o TTL já passou.
  bool isExpired(String userId) {
    if (userId.isEmpty) return false;
    final verifiedAt = _prefs.getInt(_verifiedAtKey(userId));
    if (verifiedAt == null) return false;
    final verified = DateTime.fromMillisecondsSinceEpoch(verifiedAt);
    return _now().difference(verified) >= ttl;
  }

  Future<void> clear(String userId) async {
    if (userId.isEmpty) return;
    await _prefs.remove(_jsonKey(userId));
    await _prefs.remove(_verifiedAtKey(userId));
  }

  String _jsonKey(String userId) => '$_keyPrefix$userId';

  String _verifiedAtKey(String userId) => '$_keyPrefix${userId}_verified_at';

  UserPlan? _decode(String userId) {
    final raw = _prefs.getString(_jsonKey(userId));
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      return UserPlan.fromJson(Map<String, dynamic>.from(decoded));
    } catch (_) {
      return null;
    }
  }
}
