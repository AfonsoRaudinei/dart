import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shelf/shelf.dart';
import '../storage/feature_flag_storage.dart';

/// Middleware para validação de feature flags em endpoints protegidos.
///
/// Uso:
/// ```dart
/// final handler = Pipeline()
///   .addMiddleware(FeatureFlagValidator.requireFeature('drawing_v1'))
///   .addHandler(myProtectedHandler);
/// ```
class FeatureFlagValidator {
  final FeatureFlagStorage _storage;

  FeatureFlagValidator(this._storage);

  /// Middleware que valida se feature está habilitada para o usuário.
  Middleware requireFeature(String featureKey) {
    return (Handler handler) {
      return (Request request) async {
        // Extrair userId e role dos headers ou JWT
        final userId = request.headers['x-user-id'];
        final userRole = request.headers['x-user-role'];
        final appVersion = request.headers['x-app-version'];

        if (userId == null) {
          return Response.badRequest(
            body: jsonEncode({'error': 'Missing user identification'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Buscar flag
        final flag = await _storage.getFlag(featureKey);

        if (flag == null) {
          return Response.internalServerError(
            body: jsonEncode({'error': 'Feature flag not configured: $featureKey'}),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Validar se está habilitada
        final isEnabled = _isFeatureEnabled(
          flag: flag,
          userId: userId,
          userRole: userRole,
          appVersion: appVersion,
        );

        if (!isEnabled) {
          return Response(
            403,
            body: jsonEncode({
              'error': 'Feature not available',
              'feature': featureKey,
              'reason': 'Feature flag disabled or user not in rollout',
            }),
            headers: {'Content-Type': 'application/json'},
          );
        }

        // Feature habilitada → prosseguir
        return handler(request);
      };
    };
  }

  /// Lógica de validação de feature flag (espelhada do client).
  bool _isFeatureEnabled({
    required Map<String, dynamic> flag,
    required String userId,
    String? userRole,
    String? appVersion,
  }) {
    // 1️⃣ Kill switch: flag globalmente desativada
    if (flag['enabled'] != true) {
      return false;
    }

    // 2️⃣ Filtro por papel
    final allowedRoles = flag['allowed_roles'] as List?;
    if (allowedRoles != null && allowedRoles.isNotEmpty && userRole != null) {
      if (!allowedRoles.contains(userRole)) {
        return false;
      }
    }

    // 3️⃣ Rollout percentual determinístico
    final rolloutPercentage = flag['rollout_percentage'] as int? ?? 0;
    if (!_isUserInRollout(userId, rolloutPercentage)) {
      return false;
    }

    // 4️⃣ Versão mínima do app
    final minAppVersion = flag['min_app_version'] as String?;
    if (minAppVersion != null && appVersion != null) {
      if (!_meetsMinVersion(appVersion, minAppVersion)) {
        return false;
      }
    }

    return true;
  }

  /// Hash determinístico do userId (mesmo algoritmo do client).
  bool _isUserInRollout(String userId, int rolloutPercentage) {
    if (rolloutPercentage >= 100) return true;
    if (rolloutPercentage <= 0) return false;

    final bytes = utf8.encode(userId);
    final digest = sha256.convert(bytes);

    final hashInt = (digest.bytes[0] << 24) |
        (digest.bytes[1] << 16) |
        (digest.bytes[2] << 8) |
        digest.bytes[3];

    final bucket = hashInt.abs() % 100;

    return bucket < rolloutPercentage;
  }

  /// Compara versões semver.
  bool _meetsMinVersion(String current, String required) {
    try {
      final currentParts = current.split('.').map(int.parse).toList();
      final requiredParts = required.split('.').map(int.parse).toList();

      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (requiredParts.length < 3) {
        requiredParts.add(0);
      }

      for (int i = 0; i < 3; i++) {
        if (currentParts[i] > requiredParts[i]) return true;
        if (currentParts[i] < requiredParts[i]) return false;
      }

      return true;
    } catch (e) {
      return false;
    }
  }
}
