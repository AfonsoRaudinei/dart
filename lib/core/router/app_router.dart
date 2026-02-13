import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../session/session_controller.dart';
import '../session/session_models.dart';
import '../../ui/components/app_shell.dart';
import '../../ui/screens/public_map_screen.dart';
import '../../ui/screens/private_map_screen.dart';
import '../../ui/screens/login_screen.dart';
import '../../modules/auth/pages/register_page.dart';
import '../../modules/auth/pages/recover_password_page.dart';
import '../../modules/agenda/presentation/pages/agenda_month_page.dart';
import '../../modules/agenda/presentation/pages/agenda_day_page.dart';
import '../../modules/agenda/presentation/pages/agenda_event_detail_page.dart';
import '../../ui/screens/publicacao_editor_screen.dart';
import '../../../modules/settings/presentation/screens/settings_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_list_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_form_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_detail_screen.dart';
import '../../../modules/consultoria/reports/presentation/screens/report_list_screen.dart';
import '../../../modules/consultoria/reports/presentation/screens/report_form_screen.dart';
import '../../../modules/consultoria/reports/presentation/screens/report_detail_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/farm_detail_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/field_detail_screen.dart';
import '../../../modules/feedback/presentation/screens/feedback_screen.dart';

import 'app_routes.dart';

part 'app_router.g.dart';

const String _runtimeEnvironment = String.fromEnvironment(
  'SOLOFORTE_ENV',
  defaultValue: 'dev',
);

bool get _isProdEnvironment =>
    kReleaseMode && _runtimeEnvironment.toLowerCase() == 'prod';

String get _environmentLabel =>
    _isProdEnvironment ? 'prod' : _runtimeEnvironment.toLowerCase();

bool get _shouldShowDashboardWarning => !_isProdEnvironment;

void _instrumentDashboardRedirect({
  required BuildContext context,
  required SessionState session,
  required GoRouterState state,
}) {
  final payload = <String, dynamic>{
    // ignore: deprecated_member_use_from_same_package
    'route_hit': AppRoutes.dashboard,
    'timestamp': DateTime.now().toIso8601String(),
    'environment': _environmentLabel,
    'userId': _resolveObfuscatedUserId(session),
    'source': _resolveRouteSource(state),
  }..removeWhere((_, value) => value == null);

  developer.log(jsonEncode(payload), name: 'Navigation.DeprecatedDashboard');

  if (_shouldShowDashboardWarning) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final messenger = _resolveMessenger(context);
      messenger?.showSnackBar(
        const SnackBar(
          content: Text(
            'Rota /dashboard será removida em breve. Redirecionando para /map.',
          ),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    });
  }
}

String? _resolveObfuscatedUserId(SessionState session) {
  if (session is SessionAuthenticated && session.token.isNotEmpty) {
    final hash = session.token.hashCode;
    return 'auth#$hash';
  }
  return null;
}

String _resolveRouteSource(GoRouterState state) {
  final qpSource = state.uri.queryParameters['source'];
  if (qpSource != null && qpSource.isNotEmpty) {
    return qpSource;
  }

  final extra = state.extra;
  if (extra is Map && extra['source'] is String) {
    final fromExtra = (extra['source'] as String).trim();
    if (fromExtra.isNotEmpty) {
      return fromExtra;
    }
  }

  if (state.uri.path.startsWith('http')) {
    return 'deep_link';
  }
  return 'internal';
}

ScaffoldMessengerState? _resolveMessenger(BuildContext context) {
  final messenger = ScaffoldMessenger.maybeOf(context);
  if (messenger != null) {
    return messenger;
  }

  final fallbackContext = GoRouter.of(
    context,
  ).routerDelegate.navigatorKey.currentContext;
  if (fallbackContext != null) {
    return ScaffoldMessenger.maybeOf(fallbackContext);
  }
  return null;
}

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
          path == AppRoutes.register ||
          path == AppRoutes.recoverPassword;

      if (!isAuth && !isPublicRoute) {
        return AppRoutes.publicMap;
      }

      // If auth, redirect login/register/public-map to map
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
            path: AppRoutes.register,
            builder: (_, __) => const RegisterPage(),
          ),
          GoRoute(
            path: AppRoutes.recoverPassword,
            builder: (_, __) => const RecoverPasswordPage(),
          ),
          // ════════════════════════════════════════════════════════════════
          // ROTA CANÔNICA: /map (MAP-FIRST)
          // ════════════════════════════════════════════════════════════════
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const PrivateMapScreen(),
            routes: [
              // Sub-rota de edição de Publicação (ADR-007)
              // Permanece L0 (AppRoutes.getLevel detecta /map/*)
              // Acesso exclusivo via CTA do preview contextual
              GoRoute(
                path: 'publicacao/edit',
                builder: (_, state) {
                  final id = state.uri.queryParameters['id'] ?? '';
                  return PublicacaoEditorScreen(publicacaoId: id);
                },
              ),
            ],
          ),
          // Redirect legado /dashboard -> /map com telemetria controlada
          GoRoute(
            // ignore: deprecated_member_use_from_same_package
            path: AppRoutes.dashboard,
            redirect: (context, state) {
              _instrumentDashboardRedirect(
                context: context,
                session: session,
                state: state,
              );
              return AppRoutes.map;
            },
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
            builder: (_, __) => const AgendaMonthPage(),
            routes: [
              GoRoute(
                path: 'day',
                builder: (_, state) {
                  final dateStr = state.uri.queryParameters['date'];
                  final date = dateStr != null
                      ? DateTime.parse(dateStr)
                      : DateTime.now();
                  return AgendaDayPage(selectedDate: date);
                },
              ),
              GoRoute(
                path: 'event/:id',
                builder: (_, state) => AgendaEventDetailPage(
                  eventId: state.pathParameters['id']!,
                ),
              ),
            ],
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
