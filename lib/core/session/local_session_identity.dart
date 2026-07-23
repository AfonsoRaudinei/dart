import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../infra/preferences_service.dart';

class LocalSessionIdentity {
  const LocalSessionIdentity._();

  static const _lastKnownUserIdKey = 'session_last_known_user_id_v1';

  static PreferencesService? _preferences;
  static String? _ephemeralLastKnownUserId;
  static bool _sessionKnownPublic = false;

  static void configure(PreferencesService preferences) {
    _preferences = preferences;
  }

  static String resolveUserId({bool allowLastKnown = true}) {
    final currentUserId = _currentSupabaseUserId();
    if (currentUserId.isNotEmpty) {
      remember(currentUserId);
      return currentUserId;
    }

    if (!allowLastKnown || _sessionKnownPublic) return '';
    return _readLastKnownUserId();
  }

  static String _currentSupabaseUserId() {
    try {
      return Supabase.instance.client.auth.currentUser?.id.trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  static void remember(String? userId) {
    final normalized = userId?.trim() ?? '';
    if (normalized.isEmpty) return;

    _sessionKnownPublic = false;
    _ephemeralLastKnownUserId = normalized;
    final preferences = _preferences;
    if (preferences != null) {
      unawaited(preferences.setString(_lastKnownUserIdKey, normalized));
    }
  }

  static void markSessionPublic() {
    _sessionKnownPublic = true;
  }

  static void clear() {
    _sessionKnownPublic = true;
    _ephemeralLastKnownUserId = '';
    final preferences = _preferences;
    if (preferences != null) {
      unawaited(preferences.remove(_lastKnownUserIdKey));
    }
  }

  @visibleForTesting
  static void resetForTesting() {
    _preferences = null;
    _ephemeralLastKnownUserId = null;
    _sessionKnownPublic = false;
  }

  static String _readLastKnownUserId() {
    final persisted =
        _preferences?.getString(_lastKnownUserIdKey)?.trim() ?? '';
    if (persisted.isNotEmpty) return persisted;
    return _ephemeralLastKnownUserId?.trim() ?? '';
  }
}
