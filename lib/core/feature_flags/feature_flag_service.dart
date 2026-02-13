import 'dart:async';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'feature_flag_model.dart';

/// Serviço de gerenciamento de Feature Flags.
///
/// Responsável por:
/// - Buscar flags do backend
/// - Cache local com TTL
/// - Atualização em background
/// - Fallback para valores padrão
class FeatureFlagService {
  // Dependências externas (injetadas para testabilidade)
  final Future<Map<String, dynamic>> Function() _fetchFromBackend;
  final Future<SharedPreferences> Function() _getPreferences;

  // Configuração de cache
  static const String _cachePrefix = 'feature_flag_';
  static const String _cacheTimestampSuffix = '_timestamp';
  static const Duration _cacheTTL = Duration(minutes: 15);

  // Atualização em background
  Timer? _backgroundUpdateTimer;
  static const Duration _backgroundUpdateInterval = Duration(minutes: 30);

  FeatureFlagService({
    required Future<Map<String, dynamic>> Function() fetchFromBackend,
    Future<SharedPreferences> Function()? getPreferences,
  })  : _fetchFromBackend = fetchFromBackend,
        _getPreferences = getPreferences ?? SharedPreferences.getInstance;

  /// Inicia atualização automática em background.
  void startBackgroundUpdates() {
    _backgroundUpdateTimer?.cancel();
    _backgroundUpdateTimer = Timer.periodic(_backgroundUpdateInterval, (_) {
      _updateCacheInBackground();
    });
  }

  /// Para atualização em background.
  void stopBackgroundUpdates() {
    _backgroundUpdateTimer?.cancel();
    _backgroundUpdateTimer = null;
  }

  /// Busca uma feature flag específica.
  ///
  /// Estratégia:
  /// 1. Verifica cache local (se válido por TTL)
  /// 2. Se cache expirado ou inexistente → busca do backend
  /// 3. Se backend falhar → usa cache expirado (se existir)
  /// 4. Se nada disponível → retorna flag desativada (kill switch seguro)
  Future<FeatureFlag> getFlag(String key) async {
    try {
      // 1️⃣ Verificar cache local
      final cachedFlag = await _getCachedFlag(key);
      if (cachedFlag != null) {
        return cachedFlag;
      }

      // 2️⃣ Buscar do backend
      final backendData = await _fetchFromBackend();
      final flags = _parseBackendResponse(backendData);
      final flag = flags[key];

      if (flag != null) {
        // Salvar no cache
        await _cacheFlag(key, flag);
        return flag;
      }

      // 3️⃣ Flag não encontrada → desabilitada por padrão
      return FeatureFlag.disabled(key);
    } catch (e) {
      // 4️⃣ Erro crítico → tentar cache expirado como fallback
      final staleCache = await _getStaleCache(key);
      if (staleCache != null) {
        return staleCache;
      }

      // Último recurso: desabilitada
      return FeatureFlag.disabled(key);
    }
  }

  /// Busca flag específica para Drawing (conveniência).
  Future<FeatureFlag> getDrawingFlag() async {
    return getFlag('drawing_v1');
  }

  /// Verifica cache local e valida TTL.
  Future<FeatureFlag?> _getCachedFlag(String key) async {
    try {
      final prefs = await _getPreferences();
      final cacheKey = _cachePrefix + key;
      final timestampKey = cacheKey + _cacheTimestampSuffix;

      final flagJson = prefs.getString(cacheKey);
      final timestamp = prefs.getInt(timestampKey);

      if (flagJson == null || timestamp == null) {
        return null;
      }

      // Validar TTL
      final cacheAge = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (cacheAge > _cacheTTL.inMilliseconds) {
        return null; // Cache expirado
      }

      final json = jsonDecode(flagJson) as Map<String, dynamic>;
      return FeatureFlag.fromJson(json);
    } catch (e) {
      return null; // Erro de parsing → cache inválido
    }
  }

  /// Recupera cache expirado (usado como fallback em caso de falha de rede).
  Future<FeatureFlag?> _getStaleCache(String key) async {
    try {
      final prefs = await _getPreferences();
      final cacheKey = _cachePrefix + key;
      final flagJson = prefs.getString(cacheKey);

      if (flagJson == null) return null;

      final json = jsonDecode(flagJson) as Map<String, dynamic>;
      return FeatureFlag.fromJson(json);
    } catch (e) {
      return null;
    }
  }

  /// Salva flag no cache local com timestamp.
  Future<void> _cacheFlag(String key, FeatureFlag flag) async {
    try {
      final prefs = await _getPreferences();
      final cacheKey = _cachePrefix + key;
      final timestampKey = cacheKey + _cacheTimestampSuffix;

      final flagJson = jsonEncode(flag.toJson());
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      await prefs.setString(cacheKey, flagJson);
      await prefs.setInt(timestampKey, timestamp);
    } catch (e) {
      // Falha de cache não é crítica
    }
  }

  /// Atualiza cache em background (sem bloquear UI).
  Future<void> _updateCacheInBackground() async {
    try {
      final backendData = await _fetchFromBackend();
      final flags = _parseBackendResponse(backendData);

      // Atualizar todas as flags conhecidas
      for (final entry in flags.entries) {
        await _cacheFlag(entry.key, entry.value);
      }
    } catch (e) {
      // Falha silenciosa em background
    }
  }

  /// Parse da resposta do backend.
  ///
  /// Formato esperado:
  /// ```json
  /// {
  ///   "flags": [
  ///     {"key": "drawing_v1", "enabled": true, "rollout_percentage": 50, ...}
  ///   ]
  /// }
  /// ```
  Map<String, FeatureFlag> _parseBackendResponse(Map<String, dynamic> data) {
    final result = <String, FeatureFlag>{};

    try {
      final flagsJson = data['flags'] as List<dynamic>;

      for (final item in flagsJson) {
        final flag = FeatureFlag.fromJson(item as Map<String, dynamic>);
        result[flag.key] = flag;
      }
    } catch (e) {
      // Parsing falhou → retornar vazio (fallback para cache/disabled)
    }

    return result;
  }

  /// Limpa todo o cache de feature flags.
  Future<void> clearCache() async {
    try {
      final prefs = await _getPreferences();
      final keys = prefs.getKeys();

      for (final key in keys) {
        if (key.startsWith(_cachePrefix)) {
          await prefs.remove(key);
        }
      }
    } catch (e) {
      // Falha não crítica
    }
  }

  /// Dispose do serviço (para testes).
  void dispose() {
    stopBackgroundUpdates();
  }
}
