import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';
import '../../../theme/soloforte_theme.dart';

/// Tab 4 — PERFIL (Institucional: Configurações, Conta, Suporte)
class ProfileTabContent extends StatelessWidget {
  const ProfileTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do perfil
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: SoloForteColors.greenIOS.withValues(
                  alpha: 0.2,
                ),
                child: const Icon(
                  SFIcons.person,
                  size: 36,
                  color: SoloForteColors.greenIOS,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raudinei Silva Pereira',
                      style: SoloTextStyles.headingMedium.copyWith(
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Consultor Agronômico',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _ProfileTile(
            icon: SFIcons.settings,
            title: 'Configurações',
            onTap: () {
              // TODO: Navegar para configurações
            },
          ),
          _ProfileTile(
            icon: SFIcons.accountCircle,
            title: 'Minha Conta',
            onTap: () {
              // TODO: Navegar para conta
            },
          ),
          _ProfileTile(
            icon: SFIcons.help,
            title: 'Suporte',
            onTap: () {
              // TODO: Navegar para suporte
            },
          ),
          _ProfileTile(
            icon: SFIcons.info,
            title: 'Sobre',
            onTap: () {
              // TODO: Navegar para sobre
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),
          _ProfileTile(
            icon: SFIcons.logout,
            title: 'Sair',
            isDestructive: true,
            onTap: () {
              // TODO: Implementar logout
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ProfileTile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red
        : Colors.black.withValues(alpha: 0.85);

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
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ),
              if (!isDestructive)
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
