import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/services/geo_calculator_service.dart';
import '../../domain/services/gps_tracking_service.dart';
import '../controllers/drawing_controller.dart';
import 'gps_walk_metrics_bar.dart';

/// Fallback quando o mapa está em GPS tracking sem sessão de caminhada.
///
/// Fechar desenho é a única ação que liga o início ao fim.
/// Parar sem fechar encerra o stream e mantém o traço aberto.
class GpsTrackingOverlay extends StatelessWidget {
  final DrawingController controller;

  const GpsTrackingOverlay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final vertices = controller.gpsVertices;
    final accuracyM = controller.gpsLastAccuracyM;
    final isPaused = controller.gpsIsPaused;
    final stoppedOpen = controller.gpsStoppedOpen;
    final quality = controller.gpsAccuracyQuality;
    final distance = GeoCalculatorService.calculateOpenPathMeters(vertices);
    final canClose = vertices.length >= kGpsMinVertices;
    final canStop = vertices.length >= 2 && !stoppedOpen;
    final v = SoloForteSheetVisuals.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final pointsLabel = vertices.length == 1
        ? '1 ponto'
        : '${vertices.length} pontos';

    return Material(
      color: v.sheetBackground,
      borderRadius: BorderRadius.vertical(top: Radius.circular(v.sheetRadius)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: v.handleSize.width,
                height: v.handleSize.height,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: v.handleColor,
                  borderRadius: BorderRadius.circular(v.handleSize.height),
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'GPS — Caminhar',
                    style: TextStyle(
                      color: v.titleColor,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                _AccuracyDot(
                  quality: quality,
                  accuracyM: accuracyM,
                  visuals: v,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              stoppedOpen
                  ? 'Desenho aberto. Nada foi salvo.'
                  : 'O traço fica aberto. A distância é o caminho que você andou.',
              style: TextStyle(
                color: v.subtitleColor,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatGpsWalkDistance(distance),
                        style: TextStyle(
                          color: v.titleColor,
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.8,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Distância',
                        style: TextStyle(
                          color: v.subtitleColor,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  pointsLabel,
                  style: TextStyle(
                    color: v.subtitleColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(height: 1, thickness: 0.5, color: v.dividerColor),
            const SizedBox(height: 16),
            _CloseAction(
              visuals: v,
              enabled: canClose,
              onPressed: () {
                HapticFeedback.mediumImpact();
                controller.finalizeGpsTracking();
              },
            ),
            if (!stoppedOpen) ...[
              const SizedBox(height: 10),
              _StopAction(
                visuals: v,
                enabled: canStop,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.stopGpsStreamKeepingVertices();
                },
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (!stoppedOpen && vertices.isNotEmpty)
                  _QuietAction(
                    label: 'Desfazer',
                    color: v.subtitleColor,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      controller.undoLastGpsVertex();
                    },
                  ),
                if (!stoppedOpen) ...[
                  if (vertices.isNotEmpty) const SizedBox(width: 12),
                  _QuietAction(
                    label: isPaused ? 'Retomar' : 'Pausar',
                    color: v.subtitleColor,
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      if (isPaused) {
                        controller.resumeGpsTracking();
                      } else {
                        controller.pauseGpsTracking();
                      }
                    },
                  ),
                ],
                const Spacer(),
                _QuietAction(
                  label: stoppedOpen ? 'Descartar' : 'Cancelar medição',
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    AppLogger.debug(
                      'GPS: cancelar pelo overlay',
                      tag: 'GpsTrackingOverlay',
                    );
                    controller.cancelOperation();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AccuracyDot extends StatelessWidget {
  const _AccuracyDot({
    required this.quality,
    required this.accuracyM,
    required this.visuals,
  });

  final GpsQuality quality;
  final double accuracyM;
  final SoloForteSheetVisuals visuals;

  @override
  Widget build(BuildContext context) {
    final color = switch (quality) {
      GpsQuality.excellent => const Color(0xFF30D158),
      GpsQuality.acceptable => const Color(0xFFFFD60A),
      GpsQuality.poor => Theme.of(context).colorScheme.error,
    };
    final label = accuracyM > 0 ? '${accuracyM.toStringAsFixed(0)} m' : '--';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: visuals.subtitleColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _CloseAction extends StatelessWidget {
  const _CloseAction({
    required this.visuals,
    required this.enabled,
    required this.onPressed,
  });

  final SoloForteSheetVisuals visuals;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final v = visuals;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: v.ctaBackground,
        borderRadius: BorderRadius.circular(v.ctaRadius),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(v.ctaRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fechar desenho',
                  style: TextStyle(
                    color: v.ctaText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Liga o ponto inicial ao ponto final e salva a área.',
                  style: TextStyle(
                    color: v.ctaText.withValues(alpha: 0.82),
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StopAction extends StatelessWidget {
  const _StopAction({
    required this.visuals,
    required this.enabled,
    required this.onPressed,
  });

  final SoloForteSheetVisuals visuals;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final v = visuals;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: v.cardBackground,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(v.cardRadius),
          side: BorderSide(color: v.cardBorder),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(v.cardRadius),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Parar sem fechar',
                  style: TextStyle(
                    color: v.titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Para o GPS e mantém o traço aberto. Nada é salvo.',
                  style: TextStyle(
                    color: v.subtitleColor,
                    fontSize: 13,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuietAction extends StatelessWidget {
  const _QuietAction({
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: color,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
