import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../auth/auth_service.dart';
import 'session_models.dart';
import 'session_storage.dart';

part 'session_controller.g.dart';

@Riverpod(keepAlive: true)
class SessionController extends _$SessionController {
  @override
  SessionState build() {
    // Initial state check
    // We can't use async in build easily for sync state unless we return AsyncValue usually.
    // But typical riverpod pattern for auth is AsyncValue<SessionState> or handling loading.
    // However, prompt mandated states: unknown, public, authenticated.
    // We will start 'unknown' and then check storage.

    _initialize();
    return const SessionUnknown();
  }

  Future<void> _initialize() async {
    // Artificial delay to show splash or check usage
    await Future.delayed(Duration.zero);

    final storage = ref.read(sessionStorageProvider);
    final token = storage.getToken();

    if (token != null) {
      state = SessionAuthenticated(token);
    } else {
      state = const SessionPublic();
    }
  }

  Future<void> login(String email, String password) async {
    try {
      final authService = AuthService(); // We could inject this too
      final token = await authService.login(email, password);

      final storage = ref.read(sessionStorageProvider);
      await storage.saveToken(token);

      state = SessionAuthenticated(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signup(String name, String email, String password) async {
    try {
      final authService = AuthService();
      final token = await authService.signup(name, email, password);

      final storage = ref.read(sessionStorageProvider);
      await storage.saveToken(token);

      state = SessionAuthenticated(token);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    final storage = ref.read(sessionStorageProvider);
    await storage.clearToken();
    state = const SessionPublic();
  }
}
