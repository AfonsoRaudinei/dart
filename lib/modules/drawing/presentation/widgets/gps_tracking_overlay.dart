import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/app_logger.dart';
import '../../domain/services/gps_tracking_service.dart';
import '../controllers/drawing_controller.dart';

/// Overlay de rastreamento GPS para desenho de perímetro de talhão.
///
/// Exibe em tempo real:
/// - Número de vértices capturados
/// - Área parcial em hectares
/// - Indicador visual de qualidade GPS (🟢🟡🔴)
/// - Precisão atual em metros
///
/// Ações disponíveis:
/// - Pausar / Retomar rastreamento
/// - Desfazer último vértice
/// - Finalizar (mínimo 3 vértices)
/// - Cancelar
///
/// Design: iOS Premium — glassmorphism com BackdropFilter blur:24,
/// BorderRadius.circular(24), drag pill, HapticFeedback.
class GpsTrackingOverlay extends StatelessWidget {
  final DrawingController controller;

  const GpsTrackingOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final vertices = controller.gpsVertices;
    final accuracyM = controller.gpsLastAccuracyM;
    final isPaused = controller.gpsIsPaused;
    final quality = controller.gpsAccuracyQuality;
    final areaHa = controller.liveAreaHa;
    final canFinalize = vertices.length >= kGpsMinVertices;

    return Positioned(
      left: 16,
      right: 16,
      bottom: 120, // Acima dos controles do mapa
      child: _GlassCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Drag pill ────────────────────────────────────────────
            Center(
              child: Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFC5C5C7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // ── Header — título + indicador GPS ──────────────────────
            Row(
              children: [
                const Icon(
                  Icons.my_location_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Rastreamento GPS',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _GpsQualityBadge(quality: quality, accuracyM: accuracyM),
              ],
            ),

            const SizedBox(height: 16),

            // ── Métricas ─────────────────────────────────────────────
            Row(
              children: [
                _MetricChip(
                  icon: Icons.place_rounded,
                  label: '${vertices.length} pts',
                ),
                const SizedBox(width: 10),
                _MetricChip(
                  icon: Icons.crop_free_rounded,
                  label: areaHa > 0
                      ? '${areaHa.toStringAsFixed(2)} ha'
                      : '— ha',
                ),
                if (isPaused) ...[
                  const SizedBox(width: 10),
                  const _MetricChip(
                    icon: Icons.pause_circle_outline_rounded,
                    label: 'Pausado',
                    highlight: true,
                  ),
                ],
              ],
            ),

            const SizedBox(height: 16),

            // ── Botões de ação ────────────────────────────────────────
            Row(
              children: [
                // Desfazer
                _ActionButton(
                  icon: Icons.undo_rounded,
                  label: 'Desfazer',
                  enabled: vertices.isNotEmpty,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    controller.undoLastGpsVertex();
                  },
                ),
                const SizedBox(width: 8),
                // Pausar / Retomar
                _ActionButton(
                  icon: isPaused
                      ? Icons.play_arrow_rounded
                      : Icons.pause_rounded,
                  label: isPaused ? 'Retomar' : 'Pausar',
                  enabled: true,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    if (isPaused) {
                      controller.resumeGpsTracking();
                    } else {
                      controller.pauseGpsTracking();
                    }
                  },
                ),
                const SizedBox(width: 8),
                // Finalizar
                Expanded(
                  child: _FinalizeButton(
                    enabled: canFinalize,
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      controller.finalizeGpsTracking();
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ── Cancelar ─────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                AppLogger.debug(
                  'GPS: cancelar pelo overlay',
                  tag: 'GpsTrackingOverlay',
                );
                controller.cancelOperation();
              },
              child: const Text(
                'Cancelar rastreamento',
                style: TextStyle(
                  color: Color(0xFFFF453A),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Componentes privados ─────────────────────────────────────────────────────

class _GlassCard extends StatelessWidget {
  final Widget child;

  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _GpsQualityBadge extends StatelessWidget {
  final GpsQuality quality;
  final double accuracyM;

  const _GpsQualityBadge({required this.quality, required this.accuracyM});

  @override
  Widget build(BuildContext context) {
    final (color, emoji) = switch (quality) {
      GpsQuality.excellent => (const Color(0xFF30D158), '●'),
      GpsQuality.acceptable => (const Color(0xFFFFD60A), '●'),
      GpsQuality.poor => (const Color(0xFFFF453A), '●'),
    };

    final label = accuracyM > 0 ? '${accuracyM.toStringAsFixed(0)}m' : '--';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(emoji, style: TextStyle(color: color, fontSize: 12)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool highlight;

  const _MetricChip({
    required this.icon,
    required this.label,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: highlight
            ? const Color(0xFFFFD60A).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: highlight ? const Color(0xFFFFD60A) : Colors.white70,
            size: 13,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: highlight ? const Color(0xFFFFD60A) : Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1.0 : 0.4,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinalizeButton extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;

  const _FinalizeButton({required this.enabled, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onPressed : null,
      child: AnimatedOpacity(
        opacity: enabled ? 1.0 : 0.4,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: enabled
                ? const Color(0xFF30D158)
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
              SizedBox(width: 6),
              Text(
                'Finalizar',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
