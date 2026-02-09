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
import '../../ui/screens/misc_screens.dart'
    hide SettingsScreen, ClientesScreen, RelatoriosScreen;
import '../../../modules/settings/presentation/screens/settings_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_list_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_form_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_detail_screen.dart';
import '../../../modules/consultoria/reports/presentation/screens/report_list_screen.dart';
import '../../../modules/consultoria/reports/presentation/screens/report_form_screen.dart';
import '../../../modules/consultoria/reports/presentation/screens/report_detail_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/farm_detail_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/field_detail_screen.dart';

import 'app_routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // Watch session to rebuild router on auth change
  final session = ref.watch(sessionControllerProvider);

  return GoRouter(
    initialLocation: AppRoutes.publicMap,
    redirect: (context, state) {
      final isAuth = session is SessionAuthenticated;

      final path = state.uri.path;
      final isPublicRoute =
          path == AppRoutes.publicMap ||
          path == AppRoutes.login ||
          path == AppRoutes.signup;

      if (!isAuth && !isPublicRoute) {
        return AppRoutes.publicMap;
      }

      // If auth, redirect login/signup/public-map to map
      if (isAuth && isPublicRoute) {
        return AppRoutes.map;
      }

      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.publicMap,
            builder: (_, __) => const PublicMapScreen(),
          ),
          GoRoute(
            path: AppRoutes.login,
            builder: (_, __) => const LoginScreen(),
          ),
          GoRoute(
            path: AppRoutes.signup,
            builder: (_, __) => const SignupScreen(),
          ),
          // ════════════════════════════════════════════════════════════════
          // ROTA CANÔNICA: /map (MAP-FIRST)
          // ════════════════════════════════════════════════════════════════
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const PrivateMapScreen(),
          ),
          // Redirect legado /dashboard -> /map
          // ignore: deprecated_member_use_from_same_package
          GoRoute(
            path: AppRoutes.dashboard,
            redirect: (_, __) => AppRoutes.map,
          ),
          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (_, __) => const RelatoriosScreen(),
            routes: [
              GoRoute(
                path: 'novo',
                builder: (_, __) => const ReportFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ReportDetailScreen(reportId: state.pathParameters['id']!),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.agenda,
            builder: (_, __) => const AgendaScreen(),
          ),
          // Redirect mantido temporariamente por compatibilidade com Side Menu legado.
          GoRoute(path: '/clientes', redirect: (_, __) => AppRoutes.clients),
          GoRoute(
            path: AppRoutes.clients,
            builder: (_, __) => const ClientListScreen(),
            routes: [
              GoRoute(
                path: 'novo',
                builder: (_, __) => const ClientFormScreen(),
              ),
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    ClientDetailScreen(clientId: state.pathParameters['id']!),
                routes: [
                  GoRoute(
                    path: 'fazendas/:farmId',
                    builder: (_, state) => FarmDetailScreen(
                      clientId: state.pathParameters['id']!,
                      farmId: state.pathParameters['farmId']!,
                    ),
                    routes: [
                      GoRoute(
                        path: 'talhoes/:fieldId',
                        builder: (_, state) => FieldDetailScreen(
                          farmId: state.pathParameters['farmId']!,
                          fieldId: state.pathParameters['fieldId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.feedback,
            builder: (_, __) => const FeedbackScreen(),
          ),
        ],
      ),
    ],
  );
}
