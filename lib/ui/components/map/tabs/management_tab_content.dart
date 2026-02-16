import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';
import '../../../theme/soloforte_theme.dart';

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
            style: SoloTextStyles.headingMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          _ManagementTile(
            icon: SFIcons.people,
            title: 'Clientes',
            subtitle: 'Gestão de propriedades',
            onTap: () {
              // TODO: Navegar para clientes
            },
          ),
          _ManagementTile(
            icon: SFIcons.barChart,
            title: 'Performance',
            subtitle: 'Métricas e indicadores',
            onTap: () {
              // TODO: Navegar para performance
            },
          ),
          _ManagementTile(
            icon: SFIcons.description,
            title: 'Relatórios',
            subtitle: 'Documentos e análises',
            onTap: () {
              // TODO: Navegar para relatórios
            },
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                SFIcons.chevronRight,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
