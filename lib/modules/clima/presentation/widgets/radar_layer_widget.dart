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

/// Badge estático do radar — filho direto do [FlutterMap].
class ClimaRadarStatusOverlay extends ConsumerWidget {
  const ClimaRadarStatusOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRadar = ref.watch(climaRadarEnabledProvider);
    final isOnline = ref.watch(isOnlineProvider).asData?.value ?? false;

    if (!showRadar) return const SizedBox.shrink();

    if (!isOnline) {
      return _RadarStatusBanner.offline();
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

        return switch (overlayState) {
          ClimaRadarOverlayState.active => _RadarStatusBanner.active(),
          ClimaRadarOverlayState.noPrecipitation =>
            _RadarStatusBanner.noPrecipitation(),
          _ => _RadarStatusBanner.unavailable(),
        };
      },
      loading: () => _RadarStatusBanner.loading(),
      error: (_, __) => _RadarStatusBanner.unavailable(),
    );
  }
}

/// Alias legado para testes e imports existentes.
typedef ClimaRadarLayerWidget = ClimaRadarTileLayerWidget;

class _RadarStatusBanner extends StatelessWidget {
  final String? message;
  final Color accentColor;
  final Key bannerKey;
  final bool iconOnly;
  final bool showLiveIndicator;

  const _RadarStatusBanner({
    required this.accentColor,
    required this.bannerKey,
    this.message,
    this.iconOnly = false,
    this.showLiveIndicator = false,
  });

  factory _RadarStatusBanner.loading() {
    return const _RadarStatusBanner(
      bannerKey: Key('radar_loading_banner'),
      message: ClimaRadarOverlayMessages.loading,
      accentColor: Colors.lightBlueAccent,
    );
  }

  factory _RadarStatusBanner.active() {
    return const _RadarStatusBanner(
      bannerKey: Key('radar_active_banner'),
      accentColor: Colors.lightBlueAccent,
      iconOnly: true,
      showLiveIndicator: true,
    );
  }

  factory _RadarStatusBanner.noPrecipitation() {
    return const _RadarStatusBanner(
      bannerKey: Key('radar_no_precipitation_banner'),
      message: ClimaRadarOverlayMessages.noPrecipitation,
      accentColor: Colors.white70,
    );
  }

  factory _RadarStatusBanner.unavailable() {
    return const _RadarStatusBanner(
      bannerKey: Key('radar_unavailable_banner'),
      message: ClimaRadarOverlayMessages.unavailable,
      accentColor: Colors.orangeAccent,
    );
  }

  factory _RadarStatusBanner.offline() {
    return const _RadarStatusBanner(
      bannerKey: Key('radar_offline_banner'),
      message: ClimaRadarOverlayMessages.offline,
      accentColor: Colors.amberAccent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Container(
            key: bannerKey,
            margin: const EdgeInsets.only(top: 12, left: 16, right: 16),
            padding: EdgeInsets.symmetric(
              horizontal: iconOnly ? 10 : 12,
              vertical: iconOnly ? 10 : 8,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(iconOnly ? 20 : 8),
              border: Border.all(color: accentColor.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop_outlined, size: 16, color: accentColor),
                if (!iconOnly && message != null) ...[
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      message!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white, fontSize: 13),
                    ),
                  ),
                ],
                if (showLiveIndicator) ...[
                  const SizedBox(width: 6),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Colors.greenAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
