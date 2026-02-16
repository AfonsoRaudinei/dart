import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';
import '../../../theme/soloforte_theme.dart';

/// Tab 2 — OPERAÇÕES (Campo: Visitas, Ordens, Ocorrências)
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
            style: SoloTextStyles.headingMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          _OperationTile(
            icon: SFIcons.calendar,
            title: 'Agenda',
            subtitle: 'Visitas e compromissos',
            badge: '3',
            onTap: () {
              // TODO: Navegar para agenda
            },
          ),
          _OperationTile(
            icon: SFIcons.assignment,
            title: 'Ordens de Serviço',
            subtitle: 'Tarefas e execuções',
            onTap: () {
              // TODO: Navegar para ordens
            },
          ),
          _OperationTile(
            icon: SFIcons.warning,
            title: 'Ocorrências',
            subtitle: 'Alertas e registros',
            onTap: () {
              // TODO: Navegar para ocorrências
            },
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
  final String? badge;
  final VoidCallback onTap;

  const _OperationTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
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
                  color: SoloForteColors.greenIOS.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: SoloForteColors.greenIOS, size: 24),
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
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: SoloForteColors.greenIOS,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const SizedBox(width: 8),
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
