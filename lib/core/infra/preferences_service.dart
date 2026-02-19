import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Wrapper síncrono sobre [SharedPreferences].
///
/// Elimina `SharedPreferences.getInstance()` espalhado pelas camadas de dados
/// e apresentação. A instância já está inicializada antes do uso (via main.dart).
///
/// Regra arquitetural (PR #5):
/// - Único ponto de acesso a SharedPreferences no app.
/// - Injetado via [preferencesServiceProvider] em todos os consumidores.
/// - Domínio e apresentação nunca importam `package:shared_preferences`.
class PreferencesService {
  const PreferencesService(this._prefs);

  final SharedPreferences _prefs;

  // ── Leitura (síncrona) ──────────────────────────────────────────

  String? getString(String key) => _prefs.getString(key);
  bool? getBool(String key) => _prefs.getBool(key);
  int? getInt(String key) => _prefs.getInt(key);
  List<String>? getStringList(String key) => _prefs.getStringList(key);
  bool containsKey(String key) => _prefs.containsKey(key);
  Set<String> getKeys() => _prefs.getKeys();

  // ── Escrita (assíncrona) ────────────────────────────────────────

  Future<bool> setString(String key, String value) =>
      _prefs.setString(key, value);
  Future<bool> setBool(String key, bool value) => _prefs.setBool(key, value);
  Future<bool> setInt(String key, int value) => _prefs.setInt(key, value);
  Future<bool> setStringList(String key, List<String> value) =>
      _prefs.setStringList(key, value);

  // ── Remoção ─────────────────────────────────────────────────────

  Future<bool> remove(String key) => _prefs.remove(key);
}

/// Provider para [PreferencesService].
///
/// **Não possui implementação padrão.**
/// Deve ser substituído via `ProviderScope.overrides` em `main()` antes do
/// uso. Qualquer acesso sem override lança [StateError] imediato e explícito —
/// falha rápida em vez de comportamento silencioso.
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  throw StateError(
    '[PreferencesService] Provider não inicializado. '
    'Adicione preferencesServiceProvider.overrideWithValue(...) em main().',
  );
});
