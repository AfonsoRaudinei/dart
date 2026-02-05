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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'SoloForte',
              style: SoloTextStyles.headingLarge.copyWith(
                color: SoloForteColors.greenIOS,
              ),
            ),
          ),
          const SizedBox(height: 40),
          _MenuItem(
            icon: Icons.settings,
            label: 'Configurações',
            onTap: () => context.go(AppRoutes.settings),
          ),
          _MenuItem(
            icon: Icons.analytics,
            label: 'Relatórios',
            onTap: () => context.go(AppRoutes.reports),
          ),
          _MenuItem(
            icon: Icons.chat_bubble_outline,
            label: 'Feedback',
            onTap: () => context.go(AppRoutes.feedback),
          ),
          _MenuItem(
            icon: Icons.calendar_today,
            label: 'Agenda',
            onTap: () => context.go(AppRoutes.agenda),
          ),
          _MenuItem(
            icon: Icons.people_outline,
            label: 'Clientes',
            onTap: () => context.go(AppRoutes.clients),
          ),
        ],
      ),
    );
  }
}

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
      onTap: () {
        // If drawer is open, we can close it or just navigate.
        // Drawer auto closes usually if replacing route, but context.go might keep it if shell.
        // Better to close it explicitly.
        Scaffold.of(context).closeEndDrawer();
        onTap();
      },
    );
  }
}
