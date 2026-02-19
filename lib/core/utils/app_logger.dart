import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Logger estruturado do SoloForte.
///
/// **Regras de uso:**
/// - Jamais use [debugPrint] direto — passe por aqui.
/// - [debug] → visível apenas em debug mode.
/// - [warning] → visível em debug e profile mode.
/// - [error] → sempre registrado, inclusive em release.
///
/// Todos os logs usam `dart:developer` (aparece no DevTools,
/// não polui stdout em produção).
abstract final class AppLogger {
  /// Log de depuração — suprimido em profile e release.
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      developer.log(message, name: tag ?? 'SoloForte');
    }
  }

  /// Aviso — suprimido apenas em release.
  static void warning(String message, {String? tag, Object? error}) {
    if (!kReleaseMode) {
      developer.log(message, name: tag ?? 'SoloForte', error: error);
    }
  }

  /// Erro — sempre registrado (visível em todas as builds).
  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    developer.log(
      message,
      name: tag ?? 'SoloForte.Error',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
