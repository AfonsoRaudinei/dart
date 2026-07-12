import 'dart:async';
import 'dart:io';

import 'app_logger.dart';

/// Converte um erro técnico em mensagem exibível ao usuário final (M-003).
///
/// Regras:
/// - Mensagens já traduzidas (`Exception('texto pt-BR')`, padrão do
///   AuthService) são preservadas, sem o prefixo `Exception: `.
/// - Falhas de rede viram orientação de conectividade.
/// - Qualquer outro tipo técnico vira fallback genérico — o detalhe completo
///   vai para o [AppLogger], nunca para a tela.
///
/// Uso: `Text(userFacingError(e, action: 'Erro ao exportar'))`.
String userFacingError(Object? error, {required String action}) {
  AppLogger.error(action, tag: 'UserFacingError', error: error);

  if (error is SocketException ||
      error is TimeoutException ||
      error is HttpException) {
    return '$action. Verifique sua conexão e tente novamente.';
  }

  if (error is Exception) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    final looksTechnical =
        message.isEmpty ||
        message.length > 140 ||
        message.startsWith('Exception') ||
        message.contains('Instance of') ||
        message.contains('SocketException') ||
        message.contains('errno') ||
        message.contains('#0') ||
        message.contains('http');
    if (!looksTechnical) {
      return '$action: $message';
    }
  }

  return '$action. Tente novamente.';
}
