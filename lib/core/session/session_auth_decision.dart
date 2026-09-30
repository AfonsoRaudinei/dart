import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'session_models.dart';

/// Efeito na identidade local (prefs / lastKnown). Não fala com o router.
enum SessionIdentityEffect { none, remember, markPublic, clear }

/// Próximo [SessionState]. `nextState == null` mantém o estado anterior.
class SessionStreamResolution {
  const SessionStreamResolution({
    this.nextState,
    this.identity = SessionIdentityEffect.none,
  });

  final SessionState? nextState;
  final SessionIdentityEffect identity;
}

/// Falha de rede no refresh do JWT. O GoTrue mantém `currentUser` nesses casos.
bool isRetryableAuthFailure(Object error) {
  if (error is AuthRetryableFetchException) return true;
  if (error is TimeoutException) return true;

  final lower = error.toString().toLowerCase();
  return lower.contains('socket') ||
      lower.contains('timeout') ||
      lower.contains('network') ||
      lower.contains('host lookup') ||
      lower.contains('connection refused') ||
      lower.contains('connection reset') ||
      lower.contains('network is unreachable') ||
      lower.contains('failed host lookup');
}

/// Decisão do listener `onAuthStateChange` (eventos, não erros).
SessionStreamResolution resolveAuthStreamEvent({
  required AuthChangeEvent event,
  required User? sessionUser,
  required SessionState previous,
}) {
  if (event == AuthChangeEvent.passwordRecovery && sessionUser != null) {
    return SessionStreamResolution(
      nextState: SessionPasswordRecovery(sessionUser),
    );
  }

  if (sessionUser != null) {
    return SessionStreamResolution(
      nextState: SessionAuthenticated(sessionUser),
      identity: SessionIdentityEffect.remember,
    );
  }

  if (event == AuthChangeEvent.signedOut) {
    return const SessionStreamResolution(
      nextState: SessionPublic(),
      identity: SessionIdentityEffect.clear,
    );
  }

  if (event == AuthChangeEvent.initialSession) {
    if (previous is SessionAuthenticated) {
      return const SessionStreamResolution();
    }
    return const SessionStreamResolution(
      nextState: SessionPublic(),
      identity: SessionIdentityEffect.markPublic,
    );
  }

  return const SessionStreamResolution(
    nextState: SessionPublic(),
    identity: SessionIdentityEffect.markPublic,
  );
}

/// Erro do stream de auth. Rede com usuário local não é logout.
SessionStreamResolution resolveAuthStreamError({
  required Object error,
  required User? currentUser,
  required SessionState previous,
}) {
  if (isRetryableAuthFailure(error) && currentUser != null) {
    final already =
        previous is SessionAuthenticated && previous.user.id == currentUser.id;
    return SessionStreamResolution(
      nextState: already ? null : SessionAuthenticated(currentUser),
      identity: SessionIdentityEffect.remember,
    );
  }

  return const SessionStreamResolution(
    nextState: SessionPublic(),
    identity: SessionIdentityEffect.markPublic,
  );
}
