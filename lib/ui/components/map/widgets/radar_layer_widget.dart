// Radar de chuva controlado por radarEnabledProvider (overlay persistente,
// independente de armedModeProvider).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../providers/rainviewer_provider.dart';

/// Camada de radar de precipitação em tempo real (RainViewer — ADR-028).
///
/// Renderiza um [TileLayer] sobre o mapa base quando:
///   1. [radarEnabledProvider] == true  (toggle ativado pelo usuário)
///   2. [rainviewerRadarFramesProvider] retornou frames válidos
///
/// Graceful degradation: se a API estiver indisponível ou a lista de frames
/// estiver vazia, exibe um indicador discreto sem comprometer o mapa.
///
/// Posicionamento: deve estar no FlutterMap.children APÓS o [MapLayersWidget]
/// (camada base) e ANTES dos markers.
class RadarLayerWidget extends ConsumerStatefulWidget {
  final TileProvider? tileProvider;

  const RadarLayerWidget({super.key, this.tileProvider});

  @override
  ConsumerState<RadarLayerWidget> createState() => _RadarLayerWidgetState();
}

class _RadarLayerWidgetState extends ConsumerState<RadarLayerWidget> {
  Timer? _animationTimer;
  int _animatedFrameCount = 0;

  @override
  void dispose() {
    _stopAnimation();
    super.dispose();
  }

  void _syncAnimation(int frameCount) {
    if (frameCount <= 1) {
      _stopAnimation();
      return;
    }

    if (_animationTimer != null && _animatedFrameCount == frameCount) return;

    _stopAnimation();
    _animatedFrameCount = frameCount;
    _animationTimer = Timer.periodic(
      MapConfig.rainViewerAnimationFrameInterval,
      (_) {
        if (!mounted) return;
        final indexNotifier = ref.read(rainviewerFrameIndexProvider.notifier);
        indexNotifier.state = (indexNotifier.state + 1) % frameCount;
      },
    );
  }

  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _animatedFrameCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    final showRadar = ref.watch(radarEnabledProvider);

    // Radar desativado → não assiste o FutureProvider (economiza request)
    if (!showRadar) {
      _stopAnimation();
      return const SizedBox.shrink();
    }

    final framesAsync = ref.watch(rainviewerRadarFramesProvider);

    return framesAsync.when(
      data: (frames) {
        if (frames.isEmpty) {
          _stopAnimation();
          return const _RadarUnavailableIndicator();
        }
        _syncAnimation(frames.length);

        final rawIndex = ref.watch(rainviewerFrameIndexProvider);
        final frameIndex = rawIndex.clamp(0, frames.length - 1);
        final tileUrl = frames[frameIndex].urlTemplate;

        return Stack(
          children: [
            Opacity(
              opacity: MapConfig.radarOverlayOpacity,
              child: TileLayer(
                urlTemplate: tileUrl,
                userAgentPackageName: MapConfig.userAgent,
                maxZoom: MapConfig.rainViewerMaxZoom,
                maxNativeZoom: MapConfig.rainViewerMaxNativeZoom,
                tileProvider: widget.tileProvider,
                // Tiles RainViewer não usam subdomínios.
                subdomains: const [],
              ),
            ),
            const _RadarActiveIndicator(),
          ],
        );
      },
      // Durante o carregamento, o mapa continua íntegro sem overlay.
      loading: () {
        _stopAnimation();
        return const SizedBox.shrink();
      },
      error: (_, __) {
        _stopAnimation();
        return const _RadarUnavailableIndicator();
      },
    );
  }
}

/// Banner de status do radar ativo.
///
/// É um [ConsumerWidget] separado para que a observação do zoom (Etapa 3)
/// reconstrua apenas o banner — nunca o [TileLayer] — evitando recarga de
/// tiles a cada pan/zoom.
class _RadarActiveIndicator extends ConsumerWidget {
  const _RadarActiveIndicator();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zoom = ref.watch(
      mapCameraSnapshotProvider.select((snap) => snap?.zoom),
    );
    // Acima do zoom nativo da RainViewer o tile sofre overzoom e fica grosseiro
    // (mosaico global de ~1 km). Avisamos para não passar impressão de "bug".
    final coarse = zoom != null && zoom > MapConfig.rainViewerMaxNativeZoom;

    return IgnorePointer(
      child: SafeArea(
        child: Align(
          // topCenter: zona livre entre o card de conta (esquerda) e a
          // bússola (direita). Evita a oclusão que ocorria em topLeft.
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 12, left: 12, right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop,
                      color: Colors.lightBlueAccent,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        'Radar de chuva ativo · áreas em azul indicam chuva agora',
                        style: TextStyle(color: Colors.white, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (coarse)
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Text(
                      'Resolução regional (~1 km) neste zoom',
                      style: TextStyle(color: Colors.white60, fontSize: 10),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

class _RadarUnavailableIndicator extends StatelessWidget {
  const _RadarUnavailableIndicator();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Radar indisponível',
              style: TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ),
      ),
    );
  }
}
