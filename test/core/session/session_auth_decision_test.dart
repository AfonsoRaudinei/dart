import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/session_auth_decision.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('resolveAuthStreamError', () {
    test('erro de rede com usuário local não vira sessão pública', () {
      final user = _user();
      final resolution = resolveAuthStreamError(
        error: AuthRetryableFetchException(message: 'offline'),
        currentUser: user,
        previous: const SessionUnknown(),
      );

      expect(resolution.identity, SessionIdentityEffect.remember);
      expect(resolution.nextState, isA<SessionAuthenticated>());
      expect((resolution.nextState! as SessionAuthenticated).user.id, user.id);
    });

    test('já autenticado com o mesmo usuário: não troca o estado', () {
      final user = _user();
      final resolution = resolveAuthStreamError(
        error: const SocketException('failed host lookup'),
        currentUser: user,
        previous: SessionAuthenticated(user),
      );

      expect(resolution.identity, SessionIdentityEffect.remember);
      expect(resolution.nextState, isNull);
    });

    test('timeout com usuário local permanece autenticado', () {
      final user = _user();
      final resolution = resolveAuthStreamError(
        error: TimeoutException('refresh'),
        currentUser: user,
        previous: SessionAuthenticated(user),
      );

      expect(resolution.nextState, isNull);
      expect(resolution.identity, SessionIdentityEffect.remember);
    });

    test('erro de credencial sem sessão vira público', () {
      final resolution = resolveAuthStreamError(
        error: const AuthException('Invalid login credentials'),
        currentUser: null,
        previous: const SessionUnknown(),
      );

      expect(resolution.identity, SessionIdentityEffect.markPublic);
      expect(resolution.nextState, isA<SessionPublic>());
    });
  });

  group('resolveAuthStreamEvent', () {
    test('signedOut limpa identidade e vai a público', () {
      final resolution = resolveAuthStreamEvent(
        event: AuthChangeEvent.signedOut,
        sessionUser: null,
        previous: SessionAuthenticated(_user()),
      );

      expect(resolution.identity, SessionIdentityEffect.clear);
      expect(resolution.nextState, isA<SessionPublic>());
    });

    test('initialSession sem usuário confirma visitante', () {
      final resolution = resolveAuthStreamEvent(
        event: AuthChangeEvent.initialSession,
        sessionUser: null,
        previous: const SessionUnknown(),
      );

      expect(resolution.identity, SessionIdentityEffect.markPublic);
      expect(resolution.nextState, isA<SessionPublic>());
    });

    test('initialSession vazio não derruba sessão já autenticada', () {
      final resolution = resolveAuthStreamEvent(
        event: AuthChangeEvent.initialSession,
        sessionUser: null,
        previous: SessionAuthenticated(_user()),
      );

      expect(resolution.identity, SessionIdentityEffect.none);
      expect(resolution.nextState, isNull);
    });
  });
}

User _user() => User.fromJson(const {
  'id': 'user-offline',
  'app_metadata': <String, dynamic>{},
  'user_metadata': <String, dynamic>{},
  'aud': 'authenticated',
  'created_at': '2026-08-16T12:00:00.000Z',
})!;
