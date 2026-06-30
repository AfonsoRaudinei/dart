import 'package:supabase_flutter/supabase_flutter.dart';

sealed class SessionState {
  const SessionState();
}

/// Estado inicial enquanto o stream de auth ainda não emitiu.
class SessionUnknown extends SessionState {
  const SessionUnknown();
}

/// Nenhum usuário autenticado.
class SessionPublic extends SessionState {
  const SessionPublic();
}

/// Usuário autenticado via Supabase Auth.
class SessionAuthenticated extends SessionState {
  /// Usuário real do Supabase — nunca contém token fake.
  final User user;
  const SessionAuthenticated(this.user);
}

/// Sessão de recuperação de senha ativa.
/// Emitido exclusivamente quando [AuthChangeEvent.passwordRecovery]
/// é detectado — garante que apenas usuários vindos do deep link de
/// recovery conseguem acessar a tela de redefinição de senha.
class SessionPasswordRecovery extends SessionState {
  final User user;
  const SessionPasswordRecovery(this.user);
}
