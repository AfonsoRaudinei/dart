import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/sync_service.dart';
import 'package:soloforte_app/core/state/side_menu_state.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

const _menuGreen = Color(0xFF34C759);
const _deepGreen = Color(0xFF1E3A2F);
const _softGreen = Color(0xFFF1FAF4);
const _cardBorder = Color(0xFFE5E5E7);
const _appBuildVersion = String.fromEnvironment(
  'APP_VERSION',
  defaultValue: '1.1.0+115',
);

class SideMenuOverlay extends ConsumerWidget {
  const SideMenuOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOpen = ref.watch(sideMenuOpenProvider);

    if (!isOpen) return const SizedBox.shrink();

    final drawerWidth = math.min(
      MediaQuery.of(context).size.width * 0.88,
      390.0,
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
              duration: const Duration(milliseconds: 260),
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
            duration: const Duration(milliseconds: 260),
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
                  topLeft: Radius.circular(22),
                  bottomLeft: Radius.circular(22),
                ),
              ),
              child: Column(
                children: [
                  _buildHeader(context, ref),
                  const Expanded(
                    child: SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(14, 14, 14, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _SectionTitle('Menu principal'),
                          SizedBox(height: 6),
                          _MenuPanel(
                            children: [
                              _MenuItem(
                                icon: Icons.calendar_today_outlined,
                                label: 'Agenda',
                                subtitle: 'Próximas visitas',
                                route: AppRoutes.agenda,
                              ),
                              _MenuItem(
                                icon: Icons.people_outline_rounded,
                                label: 'Clientes',
                                subtitle: 'Gerenciar carteira',
                                route: AppRoutes.clients,
                              ),
                              _MenuItem(
                                icon: Icons.analytics_outlined,
                                label: 'Relatórios',
                                subtitle: 'Análises e KPIs',
                                route: AppRoutes.reports,
                              ),
                              _MenuItem(
                                icon: Icons.chat_bubble_outline_rounded,
                                label: 'Feedback',
                                subtitle: 'Envie sua opinião',
                                route: AppRoutes.feedback,
                              ),
                              _MenuItem(
                                icon: Icons.wb_sunny_outlined,
                                label: 'Clima',
                                subtitle: 'Previsão para o campo',
                                route: AppRoutes.clima,
                              ),
                              _MenuItem(
                                icon: Icons.account_balance_wallet_outlined,
                                label: 'Carteira',
                                subtitle: 'Acompanhamento de mercado',
                                route: AppRoutes.carteira,
                              ),
                              _MenuItem(
                                icon: Icons.settings_outlined,
                                label: 'Configurações',
                                subtitle: 'Ajustes do aplicativo',
                                route: AppRoutes.settings,
                                showDivider: false,
                              ),
                            ],
                          ),
                          SizedBox(height: 18),
                          _SectionTitle('Conta'),
                          SizedBox(height: 6),
                          _MenuPanel(
                            children: [
                              _MenuPlanoBadgeItem(),
                              _ManualSyncItem(),
                            ],
                          ),
                          SizedBox(height: 18),
                          _SectionTitle('Acesso rápido'),
                          SizedBox(height: 8),
                          _QuickActionsGrid(),
                          SizedBox(height: 18),
                          _SectionTitle('Resumo de hoje'),
                          SizedBox(height: 8),
                          _DailySummary(),
                          SizedBox(height: 16),
                          _MotivationalCard(),
                        ],
                      ),
                    ),
                  ),
                  _buildFooter(context, ref),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(currentUserProfileProvider);
    final localProfile = ref.watch(profileProvider);

    final profile = userProfileAsync.asData?.value;
    final displayName = (profile?.fullName?.trim().isNotEmpty ?? false)
        ? profile!.fullName!
        : 'Usuário';
    final displayRole = _formatRole(profile?.role ?? '');
    final displayEmail = profile?.email.trim() ?? '';

    ImageProvider<Object>? avatarImage;
    final localPath = localProfile.imagePath;
    if (localPath != null && File(localPath).existsSync()) {
      avatarImage = FileImage(File(localPath));
    } else if ((profile?.photoUrl?.trim().isNotEmpty ?? false)) {
      avatarImage = NetworkImage(profile!.photoUrl!);
    }

    final initial = displayName.trim().isNotEmpty
        ? displayName.trim().characters.first.toUpperCase()
        : 'U';
    final safeTop = MediaQuery.of(context).padding.top;

    return SizedBox(
      height: safeTop + 136,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(22)),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 9, sigmaY: 9),
              child: Image.asset(
                'assets/images/logo.jpeg',
                fit: BoxFit.cover,
                color: _deepGreen.withValues(alpha: 0.32),
                colorBlendMode: BlendMode.multiply,
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xF21E3A2F), Color(0xD934C759)],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(18, safeTop + 16, 18, 14),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.76),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.16),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      backgroundImage: avatarImage,
                      child: avatarImage == null
                          ? Text(
                              initial,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayRole,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.82),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (displayEmail.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            displayEmail,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.82),
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context, WidgetRef ref) {
    final connectivity = ref.watch(connectivityStateProvider);
    final isOnline = connectivity.asData?.value == true;

    return Container(
      padding: EdgeInsets.fromLTRB(
        14,
        10,
        14,
        MediaQuery.of(context).padding.bottom + 10,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: const Border(top: BorderSide(color: _cardBorder, width: 0.7)),
      ),
      child: Row(
        children: [
          Image.asset(
            'assets/images/soloforte_logo.png',
            width: 30,
            height: 30,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SoloForte',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Inteligência Agronômica',
                  style: TextStyle(fontSize: 9, color: Color(0xFF8E8E93)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Versão $_appBuildVersion',
                style: TextStyle(fontSize: 9, color: Color(0xFF8E8E93)),
              ),
              const SizedBox(height: 3),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline
                          ? const Color(0xFF34C759)
                          : const Color(0xFF8E8E93),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isOnline ? 'Online' : 'Offline',
                    style: const TextStyle(
                      fontSize: 9,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    final normalized = role.trim().toLowerCase();
    return switch (normalized) {
      'consultor' => 'Consultor',
      'produtor' => 'Produtor',
      '' || 'não informado' => 'Conta',
      _ => role,
    };
  }
}

class _SectionTitle extends StatelessWidget {
  final String label;

  const _SectionTitle(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: Theme.of(context).colorScheme.outline,
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.1,
      ),
    );
  }
}

class _MenuPanel extends StatelessWidget {
  final List<Widget> children;

  const _MenuPanel({required this.children});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(children: children),
    );
  }
}

