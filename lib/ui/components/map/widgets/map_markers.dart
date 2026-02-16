import 'package:flutter/material.dart';
import '../../../../../../modules/map/design/sf_icons.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/state/map_state.dart';
import '../../../theme/soloforte_theme.dart';
import '../../../../core/utils/map_logger.dart';

/// Widget que observa apenas showMarkersProvider e publicacoesDataProvider.
/// Rebuild isolado quando markers ou visibilidade mudam.
class MapMarkersWidget extends ConsumerWidget {
  const MapMarkersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showMarkers = ref.watch(showMarkersProvider);
    // ⚡ Otimização: Apenas rebuilda se a lista de publicações mudar (não se props internas mudarem)
    final publications = ref.watch(
      publicacoesDataProvider.select((asyncPubs) {
        if (!asyncPubs.hasValue) return null;
        // Mapear para dados relevantes apenas (lat, long, id)
        return asyncPubs.value!
            .map((p) => (p.id, p.latitude, p.longitude))
            .toList();
      }),
    );

    if (!showMarkers || publications == null || publications.isEmpty) {
      return const SizedBox.shrink();
    }

    final markers = publications
        .map(
          (data) => Marker(
            point: LatLng(data.$2, data.$3), // lat, long
            width: 40,
            height: 40,
            child: const Icon(
              SFIcons.locationOn,
              color: SoloForteColors.greenIOS,
              size: 40,
            ),
          ),
        )
        .toList();

    MapLogger.logMarkerCount(markers.length);

    return MarkerClusterLayerWidget(
      options: MarkerClusterLayerOptions(
        maxClusterRadius: 120,
        size: const Size(40, 40),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(50),
        maxZoom: 15,
        markers: markers,
        builder: (context, markers) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: SoloForteColors.greenIOS,
            ),
            child: Center(
              child: Text(
                markers.length.toString(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
          );
        },
      ),
    );
  }
}
