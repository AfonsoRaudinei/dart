// DT-028 concluído: radar controlado por armedModeProvider == ArmedMode.clima.
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/map_config.dart';
import '../../../../ui/screens/map/providers/map_armed_mode_provider.dart';
import '../providers/rainviewer_provider.dart';

/// Camada de radar de precipitação em tempo real (RainViewer — ADR-028).
///
/// Renderiza um [TileLayer] sobre o mapa base quando:
///   1. [armedModeProvider] == [ArmedMode.clima]  (toggle ativado pelo usuário)
///   2. [rainviewerTileUrlProvider] retornou URL válida (API acessível)
///
/// Graceful degradation: se a API estiver indisponível ou a lista de frames
/// estiver vazia, o widget retorna [SizedBox.shrink()] sem erro nem crash.
///
/// Posicionamento: deve estar no FlutterMap.children APÓS o [MapLayersWidget]
/// (camada base) e ANTES dos markers.
class RadarLayerWidget extends ConsumerWidget {
  const RadarLayerWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRadar = ref.watch(armedModeProvider) == ArmedMode.clima;

    // Radar desativado → não assiste o FutureProvider (economiza request)
    if (!showRadar) return const SizedBox.shrink();

    final tileUrlAsync = ref.watch(rainviewerTileUrlProvider);

    return tileUrlAsync.when(
      data: (tileUrl) {
        if (tileUrl == null) return const SizedBox.shrink();
        return Opacity(
          opacity: MapConfig.radarOverlayOpacity,
          child: TileLayer(
            urlTemplate: tileUrl,
            userAgentPackageName: MapConfig.userAgent,
            // Tiles RainViewer não usam subdomínios
            subdomains: const [],
          ),
        );
      },
      // Carregando ou erro → nenhum overlay (mapa continua íntegro)
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