class _MenuItem extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final String route;
  final bool showDivider;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.route,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () => _closeAndNavigate(context, ref, route),
      child: Column(
        children: [
          SizedBox(
            height: 57,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _softGreen,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: _menuGreen, size: 18),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.outlineVariant,
                  size: 20,
                ),
                const SizedBox(width: 9),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, thickness: 0.6, indent: 55),
        ],
      ),
    );
  }
}

String buildIndicacaoSubtitle(UserPlan plano, int indicacoesValidadas) {
  switch (plano.plano) {
    case PlanoTipo.bronze:
      return '$indicacoesValidadas/5 para Prata';
    case PlanoTipo.prata:
      return '$indicacoesValidadas/10 para Ouro';
    case PlanoTipo.ouro:
      return '';
  }
}

class _MenuPlanoBadgeItem extends ConsumerWidget {
  const _MenuPlanoBadgeItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planoAsync = ref.watch(planoAtivoProvider);

    return planoAsync.when(
      loading: () => const _AccountActionItem(
        icon: Icons.workspace_premium_rounded,
        label: 'Meu Plano',
        subtitle: 'Carregando...',
      ),
      data: (plano) => _buildData(plano),
      error: (error, _) => _buildError(context, ref, error),
    );
  }

  Widget _buildData(UserPlan? plano) {
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

  Widget _buildError(BuildContext context, WidgetRef ref, Object error) {
    final errorText = error.toString().toLowerCase();
    final isNetwork =
        errorText.contains('socketexception') ||
        errorText.contains('failed host lookup') ||
        errorText.contains('network is unreachable') ||
        errorText.contains('connection refused') ||
        errorText.contains('no address associated') ||
        errorText.contains('networkrequestfailed');

    return _AccountActionItem(
      icon: isNetwork ? Icons.wifi_off_outlined : Icons.error_outline,
      label: 'Meu Plano',
      subtitle: isNetwork ? 'Sem conexão' : 'Não foi possível carregar',
      iconColor: Theme.of(context).colorScheme.error,
      trailingIcon: Icons.refresh,
      onTap: () => ref.invalidate(planoAtivoProvider),
    );
  }
}

