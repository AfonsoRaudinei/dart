import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'feature_flag_model.dart';

/// Entidade de usuário mínima necessária para resolução de feature flags.
class FeatureFlagUser {
  final String userId;
  final String? role;
  final String? appVersion;

  const FeatureFlagUser({
    required this.userId,
    this.role,
    this.appVersion,
  });
}

/// Resolvedor puro e determinístico de Feature Flags.
///
/// **Função pura**: sem efeitos colaterais, sem estado, sem lógica de UI.
/// **Determinístico**: mesmo usuário sempre recebe mesma decisão para mesma flag.
///
/// Ordem de decisão (fail-fast):
/// 1. Flag global enabled?
/// 2. Papel permitido?
/// 3. Hash do userId dentro do rolloutPercentage?
/// 4. App version >= mínima?
///
/// Se qualquer condição falhar → feature desativada.
class FeatureFlagResolver {
  const FeatureFlagResolver();

  /// Decide se uma feature está ativa para um usuário específico.
  ///
  /// Exemplo:
  /// ```dart
  /// final user = FeatureFlagUser(userId: '123', role: 'consultor');
  /// final flag = FeatureFlag(key: 'drawing_v1', enabled: true, rolloutPercentage: 50, version: 1);
  /// final active = resolver.isFeatureEnabled(flag, user);
  /// ```
  bool isFeatureEnabled(FeatureFlag flag, FeatureFlagUser user) {
    // 1️⃣ Kill switch: flag globalmente desativada
    if (!flag.enabled) {
      return false;
    }

    // 2️⃣ Filtro por papel (se especificado)
    if (flag.allowedRoles != null &&
        flag.allowedRoles!.isNotEmpty &&
        user.role != null) {
      if (!flag.allowedRoles!.contains(user.role)) {
        return false;
      }
    }

    // 3️⃣ Rollout percentual determinístico
    if (!_isUserInRollout(user.userId, flag.rolloutPercentage)) {
      return false;
    }

    // 4️⃣ Versão mínima do app (se especificada)
    if (flag.minAppVersion != null && user.appVersion != null) {
      if (!_meetsMinVersion(user.appVersion!, flag.minAppVersion!)) {
        return false;
      }
    }

    return true;
  }

  /// Hash determinístico do userId para rollout consistente.
  ///
  /// Regra: `hash(userId) % 100 < rolloutPercentage`
  ///
  /// Garante:
  /// - Mesmo usuário sempre no mesmo bucket (0-99)
  /// - Distribuição uniforme
  /// - Não muda entre sessões/restarts
  bool _isUserInRollout(String userId, int rolloutPercentage) {
    if (rolloutPercentage >= 100) return true;
    if (rolloutPercentage <= 0) return false;

    // Hash SHA-256 do userId
    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);

    // Pegar primeiros 4 bytes como inteiro (suficiente para distribuição)
    final hashInt = (digest.bytes[0] << 24) |
        (digest.bytes[1] << 16) |
        (digest.bytes[2] << 8) |
        digest.bytes[3];

    // Bucket 0-99
    final bucket = hashInt.abs() % 100;

    return bucket < rolloutPercentage;
  }

  /// Compara versões no formato semver simplificado (major.minor.patch).
  ///
  /// Retorna true se `current >= required`.
  bool _meetsMinVersion(String current, String required) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final requiredParts = required.split('.').map(int.parse).toList();

      // Normalizar tamanhos (1.0 → 1.0.0)
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (requiredParts.length < 3) {
        requiredParts.add(0);
      }

      // Comparar major.minor.patch
      for (int i = 0; i < 3; i++) {
        if (currentParts[i] > requiredParts[i]) return true;
        if (currentParts[i] < requiredParts[i]) return false;
      }

      return true; // Versões idênticas
    } catch (e) {
      // Formato inválido → considerar como não atende
      return false;
    }
  }

  /// Método de conveniência para verificar feature "drawing_v1".
  bool isDrawingEnabled(FeatureFlag flag, FeatureFlagUser user) {
    assert(flag.key == 'drawing_v1',
        'Use isDrawingEnabled apenas para drawing_v1');
    return isFeatureEnabled(flag, user);
  }
}
