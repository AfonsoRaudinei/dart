import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

/// Tab 3 — GESTÃO (Administrativo: Clientes, Performance, Relatórios)
class ManagementTabContent extends StatelessWidget {
  const ManagementTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gestão',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _ManagementTile(
            icon: SFIcons.people,
            title: 'Clientes',
            subtitle: 'Gestão de propriedades',
            onTap: () => context.go(AppRoutes.clients),
          ),
          _ManagementTile(
            icon: SFIcons.barChart,
            title: 'Performance',
            subtitle: 'Métricas na Agenda',
            onTap: () => context.go(AppRoutes.agenda),
          ),
          _ManagementTile(
            icon: SFIcons.description,
            title: 'Relatórios',
            subtitle: 'Documentos e análises',
            onTap: () => context.go(AppRoutes.reports),
          ),
        ],
      ),
    );
  }
}

class _ManagementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ManagementTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.orange.shade700, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 13, color: secondary),
                    ),
                  ],
                ),
              ),
              Icon(SFIcons.chevronRight, color: secondary),
            ],
          ),
        ),
      ),
    );
  }
}
