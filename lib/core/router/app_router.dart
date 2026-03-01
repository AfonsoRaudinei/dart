import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'router_notifier.dart';
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
import '../../../modules/consultoria/relatorios/presentation/relatorios_page.dart';
import '../../../modules/consultoria/reports/presentation/screens/report_form_screen.dart';
import '../../../modules/consultoria/reports/presentation/screens/report_detail_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/farm_detail_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/field_detail_screen.dart';
import '../../../modules/feedback/presentation/screens/feedback_screen.dart';
// ADR-012 — Módulo planos/
import '../../../modules/planos/presentation/screens/planos_screen.dart';
import '../../../modules/planos/presentation/screens/pagamento_screen.dart';
import '../../../modules/planos/presentation/screens/confirmacao_screen.dart';
import '../../../modules/planos/presentation/screens/meu_plano_screen.dart';
import '../../../modules/planos/presentation/screens/indicacoes_screen.dart';

import 'app_routes.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  // RouterNotifier lido com ref.read (não ref.watch) para garantir que
  // o GoRouter seja instanciado uma única vez e nunca recriado.
  // Mudanças de auth disparam notifyListeners() via refreshListenable
  // → GoRouter re-avalia apenas o redirect, sem destruir a navigation stack.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: AppRoutes.publicMap,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = notifier.isAuthenticated;

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
                builder: (_, state) =>
                    AgendaEventDetailPage(eventId: state.pathParameters['id']!),
              ),
            ],
          ),

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
          // ════════════════════════════════════════════════════════════════
          // MÓDULO PLANOS — ADR-012
          // ════════════════════════════════════════════════════════════════
          GoRoute(
            path: AppRoutes.planos,
            builder: (_, __) => const PlanosScreen(),
          ),
          GoRoute(
            path: AppRoutes.meuPlano,
            builder: (_, __) => const MeuPlanoScreen(),
          ),
          GoRoute(
            path: AppRoutes.planosPagamento,
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final plano = extra?['plano'] as String? ?? 'bronze';
              return PagamentoScreen(plano: plano);
            },
          ),
          GoRoute(
            path: AppRoutes.planosConfirmacao,
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final plano = extra?['plano'] as String? ?? 'bronze';
              final checkoutUrl = extra?['checkoutUrl'] as String?;
              return ConfirmacaoScreen(plano: plano, checkoutUrl: checkoutUrl);
            },
          ),
          GoRoute(
            path: AppRoutes.planosIndicacoes,
            builder: (_, __) => const IndicacoesScreen(),
          ),
        ],
      ),
    ],
  );
}
