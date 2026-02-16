import 'package:flutter/material.dart';
import '../../../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../theme/soloforte_theme.dart';

/// Tab 1 — MAPA (Funções core relacionadas ao mapa técnico)
class MapTabContent extends ConsumerWidget {
  final VoidCallback onDrawingTap;
  final VoidCallback onLayersTap;
  final VoidCallback onPublicationsTap;
  final VoidCallback onCheckInTap;

  const MapTabContent({
    super.key,
    required this.onDrawingTap,
    required this.onLayersTap,
    required this.onPublicationsTap,
    required this.onCheckInTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ferramentas do Mapa',
            style: SoloTextStyles.headingMedium.copyWith(fontSize: 18),
          ),
          const SizedBox(height: 16),
          _ActionTile(
            icon: SFIcons.edit,
            title: 'Desenhar',
            subtitle: 'Criar polígonos e marcações',
            onTap: onDrawingTap,
          ),
          _ActionTile(
            icon: SFIcons.layers,
            title: 'Camadas',
            subtitle: 'Alternar visualizações do mapa',
            onTap: onLayersTap,
          ),
          _ActionTile(
            icon: SFIcons.article,
            title: 'Publicações',
            subtitle: 'Ver publicações no mapa',
            onTap: onPublicationsTap,
          ),
          _ActionTile(
            icon: SFIcons.checkCircle,
            title: 'Check-in',
            subtitle: 'Registrar presença em campo',
            onTap: onCheckInTap,
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
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
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: const Color(0xFF22C55E), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                SFIcons.chevronRight,
                size: 20,
                color: Colors.black.withValues(alpha: 0.25),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
