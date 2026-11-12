import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/auth_deep_link.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('kAuthEmailRedirectUrl', () {
    test('aponta para o deep link de login do app', () {
      expect(kAuthEmailRedirectUrl, 'soloforte://login');
      final uri = Uri.parse(kAuthEmailRedirectUrl);
      expect(uri.scheme, 'soloforte');
      expect(uri.host, 'login');
    });

    test('retorno do link de confirmação é interpretado como signup', () {
      final uri = Uri.parse(
        '$kAuthEmailRedirectUrl#access_token=a&refresh_token=b&type=signup',
      );
      final intent = AuthDeepLinkIntent.parse(uri);
      expect(intent.type, AuthDeepLinkType.signup);
      expect(intent.hasCredentials, isTrue);
    });
  });

  group('traduzirAuthException — casos existentes', () {
    test('credenciais inválidas', () {
      expect(
        traduzirAuthException(const AuthException('Invalid login credentials')),
        'Email ou senha incorretos.',
      );
    });

    test('já cadastrado', () {
      expect(
        traduzirAuthException(const AuthException('User already registered')),
        'Este email já está cadastrado.',
      );
    });

    test('email não confirmado', () {
      expect(
        traduzirAuthException(const AuthException('Email not confirmed')),
        'Email não confirmado. Verifique sua caixa de entrada.',
      );
    });

    test('senha curta', () {
      expect(
        traduzirAuthException(
          const AuthException('Password should be at least 6 characters'),
        ),
        'A senha deve ter pelo menos 8 caracteres.',
      );
    });

    test('rate limit', () {
      expect(
        traduzirAuthException(const AuthException('email rate limit exceeded')),
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      );
    });

    test('rede', () {
      const conexao =
          'Não foi possível conectar ao servidor. Verifique sua conexão e tente novamente.';
      expect(traduzirAuthException(AuthRetryableFetchException()), conexao);
      expect(
        traduzirAuthException(const AuthException('Socket closed')),
        conexao,
      );
    });

    test('desconhecido genérico', () {
      expect(
        traduzirAuthException(const AuthException('algo estranho')),
        'Erro de autenticação. Tente novamente.',
      );
    });
  });

  group('traduzirAuthException — casos novos', () {
    test('link expirado por code', () {
      expect(
        traduzirAuthException(
          const AuthException(
            'Email link is invalid or has expired',
            code: 'otp_expired',
          ),
        ),
        contains('expirou'),
      );
    });

    test('link expirado por mensagem', () {
      expect(
        traduzirAuthException(
          const AuthException('Email link is invalid or has expired'),
        ),
        contains('expirou'),
      );
    });

    test('falha ao enviar e-mail de confirmação (SMTP)', () {
      expect(
        traduzirAuthException(
          const AuthException(
            'Error sending confirmation email',
            statusCode: '500',
            code: 'unexpected_failure',
          ),
        ),
        contains('enviar o e-mail de confirmação'),
      );
    });

    test('database error saving new user', () {
      expect(
        traduzirAuthException(
          const AuthException('Database error saving new user'),
        ),
        contains('criar a conta'),
      );
    });

    test('cadastro desabilitado', () {
      expect(
        traduzirAuthException(const AuthException('Signups not allowed')),
        contains('indisponível'),
      );
      expect(
        traduzirAuthException(
          const AuthException('x', code: 'signup_disabled'),
        ),
        contains('indisponível'),
      );
    });

    test('e-mail inválido', () {
      expect(
        traduzirAuthException(
          const AuthException(
            'Email address "a@b" is invalid',
            code: 'email_address_invalid',
          ),
        ),
        contains('e-mail não é válido'),
      );
    });

    test('senha fraca', () {
      expect(
        traduzirAuthException(
          const AuthException(
            'Password is known to be weak and easy to guess',
            code: 'weak_password',
          ),
        ),
        contains('fraca'),
      );
    });

    test('over_email_send_rate_limit por code e por status 429', () {
      const msg = 'Muitas tentativas. Aguarde alguns minutos e tente novamente.';
      expect(
        traduzirAuthException(
          const AuthException('x', code: 'over_email_send_rate_limit'),
        ),
        msg,
      );
      expect(
        traduzirAuthException(const AuthException('x', statusCode: '429')),
        msg,
      );
    });

    test('código OTP inválido ou expirado (verifyOTP)', () {
      const msg = 'Código inválido ou expirado. Peça um novo código.';
      expect(
        traduzirAuthException(
          const AuthException(
            'Token has expired or is invalid',
            statusCode: '403',
            code: 'otp_expired',
          ),
        ),
        msg,
      );
      expect(
        traduzirAuthException(
          const AuthException('Token has expired or is invalid'),
        ),
        msg,
      );
    });

    test('over_request_rate_limit', () {
      expect(
        traduzirAuthException(
          const AuthException(
            'Request rate limit reached',
            statusCode: '429',
            code: 'over_request_rate_limit',
          ),
        ),
        'Muitas tentativas. Aguarde alguns minutos e tente novamente.',
      );
    });

    test('mensagem de código não vaza texto cru do servidor', () {
      final msg = traduzirAuthException(
        const AuthException(
          'Token has expired or is invalid',
          code: 'otp_expired',
        ),
      );
      expect(msg, isNot(contains('Token')));
      expect(msg, isNot(contains('otp_expired')));
    });

    test('mensagem não vaza e-mail nem texto cru', () {
      final msg = traduzirAuthException(
        const AuthException(
          'Email address "segredo@exemplo.com" is invalid',
          code: 'email_address_invalid',
        ),
      );
      expect(msg, isNot(contains('segredo@exemplo.com')));
      expect(msg, isNot(contains('Email address')));
    });
  });
}
