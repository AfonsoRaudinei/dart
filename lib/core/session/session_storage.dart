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
  final SharedPreferences _prefs;
  static const _keyToken = 'session_token';

  SessionStorage(this._prefs);

  String? getToken() {
    return _prefs.getString(_keyToken);
  }

  Future<void> saveToken(String token) async {
    await _prefs.setString(_keyToken, token);
  }

  Future<void> clearToken() async {
    await _prefs.remove(_keyToken);
  }
}
