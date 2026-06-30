import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import 'auth_exception.dart';

class AuthService {
  SupabaseClient? get _client {
    if (!AppConfig.hasSupabaseConfig) return null;
    return Supabase.instance.client;
  }

  void _ensureConfigured() {
    if (_client == null) {
      throw const AuthException(
        'Supabase não configurado. Defina SUPABASE_URL e SUPABASE_ANON_KEY.',
      );
    }
  }

  Future<String> login(String email, String password) async {
    _ensureConfigured();
    try {
      final response = await _client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final session = response.session;
      if (session == null) {
        throw const AuthException('Credenciais inválidas.');
      }
      return session.accessToken;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(mapAuthError(e));
    }
  }

  Future<String> signup(String name, String email, String password) async {
    _ensureConfigured();
    try {
      final response = await _client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {'full_name': name.trim()},
      );
      final session = response.session;
      if (session != null) {
        return session.accessToken;
      }

      // Confirmação de e-mail habilitada no Supabase.
      throw const AuthException(
        'Conta criada. Confirme seu e-mail para entrar.',
      );
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(mapAuthError(e));
    }
  }

  Future<void> signOut() async {
    if (_client == null) return;
    await _client!.auth.signOut();
  }

  Future<void> deleteAccount() async {
    _ensureConfigured();
    try {
      await _client!.rpc('delete_own_account');
    } catch (e) {
      throw AuthException(mapAuthError(e));
    } finally {
      await signOut();
    }
  }

  String? get currentAccessToken =>
      _client?.auth.currentSession?.accessToken;
}
