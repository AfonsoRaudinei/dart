import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_storage.g.dart';

@Riverpod(keepAlive: true)
SessionStorage sessionStorage(Ref ref) {
  throw UnimplementedError(
    'SessionStorage must be overridden in ProviderScope',
  );
}

class SessionStorage {
  static const _keyToken = 'session_token';
  static const _legacyPrefsKey = 'session_token';

  final FlutterSecureStorage _secureStorage;
  String? _cachedToken;
  bool _initialized = false;

  SessionStorage(this._secureStorage);

  bool get isInitialized => _initialized;

  Future<void> init({SharedPreferences? legacyPrefs}) async {
    if (_initialized) return;

    _cachedToken = await _secureStorage.read(key: _keyToken);

    if (_cachedToken == null && legacyPrefs != null) {
      final legacyToken = legacyPrefs.getString(_legacyPrefsKey);
      if (legacyToken != null && legacyToken.isNotEmpty) {
        await saveToken(legacyToken);
        await legacyPrefs.remove(_legacyPrefsKey);
      }
    }

    _initialized = true;
  }

  String? getToken() {
    return _cachedToken;
  }

  Future<void> saveToken(String token) async {
    _cachedToken = token;
    await _secureStorage.write(key: _keyToken, value: token);
  }

  Future<void> clearToken() async {
    _cachedToken = null;
    await _secureStorage.delete(key: _keyToken);
  }
}
