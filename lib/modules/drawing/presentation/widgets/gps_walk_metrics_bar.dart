import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/gps_walk_session.dart';
import '../providers/gps_walk_providers.dart';

/// Barra de métricas em tempo real para o modo GPS Walk.
///
/// Exibe Perímetro (metros) e Área (hectares) atualizados a cada novo ponto
/// GPS coletado. Visível apenas durante [GpsWalkStatus.measuring] e
/// [GpsWalkStatus.paused].
///
/// Design: iOS Premium — glassmorphism + BackdropFilter blur:24.
/// Posicionamento: topo do mapa (dentro do Stack do DrawingSheet).
class GpsWalkMetricsBar extends ConsumerWidget {
  const GpsWalkMetricsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gpsWalkProvider);

    // Não exibir no status idle ou finished
    if (session == null ||
        session.status == GpsWalkStatus.idle ||
        session.status == GpsWalkStatus.finished) {
      return const SizedBox.shrink();
    }

    final periM = session.perimeterMeters;
    final areaHa = session.areaHectares;
    final isPaused = session.status == GpsWalkStatus.paused;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isPaused
                ? Colors.orange.withValues(alpha: 0.18)
                : Colors.black.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.14),
              width: 0.8,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Status indicator ─────────────────────────────────
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isPaused
                      ? const Color(0xFFFFD60A)
                      : const Color(0xFF30D158),
                ),
              ),
              const SizedBox(width: 10),

              // ── Perímetro ────────────────────────────────────────
              _MetricItem(
                icon: Icons.straighten_rounded,
                value: periM >= 1000
                    ? '${(periM / 1000).toStringAsFixed(2)} km'
                    : '${periM.toStringAsFixed(0)} m',
                label: 'Perímetro',
              ),

              _Divider(),

              // ── Área ─────────────────────────────────────────────
              _MetricItem(
                icon: Icons.crop_free_rounded,
                value: areaHa >= 0.01
                    ? '${areaHa.toStringAsFixed(2)} ha'
                    : '${session.areaSquareMeters.toStringAsFixed(0)} m²',
                label: 'Área',
              ),

              // ── Pontos ───────────────────────────────────────────
              if (session.points.isNotEmpty) ...[
                _Divider(),
                _MetricItem(
                  icon: Icons.place_rounded,
                  value: '${session.points.length}',
                  label: 'Pts',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Componentes privados ─────────────────────────────────────────────────────

class _MetricItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _MetricItem({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 13),
        const SizedBox(width: 4),
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
                height: 1.1,
              ),
            ),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white54,
                fontSize: 9,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.5,
      height: 28,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: Colors.white.withValues(alpha: 0.2),
    );
  }
}
