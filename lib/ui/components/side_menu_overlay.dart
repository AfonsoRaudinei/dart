import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/state/side_menu_state.dart';
// ADR-012 — planos/
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
// ignore_for_file: unused_import

class SideMenuOverlay extends ConsumerWidget {
  const SideMenuOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(sideMenuOpenProvider);

    if (!isOpen) return const SizedBox.shrink();

    final drawerWidth = math.min(
      MediaQuery.of(context).size.width * 0.80,
      320.0,
    );

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            onTap: () {
              ref.read(sideMenuOpenProvider.notifier).state = false;
            },
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Container(
                  color: Colors.black.withValues(alpha: 0.4 * value),
                );
              },
            ),
          ),
        ),
        Positioned(
          top: 0,
          bottom: 0,
          right: 0,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            builder: (context, value, child) {
              return Transform.translate(
                offset: Offset((1 - value) * drawerWidth, 0),
                child: child,
              );
            },
            child: Drawer(
              width: drawerWidth,
              backgroundColor: Theme.of(context).colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildSectionLabel(context, "PRINCIPAL"),
                          const _MenuItem(
                            icon: Icons.calendar_today_outlined,
                            label: 'Agenda',
                            subtitle: 'Próximas visitas',
                            route: AppRoutes.agenda,
                          ),
                          const _MenuItem(
                            icon: Icons.people_outline_rounded,
                            label: 'Clientes',
                            subtitle: 'Gerenciar carteira',
                            route: AppRoutes.clients,
                          ),
                          const _MenuItem(
                            icon: Icons.analytics_outlined,
                            label: 'Relatórios',
                            subtitle: 'Análises e KPIs',
                            route: AppRoutes.reports,
                          ),
                          const _MenuItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Feedback',
                            route: AppRoutes.feedback,
                          ),

                          _buildSectionLabel(context, "FERRAMENTAS"),
                          const _MenuItem(
                            icon: Icons.wb_sunny_outlined,
                            label: 'Clima',
                            route: AppRoutes.clima,
                          ),
                          const _MenuItem(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'Carteira',
                            subtitle: 'Acompanhamento de mercado',
                            route: AppRoutes.carteira,
                          ),

                          _buildSectionLabel(context, "CONTA"),
                          const _MenuPlanoBadgeItem(),
                          Consumer(
                            builder: (context, ref, _) {
                              final planoAsync = ref.watch(planoAtivoProvider);
                              return planoAsync.when(
                                data: (plano) {
                                  if (plano == null ||
                                      plano.plano == PlanoTipo.ouro) {
                                    return const SizedBox.shrink();
                                  }
                                  return _MenuItem(
                                    icon: Icons.group_add_outlined,
                                    label: 'Indicações',
                                    subtitle: buildIndicacaoSubtitle(plano),
                                    route: AppRoutes.planosIndicacoes,
                                  );
                                },
                                loading: () => const SizedBox.shrink(),
                                error: (_, __) => const SizedBox.shrink(),
                              );
                            },
                          ),
                          const _MenuItem(
                            icon: Icons.settings_outlined,
                            label: 'Configurações',
                            route: AppRoutes.settings,
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.primary,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 20,
        right: 20,
        bottom: 24,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.onPrimary.withValues(alpha: 0.2),
            child: Text(
              "J",
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Consultor",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              Text(
                "João Silva",
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(BuildContext context, String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Text(
        "SoloForte v1.0.0",
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class _MenuItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String route;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.route,
  });

  void _closeAndNavigate(BuildContext context, WidgetRef ref, String route) {
    // Captura o construtor do router ANTES de fechar o menu.
    // Quando sideMenuOpenProvider → false, o SideMenuOverlay desaparece
    // e desmonta este widget imediatamente, tornando context.mounted false.
    final router = GoRouter.of(context);
    ref.read(sideMenuOpenProvider.notifier).state = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      router.go(route);
    });
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
      title: Text(label),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: Icon(
        Icons.chevron_right,
        color: Theme.of(context).colorScheme.outline,
      ),
      onTap: () => _closeAndNavigate(context, ref, route),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// ADR-012 — Funções e widgets auxiliares para planos/
// ─────────────────────────────────────────────────────────────

String buildIndicacaoSubtitle(UserPlan plano) {
  switch (plano.plano) {
    case PlanoTipo.bronze:
      return '? /5 para Prata';
    case PlanoTipo.prata:
      return '? /10 para Ouro';
    case PlanoTipo.ouro:
      return '';
  }
}

/// Item "Meu Plano" no SideMenu com estados diferenciados:
/// - loading: texto "Carregando..."
/// - null: "Sem plano · Assinar" (usuário free — não é erro)
/// - plano ativo: label + dias restantes
/// - erro de rede: "Sem conexão" com ícone wifi_off + retry ao tocar
/// - erro genérico: "Não foi possível carregar" + retry ao tocar
class _MenuPlanoBadgeItem extends ConsumerWidget {
  const _MenuPlanoBadgeItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planoAsync = ref.watch(planoAtivoProvider);

    return planoAsync.when(
      loading: () => _buildLoading(context),
      data: (plano) => _buildData(context, plano),
      error: (e, _) => _buildError(context, ref, e),
    );
  }

  Widget _buildLoading(BuildContext context) {
    return ListTile(
      leading: Icon(
        Icons.workspace_premium_rounded,
        color: Theme.of(context).colorScheme.outline,
      ),
      title: const Text('Meu Plano'),
      subtitle: Text(
        'Carregando...',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }

  Widget _buildData(BuildContext context, UserPlan? plano) {
    String subtitle;
    String targetRoute = AppRoutes.meuPlano;

    if (plano == null) {
      subtitle = 'Sem plano · Assinar';
      targetRoute = AppRoutes.planos;
    } else if (plano.expirado) {
      subtitle = 'Plano expirado · Renovar';
      targetRoute = AppRoutes.planos;
    } else if (plano.expiraEmBreve) {
      subtitle = '⚠️ Expira em ${plano.diasRestantes} dia(s)';
    } else {
      subtitle = '${plano.plano.label} · ${plano.diasRestantes} dias restantes';
    }

    return _MenuItem(
      icon: Icons.workspace_premium_rounded,
      label: 'Meu Plano',
      subtitle: subtitle,
      route: targetRoute,
    );
  }

  Widget _buildError(BuildContext context, WidgetRef ref, Object e) {
    // Verificação de erro de rede sem dart:io (web-safe)
    final eStr = e.toString().toLowerCase();
    final isNetwork =
        eStr.contains('socketexception') ||
        eStr.contains('failed host lookup') ||
        eStr.contains('network is unreachable') ||
        eStr.contains('connection refused') ||
        eStr.contains('no address associated') ||
        eStr.contains('networkrequestfailed');

    return ListTile(
      leading: Icon(
        isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('Meu Plano'),
      subtitle: Text(
        isNetwork ? 'Sem conexão' : 'Não foi possível carregar',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      trailing: Icon(Icons.refresh, color: Theme.of(context).colorScheme.error),
      onTap: () => ref.invalidate(planoAtivoProvider), // retry
    );
  }
}
