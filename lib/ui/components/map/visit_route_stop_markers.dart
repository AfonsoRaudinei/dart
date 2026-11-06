import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_route_stop.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';

/// Marcadores numerados da rota sugerida no mapa privado (política 4A).
class VisitRouteStopMarkers extends ConsumerWidget {
  const VisitRouteStopMarkers({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(visitControllerProvider).valueOrNull;
    final stops = session?.routeStops ?? const <VisitRouteStop>[];
    if (stops.isEmpty) return const SizedBox.shrink();

    final current = session?.routeCurrentIndex;
    final accent = Theme.of(context).colorScheme.primary;

    return MarkerLayer(
      markers: [
        for (final stop in stops)
          Marker(
            point: LatLng(stop.lat, stop.lng),
            width: 36,
            height: 36,
            alignment: Alignment.center,
            child: _StopBadge(
              index: stop.index,
              done: stop.isDone,
              current: stop.index == current,
              accent: accent,
            ),
          ),
      ],
    );
  }
}

class _StopBadge extends StatelessWidget {
  final int index;
  final bool done;
  final bool current;
  final Color accent;

  const _StopBadge({
    required this.index,
    required this.done,
    required this.current,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    final fill = done
        ? const Color(0xFF8E8E93)
        : (current ? accent : Colors.white);
    final text = done || current ? Colors.white : accent;
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
        border: Border.all(
          color: done ? const Color(0xFF8E8E93) : accent,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 4,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        '$index',
        style: TextStyle(
          color: text,
          fontSize: 13,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