class _ManualSyncItem extends ConsumerWidget {
  const _ManualSyncItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final syncState = ref.watch(manualSyncProvider);

    return _AccountActionItem(
      icon: Icons.sync_outlined,
      label: 'Sincronizar agora',
      isLoading: syncState.isLoading,
      showDivider: false,
      onTap: syncState.isLoading
          ? null
          : () {
              ref.invalidate(manualSyncProvider);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sincronização iniciada'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
    );
  }
}

class _AccountActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? iconColor;
  final IconData? trailingIcon;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool showDivider;

  const _AccountActionItem({
    required this.icon,
    required this.label,
    this.subtitle,
    this.iconColor,
    this.trailingIcon,
    this.onTap,
    this.isLoading = false,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? _menuGreen;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            height: 57,
            child: Row(
              children: [
                const SizedBox(width: 12),
                Container(
                  width: 32,
                  height: 32,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: effectiveIconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: isLoading
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: effectiveIconColor,
                            strokeWidth: 2,
                          ),
                        )
                      : Icon(icon, color: effectiveIconColor, size: 18),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.outline,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
                if (trailingIcon != null)
                  Icon(trailingIcon, color: effectiveIconColor, size: 19),
                const SizedBox(width: 10),
              ],
            ),
          ),
          if (showDivider) const Divider(height: 1, thickness: 0.6, indent: 55),
        ],
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        SizedBox(
          height: 84,
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.event_available_outlined,
                  label: 'Nova Visita',
                  route: '${AppRoutes.agenda}?novoEvento=true',
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.person_add_alt_1_outlined,
                  label: 'Novo Cliente',
                  route: AppRoutes.clientNew,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8),
        SizedBox(
          height: 84,
          child: Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.insert_chart_outlined_rounded,
                  label: 'Ver Relatórios',
                  route: AppRoutes.reports,
                ),
              ),
              SizedBox(width: 8),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.warning_amber_rounded,
                  label: 'Nova Ocorrência',
                  route: '${AppRoutes.map}?modo=ocorrencia',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickActionCard extends ConsumerWidget {
  final IconData icon;
  final String label;
  final String route;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.route,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _cardBorder),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _closeAndNavigate(context, ref, route),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _menuGreen, size: 21),
              const Spacer(),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailySummary extends StatelessWidget {
  const _DailySummary();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          _SummaryMetric(icon: Icons.calendar_today_outlined, label: 'Visitas'),
          _SummaryMetric(icon: Icons.people_outline_rounded, label: 'Clientes'),
          _SummaryMetric(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Carteira',
          ),
          _SummaryMetric(icon: Icons.analytics_outlined, label: 'Relatórios'),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SummaryMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: _menuGreen),
          const SizedBox(height: 2),
          const Text(
            '--',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 9, color: Color(0xFF6B7280)),
          ),
        ],
      ),
    );
  }
}

class _MotivationalCard extends StatelessWidget {
  const _MotivationalCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxHeight: 90),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: _softGreen,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.eco_outlined, color: _menuGreen, size: 24),
          SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Foco no que importa',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 3),
                Flexible(
                  child: Text(
                    'Acompanhe suas visitas, clientes e resultados em tempo real.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

void _closeAndNavigate(BuildContext context, WidgetRef ref, String route) {
  final router = GoRouter.of(context);
  ref.read(sideMenuOpenProvider.notifier).state = false;
  WidgetsBinding.instance.addPostFrameCallback((_) {
    router.go(route);
  });
}
