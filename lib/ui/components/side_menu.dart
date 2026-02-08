/*
════════════════════════════════════════════════════════════════════
SIDE MENU — CONTRATO DE NAVEGAÇÃO (SOLOFORTE)
════════════════════════════════════════════════════════════════════

Este drawer é o MENU LATERAL do aplicativo.

REGRA CANÔNICA:
- O SideMenu SÓ existe no Dashboard/Mapa (L0)
- É controlado pelo SmartButton (ícone ☰)
- NÃO deve conter botão "Voltar" — navegação é responsabilidade do SmartButton
- Menu items navegam via context.go() (navegação declarativa)

Disponibilidade:
- AppShell define endDrawer: SideMenu() SOMENTE quando AppRoutes.canOpenSideMenu() = true
- Fora do Dashboard, o endDrawer é null = impossível abrir

⚠️ Qualquer alteração neste comportamento exige revisão arquitetural.
════════════════════════════════════════════════════════════════════
*/
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: SoloForteColors.grayLight,
      surfaceTintColor: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 60),

          // ═══════════════════════════════════════════════════════════════
          // HEADER DO MENU
          // ═══════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'SoloForte',
              style: SoloTextStyles.headingLarge.copyWith(
                color: SoloForteColors.greenIOS,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Menu Principal',
              style: SoloTextStyles.label.copyWith(
                color: SoloForteColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 30),
          const Divider(height: 1),
          const SizedBox(height: 10),

          // ═══════════════════════════════════════════════════════════════
          // ITENS DO MENU
          // Navegação via go() — declarativa, não depende de stack
          // ═══════════════════════════════════════════════════════════════
          _MenuItem(
            icon: Icons.people_outline,
            label: 'Clientes',
            onTap: () => _navigateTo(context, AppRoutes.clients),
          ),
          _MenuItem(
            icon: Icons.analytics,
            label: 'Relatórios',
            onTap: () => _navigateTo(context, AppRoutes.reports),
          ),
          _MenuItem(
            icon: Icons.calendar_today,
            label: 'Agenda',
            onTap: () => _navigateTo(context, AppRoutes.agenda),
          ),
          const Divider(height: 20, indent: 20, endIndent: 20),
          _MenuItem(
            icon: Icons.settings,
            label: 'Configurações',
            onTap: () => _navigateTo(context, AppRoutes.settings),
          ),
          _MenuItem(
            icon: Icons.chat_bubble_outline,
            label: 'Feedback',
            onTap: () => _navigateTo(context, AppRoutes.feedback),
          ),
        ],
      ),
    );
  }

  /// Navega para uma rota fechando o drawer primeiro.
  void _navigateTo(BuildContext context, String route) {
    // Fechar drawer antes de navegar para UX limpa
    Scaffold.of(context).closeEndDrawer();
    context.go(route);
  }
}

/// Item individual do menu lateral.
class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: SoloForteColors.textPrimary),
      title: Text(label, style: SoloTextStyles.body),
      trailing: const Icon(
        Icons.chevron_right,
        color: SoloForteColors.textTertiary,
        size: 20,
      ),
      onTap: onTap,
    );
  }
}
