class AuthService {
  // Fake login - simple delay and success
  Future<String> login(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (email.contains('error')) throw Exception('Credenciais inválidas');
    return 'fake-jwt-token-for-$email';
  }

  // Fake signup
  Future<String> signup(String name, String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (email.contains('exists')) throw Exception('Email já cadastrado');
    return 'fake-jwt-token-new-user-$email';
  }
}
