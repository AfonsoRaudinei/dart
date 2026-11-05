import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../domain/models/gps_walk_session.dart';
import '../providers/gps_walk_providers.dart';

/// Ações do GPS Walk.
///
/// Fechar desenho liga o início ao fim. Parar sem fechar só encerra o GPS.
class GpsWalkBottomBar extends ConsumerWidget {
  const GpsWalkBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gpsWalkProvider);
    if (session == null || session.status == GpsWalkStatus.finished) {
      return const SizedBox.shrink();
    }

    final notifier = ref.read(gpsWalkProvider.notifier);
    final status = session.status;
    final v = SoloForteSheetVisuals.of(context);

    if (status == GpsWalkStatus.idle) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FilledAction(
            label: 'Começar a medir',
            detail: 'O GPS marca o caminho enquanto você caminha.',
            visuals: v,
            onPressed: () {
              HapticFeedback.mediumImpact();
              notifier.startMeasuring();
            },
          ),
          const SizedBox(height: 8),
          _TextAction(
            label: 'Cancelar medição',
            color: Theme.of(context).colorScheme.error,
            onPressed: () {
              HapticFeedback.lightImpact();
              notifier.cancel();
            },
          ),
        ],
      );
    }

    final stopped = status == GpsWalkStatus.stoppedOpen;
    final canClose = session.canFinish;
    final canStop = session.canStopOpen;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilledAction(
          label: 'Fechar desenho',
          detail: 'Liga o ponto inicial ao ponto final e salva a área.',
          visuals: v,
          enabled: canClose,
          onPressed: canClose
              ? () {
                  HapticFeedback.mediumImpact();
                  notifier.finish();
                }
              : null,
        ),
        if (!stopped) ...[
          const SizedBox(height: 10),
          _OutlineAction(
            label: 'Parar sem fechar',
            detail: 'Para o GPS e mantém o traço aberto. Nada é salvo.',
            visuals: v,
            enabled: canStop,
            onPressed: canStop
                ? () {
                    HapticFeedback.lightImpact();
                    notifier.stopWithoutClosing();
                  }
                : null,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            if (status == GpsWalkStatus.measuring)
              _TextAction(
                label: 'Pausar',
                color: v.subtitleColor,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.pause();
                },
              )
            else if (status == GpsWalkStatus.paused)
              _TextAction(
                label: 'Retomar',
                color: v.subtitleColor,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  notifier.resume();
                },
              ),
            const Spacer(),
            _TextAction(
              label: stopped ? 'Descartar' : 'Cancelar medição',
              color: Theme.of(context).colorScheme.error,
              onPressed: () {
                HapticFeedback.lightImpact();
                notifier.cancel();
              },
            ),
          ],
        ),
      ],
    );
  }
}

class _FilledAction extends StatelessWidget {
  const _FilledAction({
    required this.label,
    required this.detail,
    required this.visuals,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final String detail;
  final SoloForteSheetVisuals visuals;
  final VoidCallback? onPressed;
  final bool enabled;

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
                  label,
                  style: TextStyle(
                    color: v.ctaText,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
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

class _OutlineAction extends StatelessWidget {
  const _OutlineAction({
    required this.label,
    required this.detail,
    required this.visuals,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final String detail;
  final SoloForteSheetVisuals visuals;
  final VoidCallback? onPressed;
  final bool enabled;

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
                  label,
                  style: TextStyle(
                    color: v.titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
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

class _TextAction extends StatelessWidget {
  const _TextAction({
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
