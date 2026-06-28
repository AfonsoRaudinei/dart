import 'dart:convert';

import '../infra/preferences_service.dart';
import 'user_role.dart';

class PendingSignupRoleStore {
  PendingSignupRoleStore(this._preferences);

  static const _keyPrefix = 'auth.pending_signup_role.';
  static const _ttl = Duration(hours: 24);

  final PreferencesService _preferences;

  Future<void> save({required String email, required String role}) async {
    final normalizedEmail = _normalizeEmail(email);
    final normalizedRole = role.toUserRole();
    if (normalizedEmail.isEmpty || normalizedRole.isUnknown) return;

    await _preferences.setString(
      _keyFor(normalizedEmail),
      jsonEncode({
        'role': normalizedRole.value,
        'created_at': DateTime.now().toUtc().toIso8601String(),
      }),
    );
  }

  Future<String?> readValidRole(String? email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) return null;

    final key = _keyFor(normalizedEmail);
    final raw = _preferences.getString(key);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        await _preferences.remove(key);
        return null;
      }

      final role = (decoded['role'] as String?).toUserRole();
      final createdAtRaw = decoded['created_at'] as String?;
      final createdAt = createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw)?.toUtc();
      final isExpired =
          createdAt == null ||
          DateTime.now().toUtc().difference(createdAt) > _ttl;

      if (role.isUnknown || isExpired) {
        await _preferences.remove(key);
        return null;
      }

      return role.value;
    } catch (_) {
      await _preferences.remove(key);
      return null;
    }
  }

  Future<void> clear(String? email) async {
    final normalizedEmail = _normalizeEmail(email);
    if (normalizedEmail.isEmpty) return;
    await _preferences.remove(_keyFor(normalizedEmail));
  }

  static String _normalizeEmail(String? email) =>
      (email ?? '').trim().toLowerCase();

  static String _keyFor(String email) => '$_keyPrefix$email';
}
