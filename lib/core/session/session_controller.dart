import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../auth/auth_exception.dart';
import '../auth/auth_service.dart';
import '../config/app_config.dart';
import 'session_models.dart';
import 'session_storage.dart';

part 'session_controller.g.dart';

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  AuthService? _authService;

  AuthService get authService => _authService ??= AuthService();

  @override
  SessionState build() {
    _initialize();
    return const SessionUnknown();
  }

  Future<void> _initialize() async {
    final storage = ref.read(sessionStorageProvider);
    if (!storage.isInitialized) {
      await storage.init();
    }

    if (AppConfig.hasSupabaseConfig) {
      final supabaseSession = Supabase.instance.client.auth.currentSession;
      if (supabaseSession != null) {
        await storage.saveToken(supabaseSession.accessToken);
        state = SessionAuthenticated(supabaseSession.accessToken);
        return;
      }
    }

    final token = storage.getToken();
    if (token != null && token.isNotEmpty) {
      state = SessionAuthenticated(token);
    } else {
      state = const SessionPublic();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final token = await authService.login(email, password);
      final storage = ref.read(sessionStorageProvider);
      await storage.saveToken(token);
      state = SessionAuthenticated(token);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(mapAuthError(e));
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      final token = await authService.signup(name, email, password);
      final storage = ref.read(sessionStorageProvider);
      await storage.saveToken(token);
      state = SessionAuthenticated(token);
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(mapAuthError(e));
    }
  }

  Future<void> logout() async {
    await authService.signOut();
    final storage = ref.read(sessionStorageProvider);
    await storage.clearToken();
    state = const SessionPublic();
  }

  Future<void> deleteAccount() async {
    await authService.deleteAccount();
    final storage = ref.read(sessionStorageProvider);
    await storage.clearToken();
    state = const SessionPublic();
  }
}
