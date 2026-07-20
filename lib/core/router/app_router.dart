import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'router_notifier.dart';
import '../access/app_access.dart';
import '../../core/session/session_controller.dart';
import '../../core/session/session_models.dart';
import '../../ui/components/app_shell.dart';
import '../../ui/screens/public_map_screen.dart';
import '../../ui/screens/private_map_bootstrap_screen.dart';
import '../../ui/screens/login_screen.dart';
import '../../modules/auth/pages/register_page.dart';
import '../../modules/auth/pages/recover_password_page.dart';
import '../../modules/auth/pages/reset_password_page.dart';
import '../../modules/agenda/presentation/pages/agenda_month_page.dart';
import '../../modules/agenda/presentation/pages/agenda_day_page.dart';
import '../../modules/agenda/presentation/pages/agenda_event_detail_page.dart';
import '../../modules/carteira/presentation/screens/carteira_cliente_screen.dart';
import '../../modules/carteira/presentation/screens/carteira_screen.dart';
import '../../ui/screens/publicacao_editor_screen.dart';
import '../../modules/settings/presentation/providers/user_profile_provider.dart';
import '../../../modules/settings/presentation/screens/settings_screen.dart';
import '../../../modules/settings/presentation/screens/edit_profile_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_list_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_form_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/client_detail_screen.dart';
import '../../../modules/consultoria/relatorios/presentation/relatorios_page.dart';
import '../../../modules/consultoria/relatorios/presentation/relatorio_detail_screen.dart';
import '../../../modules/consultoria/relatorios/presentation/relatorio_form_screen.dart';
// import '../../../modules/consultoria/reports/presentation/screens/report_detail_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/farm_detail_screen.dart';
import '../../../modules/consultoria/clients/presentation/screens/field_detail_screen.dart';
import '../../../modules/feedback/presentation/screens/feedback_screen.dart';
import '../../../modules/produtor/presentation/screens/producer_property_screen.dart';
import '../../modules/clima/presentation/screens/clima_screen.dart';
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
  final profileAsync = ref.watch(currentUserProfileProvider);

  return GoRouter(
    initialLocation: AppRoutes.publicMap,
    refreshListenable: notifier,
    redirect: (context, state) {
      // 🛡 IPA-109: aguarda bootstrap de autenticação concluir antes de
      // redirecionar. Enquanto _isInitializing==true o Supabase ainda pode
      // estar restaurando a sessão do storage local. Sem este guard o router
      // renderizava PublicMapScreen ou /map prematuramente, causando frame
      // branco/preto enquanto o SessionUnknown ainda estava ativo.
      if (notifier.isInitializing) {
        return AppRoutes.publicMap; // seguro: já é a initialLocation
      }

      final session = ref.read(sessionControllerProvider);
      final isAuth = notifier.isAuthenticated;
      final isRecovery = session is SessionPasswordRecovery;

      final path = state.uri.path;
      final isPublicRoute =
          path == AppRoutes.publicMap ||
          path == AppRoutes.login ||
          path == AppRoutes.register ||
          path == AppRoutes.recoverPassword ||
          path == AppRoutes.resetPassword;

      // Sem sessão: redirecionar rotas privadas para mapa público
      if (!isAuth && !isPublicRoute) {
        return AppRoutes.publicMap;
      }

      // Recovery: forçar /reset-password em qualquer outra rota
      if (isRecovery && path != AppRoutes.resetPassword) {
        return AppRoutes.resetPassword;
      }

      if (isAuth && !isRecovery) {
        if (profileAsync.isLoading || profileAsync.hasError) {
          return null;
        }

        final role = profileAsync.asData?.value?.role;
        if (!AppAccess.canAccessPath(role, path)) {
          return AppRoutes.map;
        }

        if (isPublicRoute) {
          return AppRoutes.map;
        }
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
          GoRoute(
            path: AppRoutes.resetPassword,
            builder: (_, __) => const ResetPasswordPage(),
          ),
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const PrivateMapBootstrapScreen(),
          ),

          GoRoute(
            path: AppRoutes.settings,
            builder: (_, __) => const SettingsScreen(),
          ),
          GoRoute(
            path: AppRoutes.settingsEditProfile,
            builder: (_, __) => const EditProfileScreen(),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (_, __) => const RelatoriosScreen(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) {
                  final id = state.pathParameters['id']!;
                  return RelatorioDetailScreen(relatorioId: id);
                },
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return RelatorioFormScreen(relatorioId: id);
                    },
                  ),
                ],
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
                  final parsedDate = dateStr != null
                      ? DateTime.tryParse(dateStr)
                      : null;
                  final date = parsedDate ?? DateTime.now();
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
            path: AppRoutes.carteira,
            builder: (_, __) => const CarteiraScreen(),
            routes: [
              GoRoute(
                path: 'cliente/:clienteId',
                builder: (_, state) => CarteiraClienteScreen(
                  clienteId: state.pathParameters['clienteId']!,
                ),
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
          GoRoute(
            path: AppRoutes.clima,
            builder: (_, __) => const ClimaScreen(),
          ),
          GoRoute(
            path: AppRoutes.producerProperty,
            builder: (_, __) => const ProducerPropertyScreen(),
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
          // ════════════════════════════════════════════════════════════════
          // PUBLICAÇÕES — ADR-007
          // Rota top-level fora do namespace /map (contrato Map-First)
          // ════════════════════════════════════════════════════════════════
          GoRoute(
            path: '/publicacoes/edit',
            builder: (_, state) {
              final id = state.uri.queryParameters['id'] ?? '';
              return PublicacaoEditorScreen(publicacaoId: id);
            },
          ),
        ],
      ),
    ],
  );
}
