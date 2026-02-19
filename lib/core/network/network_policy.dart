import 'dart:async';

/// Políticas globais de rede para o SoloForte.
///
/// Todas as operações de rede devem usar [NetworkPolicy.withTimeout] para
/// garantir que nenhuma requisição trave indefinidamente.
abstract final class NetworkPolicy {
  /// Timeout padrão para todas as operações de rede.
  static const Duration kTimeout = Duration(seconds: 15);

  /// Máximo de tentativas para operações críticas (retry mínimo).
  static const int kMaxRetries = 2;

  /// Executa [operation] garantindo timeout de [kTimeout].
  ///
  /// Lança [TimeoutException] se a operação exceder o prazo.
  static Future<T> withTimeout<T>(Future<T> Function() operation) =>
      operation().timeout(kTimeout);

  /// Executa [operation] com timeout + retry linear simples.
  ///
  /// Tentativas: [maxAttempts] (padrão = [kMaxRetries]).
  /// Espera 2 s fixos entre tentativas.
  /// Relança o último erro se todas as tentativas falharem.
  static Future<T> withRetry<T>(
    Future<T> Function() operation, {
    int maxAttempts = kMaxRetries,
  }) async {
    Object? lastError;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        return await operation().timeout(kTimeout);
      } catch (e) {
        lastError = e;
        if (attempt < maxAttempts) {
          await Future<void>.delayed(const Duration(seconds: 2));
        }
      }
    }
    throw lastError!;
  }
}
