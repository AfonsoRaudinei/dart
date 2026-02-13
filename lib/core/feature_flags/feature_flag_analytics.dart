import 'package:flutter/foundation.dart';

/// Analytics para monitoramento de Feature Flags.
///
/// Responsável por rastrear:
/// - Acessos a features
/// - Bloqueios por rollout/papel
/// - Uso de features habilitadas
/// - Métricas de performance
class FeatureFlagAnalytics {
  // TODO: Integrar com Firebase Analytics, Mixpanel, ou similar

  /// Registra tentativa de acesso a uma feature.
  static void trackFeatureAccess({
    required String featureKey,
    required String userId,
    required String? userRole,
    required bool wasEnabled,
    String? blockReason,
  }) {
    // TODO: Enviar para analytics backend
    // analytics.logEvent(
    //   name: 'feature_flag_access',
    //   parameters: {
    //     'feature_key': featureKey,
    //     'user_id': userId,
    //     'user_role': userRole ?? 'unknown',
    //     'enabled': wasEnabled,
    //     'block_reason': blockReason,
    //     'timestamp': DateTime.now().toIso8601String(),
    //   },
    // );

    // Por enquanto, apenas log
    if (wasEnabled) {
      debugPrint('📊 [Analytics] Feature $featureKey HABILITADA para $userId ($userRole)');
    } else {
      debugPrint('📊 [Analytics] Feature $featureKey BLOQUEADA para $userId - Motivo: $blockReason');
    }
  }

  /// Registra uso de feature habilitada.
  static void trackFeatureUsage({
    required String featureKey,
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
  }) {
    // TODO: Enviar para analytics backend
    // analytics.logEvent(
    //   name: 'feature_usage',
    //   parameters: {
    //     'feature_key': featureKey,
    //     'user_id': userId,
    //     'action': action,
    //     'metadata': jsonEncode(metadata ?? {}),
    //     'timestamp': DateTime.now().toIso8601String(),
    //   },
    // );

    debugPrint('📊 [Analytics] Feature $featureKey - Ação: $action por $userId');
  }

  /// Registra erro relacionado a feature flag.
  static void trackFeatureFlagError({
    required String featureKey,
    required String errorType,
    required String errorMessage,
  }) {
    // TODO: Enviar para analytics backend
    // analytics.logEvent(
    //   name: 'feature_flag_error',
    //   parameters: {
    //     'feature_key': featureKey,
    //     'error_type': errorType,
    //     'error_message': errorMessage,
    //     'timestamp': DateTime.now().toIso8601String(),
    //   },
    // );

    debugPrint('❌ [Analytics] Erro Feature Flag $featureKey: $errorMessage');
  }

  /// Registra métricas de performance de feature.
  static void trackFeaturePerformance({
    required String featureKey,
    required String userId,
    required String metric,
    required num value,
    String? unit,
  }) {
    // TODO: Enviar para analytics backend
    // analytics.logEvent(
    //   name: 'feature_performance',
    //   parameters: {
    //     'feature_key': featureKey,
    //     'user_id': userId,
    //     'metric': metric,
    //     'value': value,
    //     'unit': unit ?? 'ms',
    //     'timestamp': DateTime.now().toIso8601String(),
    //   },
    // );

    debugPrint('📊 [Analytics] Performance $featureKey - $metric: $value${unit ?? 'ms'}');
  }

  // ─────────────────────────────────────────────────────────────────────────
  // MÉTRICAS ESPECÍFICAS DO DRAWING MODULE
  // ─────────────────────────────────────────────────────────────────────────

  /// Registra acesso ao módulo Drawing.
  static void trackDrawingAccess({
    required String userId,
    required String? userRole,
    required bool wasEnabled,
  }) {
    trackFeatureAccess(
      featureKey: 'drawing_v1',
      userId: userId,
      userRole: userRole,
      wasEnabled: wasEnabled,
      blockReason: wasEnabled ? null : 'Feature flag disabled',
    );
  }

  /// Registra início de desenho.
  static void trackDrawingStarted({
    required String userId,
    required String toolType, // 'polygon', 'freehand', 'pivot'
  }) {
    trackFeatureUsage(
      featureKey: 'drawing_v1',
      userId: userId,
      action: 'drawing_started',
      metadata: {'tool_type': toolType},
    );
  }

  /// Registra conclusão de desenho.
  static void trackDrawingCompleted({
    required String userId,
    required String toolType,
    required double areaHectares,
    required int pointCount,
    required Duration drawingDuration,
  }) {
    trackFeatureUsage(
      featureKey: 'drawing_v1',
      userId: userId,
      action: 'drawing_completed',
      metadata: {
        'tool_type': toolType,
        'area_hectares': areaHectares,
        'point_count': pointCount,
        'duration_seconds': drawingDuration.inSeconds,
      },
    );

    // Métrica de performance: tempo de desenho
    trackFeaturePerformance(
      featureKey: 'drawing_v1',
      userId: userId,
      metric: 'drawing_duration',
      value: drawingDuration.inSeconds,
      unit: 's',
    );
  }

  /// Registra cancelamento de desenho.
  static void trackDrawingCancelled({
    required String userId,
    required String toolType,
    required int pointCount,
  }) {
    trackFeatureUsage(
      featureKey: 'drawing_v1',
      userId: userId,
      action: 'drawing_cancelled',
      metadata: {
        'tool_type': toolType,
        'point_count': pointCount,
      },
    );
  }

  /// Registra erro de validação topológica.
  static void trackDrawingValidationError({
    required String userId,
    required String errorType, // 'self_intersection', 'invalid_geometry'
    required String toolType,
  }) {
    trackFeatureFlagError(
      featureKey: 'drawing_v1',
      errorType: 'validation_error',
      errorMessage: '$errorType on $toolType',
    );
  }
}
