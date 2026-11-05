import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/ui/sheets/solo_forte_sheet_visuals.dart';
import '../../domain/models/gps_walk_session.dart';
import '../providers/gps_walk_providers.dart';

/// Distância do caminho aberto e quantidade de pontos.
///
/// Não mostra área nem a palavra perímetro: o anel ainda não fechou.
class GpsWalkMetricsBar extends ConsumerWidget {
  const GpsWalkMetricsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gpsWalkProvider);
    if (session == null ||
        session.status == GpsWalkStatus.idle ||
        session.status == GpsWalkStatus.finished) {
      return const SizedBox.shrink();
    }

    final v = SoloForteSheetVisuals.of(context);
    final pointsLabel = session.points.length == 1
        ? '1 ponto'
        : '${session.points.length} pontos';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatGpsWalkDistance(session.distanceMeters),
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
    );
  }
}

/// Metros inteiros abaixo de 1 km; quilômetros com 2 casas a partir de 1 km.
String formatGpsWalkDistance(double meters) {
  if (meters >= 1000) {
    return '${(meters / 1000).toStringAsFixed(2)} km';
  }
  return '${meters.toStringAsFixed(0)} m';
}
