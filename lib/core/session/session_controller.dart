import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'session_models.dart';

part 'session_controller.g.dart';

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  SessionState build() {
    // Inicia listener do stream de autenticação do Supabase.
    // O stream emite imediatamente com o estado atual e depois em cada mudança.
    _startListening();

    // Garante cancelamento ao dispor o provider.
    ref.onDispose(() => _authSubscription?.cancel());

    // Estado síncrono inicial baseado na sessão persistida pelo Supabase.
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser != null) {
      return SessionAuthenticated(currentUser);
    }
    return const SessionPublic();
  }

  void _startListening() {
    _authSubscription?.cancel();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen(
      (data) {
        final user = data.session?.user;
        if (user != null) {
          state = SessionAuthenticated(user);
        } else {
          state = const SessionPublic();
        }
      },
    );
  }

  /// Login real via Supabase Auth.
  /// Lança exceção com mensagem tratável em caso de falha.
  Future<void> login(String email, String password) async {
    await Supabase.instance.client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    // O stream onAuthStateChange atualiza o state automaticamente.
  }

  /// Cadastro real via Supabase Auth.
  Future<void> signup(String name, String email, String password) async {
    await Supabase.instance.client.auth.signUp(
      email: email,
      password: password,
      data: {'full_name': name},
    );
    // O stream onAuthStateChange atualiza o state automaticamente.
  }

  /// Logout real via Supabase Auth.
  Future<void> logout() async {
    await Supabase.instance.client.auth.signOut();
    // O stream onAuthStateChange seta state = SessionPublic() automaticamente.
  }
}
