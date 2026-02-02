import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../session/session_controller.dart';
import '../session/session_models.dart';
import '../../ui/components/app_shell.dart';
import '../../ui/screens/public_map_screen.dart';
import '../../ui/screens/private_map_screen.dart';
import '../../ui/screens/login_screen.dart';
import '../../ui/screens/signup_screen.dart';
import '../../ui/screens/misc_screens.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Watch session to rebuild router on auth change
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: '/public-map',
    redirect: (context, state) {
      final isAuth = session is SessionAuthenticated;

      final path = state.uri.path;
      final isPublicRoute =
          path == '/public-map' || path == '/login' || path == '/signup';

      if (!isAuth && !isPublicRoute) {
        return '/public-map';
      }

      // If auth, redirect login/signup/public-map to /map
      // Wait, "Map" is the hub.
      if (isAuth && isPublicRoute) {
        return '/map';
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/public-map',
            builder: (_, __) => const PublicMapScreen(),
          ),
          GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
          GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
          GoRoute(path: '/map', builder: (_, __) => const PrivateMapScreen()),
          GoRoute(
            path: '/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/relatorios',
            builder: (_, __) => const RelatoriosScreen(),
          ),
          GoRoute(path: '/agenda', builder: (_, __) => const AgendaScreen()),
          GoRoute(
            path: '/clientes',
            builder: (_, __) => const ClientesScreen(),
          ),
          GoRoute(
            path: '/feedback',
            builder: (_, __) => const FeedbackScreen(),
          ),
        ],
      ),
    ],
  );
}
