import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const _persistedErrorsKey = 'app_logger.persisted_errors.v1';
  static const _maxPersistedErrors = 30;
  static const _maxFieldLength = 2000;
  static Future<void> _writeChain = Future.value();

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
    unawaited(
      persistError(message, tag: tag, error: error, stackTrace: stackTrace),
    );
  }

  static Future<void> persistError(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _writeChain = _writeChain
        .then((_) async {
          final preferences = await SharedPreferences.getInstance();
          final entries =
              preferences.getStringList(_persistedErrorsKey) ?? <String>[];
          entries.add(
            jsonEncode({
              'timestamp': DateTime.now().toUtc().toIso8601String(),
              'tag': _sanitize(tag ?? 'SoloForte.Error'),
              'message': _sanitize(message),
              if (error != null) 'errorType': error.runtimeType.toString(),
              if (stackTrace != null)
                'stackTraceHash': stackTrace.toString().hashCode.toString(),
            }),
          );
          if (entries.length > _maxPersistedErrors) {
            entries.removeRange(0, entries.length - _maxPersistedErrors);
          }
          await preferences.setStringList(_persistedErrorsKey, entries);
        })
        .catchError((_) {
          // A persistência de observabilidade nunca deve interromper o fluxo.
        });
    return _writeChain;
  }

  static Future<List<Map<String, dynamic>>> readPersistedErrors() async {
    await _writeChain;
    final preferences = await SharedPreferences.getInstance();
    final entries = preferences.getStringList(_persistedErrorsKey) ?? const [];
    return entries
        .map((entry) => jsonDecode(entry) as Map<String, dynamic>)
        .toList(growable: false);
  }

  static Future<void> clearPersistedErrors() async {
    await _writeChain;
    final preferences = await SharedPreferences.getInstance();
    await preferences.remove(_persistedErrorsKey);
  }

  static String _sanitize(String value) {
    final redacted = value
        .replaceAll(
          RegExp(r'https?://[^\s]+', caseSensitive: false),
          '[REDACTED_URL]',
        )
        .replaceAll(
          RegExp(
            r'[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}',
            caseSensitive: false,
          ),
          '[REDACTED_EMAIL]',
        )
        .replaceAll(
          RegExp(
            r'(access_token|refresh_token|token|authorization|password|senha)\s*[:=]\s*[^\s,;]+',
            caseSensitive: false,
          ),
          '[REDACTED_SECRET]',
        )
        .replaceAll(
          RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b'),
          '[REDACTED_DOCUMENT]',
        )
        .replaceAll(
          RegExp(
            r'\b[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\b',
            caseSensitive: false,
          ),
          '[REDACTED_ID]',
        )
        .replaceAll(
          RegExp(r'(\+?55\s*)?\(?\d{2}\)?\s*9?\d{4}[-\s]?\d{4}'),
          '[REDACTED_PHONE]',
        )
        .replaceAll(RegExp(r'\b-?\d{1,3}\.\d{4,}\b'), '[REDACTED_COORD]');
    if (redacted.length <= _maxFieldLength) return redacted;
    return '${redacted.substring(0, _maxFieldLength)}…';
  }
}
