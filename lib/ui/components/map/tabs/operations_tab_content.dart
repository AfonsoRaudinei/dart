import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Tab 2 — OPERAÇÕES (Campo: Agenda, Ordens, Ocorrências)
class OperationsTabContent extends StatelessWidget {
  const OperationsTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Operações de Campo',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 16),
          _OperationTile(
            icon: SFIcons.calendar,
            title: 'Agenda',
            subtitle: 'Visitas e compromissos',
            onTap: () => context.go(AppRoutes.agenda),
          ),
          _OperationTile(
            icon: SFIcons.assignment,
            title: 'Ordens de Serviço',
            subtitle: 'Em breve — use a Agenda',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Ordens de Serviço em breve. Abrindo Agenda.',
                  ),
                ),
              );
              context.go(AppRoutes.agenda);
            },
          ),
          _OperationTile(
            icon: SFIcons.warning,
            title: 'Ocorrências',
            subtitle: 'Alertas e registros',
            onTap: () => context.go('${AppRoutes.map}?modo=ocorrencia'),
          ),
        ],
      ),
    );
  }
}

class _OperationTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _OperationTile({
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
                  color: PremiumTokens.brandGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: PremiumTokens.brandGreen, size: 24),
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
