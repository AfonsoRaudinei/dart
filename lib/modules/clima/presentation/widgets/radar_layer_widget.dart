// Radar de chuva controlado por climaRadarEnabledProvider (overlay persistente).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../domain/radar_overlay_logger.dart';
import '../providers/radar_providers.dart';

/// Camada de tiles do radar RainViewer (ADR-043).
///
/// Deve ser filho direto do [FlutterMap], após polígonos/desenho e antes de markers.
class ClimaRadarTileLayerWidget extends ConsumerStatefulWidget {
  final TileProvider? tileProvider;

  const ClimaRadarTileLayerWidget({super.key, this.tileProvider});

  @override
  ConsumerState<ClimaRadarTileLayerWidget> createState() =>
      _ClimaRadarTileLayerWidgetState();
}

class _ClimaRadarTileLayerWidgetState
    extends ConsumerState<ClimaRadarTileLayerWidget> {
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
        final indexNotifier = ref.read(climaRadarFrameIndexProvider.notifier);
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
    final showRadar = ref.watch(climaRadarEnabledProvider);
    final isOnline = ref.watch(isOnlineProvider).asData?.value ?? false;

    if (!showRadar) {
      _stopAnimation();
      return const SizedBox.shrink();
    }

    if (!isOnline) {
      _stopAnimation();
      logClimaRadarOverlayState(ClimaRadarOverlayState.offline.name);
      return const SizedBox.shrink();
    }

    final framesAsync = ref.watch(climaRadarFramesProvider);

    return framesAsync.when(
      data: (result) {
        final overlayState = resolveClimaRadarOverlayState(
          enabled: true,
          isOnline: true,
          isLoading: false,
          result: result,
        );
        logClimaRadarOverlayState(overlayState.name);

        if (!result.hasFrames) {
          _stopAnimation();
          return const SizedBox.shrink();
        }

        _syncAnimation(result.frames.length);

        final rawIndex = ref.watch(climaRadarFrameIndexProvider);
        final frameIndex = rawIndex.clamp(0, result.frames.length - 1);
        final activeFrame = result.frames[frameIndex];

        return Opacity(
          opacity: MapConfig.radarOverlayOpacity,
          child: TileLayer(
            urlTemplate: activeFrame.urlTemplate,
            userAgentPackageName: MapConfig.userAgent,
            tileSize: MapConfig.rainViewerTileSize,
            zoomOffset: MapConfig.rainViewerZoomOffset,
            maxZoom: MapConfig.rainViewerMaxZoom,
            maxNativeZoom: MapConfig.rainViewerMaxNativeZoom,
            tileProvider: widget.tileProvider,
            subdomains: const [],
          ),
        );
      },
      loading: () {
        _stopAnimation();
        logClimaRadarOverlayState(ClimaRadarOverlayState.loading.name);
        return const SizedBox.shrink();
      },
      error: (_, __) {
        _stopAnimation();
        logClimaRadarOverlayState(ClimaRadarOverlayState.unavailable.name);
        return const SizedBox.shrink();
      },
    );
  }
}

/// Alias legado para testes e imports existentes.
typedef ClimaRadarLayerWidget = ClimaRadarTileLayerWidget;
