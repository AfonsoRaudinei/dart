/*
════════════════════════════════════════════════════════════════════
SIDE MENU OVERLAY — MENU LATERAL COMO OVERLAY
════════════════════════════════════════════════════════════════════

Implementação do SideMenu como overlay controlado manualmente.
NÃO depende de Scaffold Drawer/EndDrawer.

REGRAS:
- Abre/fecha via estado global (sideMenuOpenProvider)
- Sempre fica abaixo do SmartButton no z-index
- Animação suave de entrada/saída
- Tap fora fecha o menu
════════════════════════════════════════════════════════════════════
*/

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/state/side_menu_state.dart';

class SideMenuOverlay extends ConsumerWidget {
  const SideMenuOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch with specialized provider if available, or just use boolean
    // Assuming sideMenuOpenProvider is a StateProvider<bool> based on context
    // If it's not imported or defined, we might need to fix imports.
    // Based on previous file content, it was imported from 'package:soloforte_app/core/state/side_menu_state.dart'

    final isOpen = ref.watch(sideMenuOpenProvider);

    // Early return with empty container to avoid layout issues
    if (!isOpen) return const SizedBox.shrink();

    return Stack(
      children: [
        // Backdrop with Fade Transition
        // We can use a simplified approach since we are inside a provider rebuild
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

        // Menu Content
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
                offset: Offset((1 - value) * 320, 0), // Slide from right
                child: child,
              );
            },
            child: Container(
              width: 320,
              decoration: BoxDecoration(
                color: SoloForteColors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  bottomLeft: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 30,
                    offset: const Offset(-8, 0),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: SoloForteColors.greenIOS.withValues(
                                    alpha: 0.1,
                                  ),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: SoloForteColors.greenIOS,
                                    width: 1.5,
                                  ),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    color: SoloForteColors.greenIOS,
                                    size: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Consultor',
                                    style: SoloTextStyles.label.copyWith(
                                      color: SoloForteColors.textSecondary,
                                    ),
                                  ),
                                  Text(
                                    'João Silva',
                                    style: SoloTextStyles.headingMedium
                                        .copyWith(fontSize: 18),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Divider(
                      height: 1,
                      color: SoloForteColors.borderLight,
                    ),
                    const SizedBox(height: 16),

                    // Menu Items
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        children: [
                          _MenuItem(
                            icon: Icons.calendar_today_rounded,
                            label: 'Agenda',
                            subtitle: 'Próximas visitas',
                            onTap: () => _closeAndNavigate(
                              context,
                              ref,
                              AppRoutes.agenda,
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.people_outline_rounded,
                            label: 'Clientes',
                            subtitle: 'Gerenciar carteira',
                            onTap: () => _closeAndNavigate(
                              context,
                              ref,
                              AppRoutes.clients,
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.analytics_outlined,
                            label: 'Relatórios',
                            subtitle: 'Análises e KPIs',
                            onTap: () => _closeAndNavigate(
                              context,
                              ref,
                              AppRoutes.reports,
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.chat_bubble_outline_rounded,
                            label: 'Feedback',
                            onTap: () => _closeAndNavigate(
                              context,
                              ref,
                              AppRoutes.feedback,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(color: SoloForteColors.borderLight),
                          ),
                          _MenuItem(
                            icon: Icons.settings_outlined,
                            label: 'Configurações',
                            onTap: () => _closeAndNavigate(
                              context,
                              ref,
                              AppRoutes.settings,
                            ),
                          ),
                          _MenuItem(
                            icon: Icons.logout_rounded,
                            label: 'Sair',
                            isDestructive: true,
                            onTap: () {
                              ref.read(sideMenuOpenProvider.notifier).state =
                                  false;
                              // Implement logout logic here later
                              context.go(AppRoutes.login);
                            },
                          ),
                        ],
                      ),
                    ),

                    // Footer
                    Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        'SoloForte v1.0.0',
                        textAlign: TextAlign.center,
                        style: SoloTextStyles.label.copyWith(
                          color: SoloForteColors.textTertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _closeAndNavigate(BuildContext context, WidgetRef ref, String route) {
    ref.read(sideMenuOpenProvider.notifier).state = false;
    Future.delayed(const Duration(milliseconds: 250), () {
      if (context.mounted) {
        context.go(route);
      }
    });
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? SoloForteColors.error
        : SoloForteColors.textPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: isDestructive
              ? SoloForteColors.error.withValues(alpha: 0.1)
              : SoloForteColors.greenIOS.withValues(alpha: 0.1),
          highlightColor: isDestructive
              ? SoloForteColors.error.withValues(alpha: 0.05)
              : SoloForteColors.greenIOS.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? SoloForteColors.bgError
                        : SoloForteColors.grayLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isDestructive
                        ? SoloForteColors.error
                        : SoloForteColors.greenIOS,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: SoloTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: color,
                          fontSize: 15,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: SoloTextStyles.label.copyWith(
                            color: SoloForteColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: SoloForteColors.textTertiary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
