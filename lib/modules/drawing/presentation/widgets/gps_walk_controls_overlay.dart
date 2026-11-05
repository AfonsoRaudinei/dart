import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../domain/models/gps_walk_session.dart';
import '../providers/gps_walk_providers.dart';
import 'gps_walk_bottom_bar.dart';
import 'gps_walk_metrics_bar.dart';

/// Superfície única do modo GPS Walk.
///
/// Fundo opaco do sheet do app. O traço no mapa permanece aberto até
/// o usuário tocar em Fechar desenho.
class GpsWalkControlsOverlay extends ConsumerWidget {
  const GpsWalkControlsOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gpsWalkProvider);
    if (session == null || session.status == GpsWalkStatus.finished) {
      return const SizedBox.shrink();
    }

    final v = SoloForteSheetVisuals.of(context);
    final bottom = MediaQuery.paddingOf(context).bottom;

    return RepaintBoundary(
      child: Material(
        color: v.sheetBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(v.sheetRadius),
        ),
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
              Text(
                'GPS — Caminhar',
                style: TextStyle(
                  color: v.titleColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _lead(session.status),
                style: TextStyle(
                  color: v.subtitleColor,
                  fontSize: 14,
                  height: 1.35,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 16),
              const GpsWalkMetricsBar(),
              if (session.status != GpsWalkStatus.idle) ...[
                const SizedBox(height: 16),
                Divider(height: 1, thickness: 0.5, color: v.dividerColor),
                const SizedBox(height: 16),
              ],
              const GpsWalkBottomBar(),
            ],
          ),
        ),
      ),
    );
  }

  String _lead(GpsWalkStatus status) {
    switch (status) {
      case GpsWalkStatus.stoppedOpen:
        return 'Desenho aberto. Nada foi salvo.';
      case GpsWalkStatus.idle:
      case GpsWalkStatus.measuring:
      case GpsWalkStatus.paused:
        return 'O traço fica aberto. A distância é o caminho que você andou.';
      case GpsWalkStatus.finished:
        return '';
    }
  }
}
