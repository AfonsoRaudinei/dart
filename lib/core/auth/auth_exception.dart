class AuthException implements Exception {
  final String message;

  const AuthException(this.message);

  @override
  String toString() => message;
}

String mapAuthError(Object error) {
  final message = error.toString().toLowerCase();

  if (message.contains('invalid login credentials') ||
      message.contains('invalid email or password')) {
    return 'E-mail ou senha incorretos.';
  }
  if (message.contains('user already registered') ||
      message.contains('already been registered')) {
    return 'Este e-mail já está cadastrado.';
  }
  if (message.contains('password') && message.contains('least')) {
    return 'A senha deve ter no mínimo 8 caracteres.';
  }
  if (message.contains('valid email') || message.contains('invalid email')) {
    return 'Informe um e-mail válido.';
  }
  if (message.contains('network') || message.contains('socket')) {
    return 'Sem conexão. Verifique sua internet e tente novamente.';
  }
  if (message.contains('not configured') ||
      message.contains('supabase não configurado')) {
    return 'Serviço de autenticação indisponível. Tente novamente mais tarde.';
  }
  if (message.contains('email not confirmed')) {
    return 'Confirme seu e-mail antes de entrar.';
  }
  if (message.contains('delete_own_account')) {
    return 'Não foi possível excluir a conta. Entre em contato com o suporte.';
  }

  if (error is AuthException) {
    return error.message;
  }

  return 'Não foi possível concluir a operação. Tente novamente.';
}
