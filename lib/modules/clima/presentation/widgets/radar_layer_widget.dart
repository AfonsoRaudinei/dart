// Radar de chuva controlado por climaRadarEnabledProvider (overlay persistente).
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../domain/radar_overlay_logger.dart';
import '../providers/radar_providers.dart';

/// Camada de radar de precipitação em tempo real (RainViewer — ADR-043).
///
/// Posicionamento: após polígonos/desenho e antes dos markers.
class ClimaRadarLayerWidget extends ConsumerStatefulWidget {
  final TileProvider? tileProvider;

  const ClimaRadarLayerWidget({super.key, this.tileProvider});

  @override
  ConsumerState<ClimaRadarLayerWidget> createState() =>
      _ClimaRadarLayerWidgetState();
}

class _ClimaRadarLayerWidgetState extends ConsumerState<ClimaRadarLayerWidget> {
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
    final isOnline = ref.watch(isOnlineProvider).valueOrNull ?? true;

    if (!showRadar) {
      _stopAnimation();
      return const SizedBox.shrink();
    }

    if (!isOnline) {
      _stopAnimation();
      logClimaRadarOverlayState(ClimaRadarOverlayState.offline.name);
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
        logClimaRadarOverlayState(overlayState.name);

        if (!result.hasFrames) {
          _stopAnimation();
          return switch (overlayState) {
            ClimaRadarOverlayState.noPrecipitation =>
              _RadarStatusBanner.noPrecipitation(),
            _ => _RadarStatusBanner.unavailable(),
          };
        }

        _syncAnimation(result.frames.length);

        final rawIndex = ref.watch(climaRadarFrameIndexProvider);
        final frameIndex = rawIndex.clamp(0, result.frames.length - 1);
        final activeFrame = result.frames[frameIndex];
        final ageLabel = formatClimaRadarFrameAgeLabel(
          activeFrame.time,
          DateTime.now(),
        );

        return Stack(
          children: [
            Opacity(
              opacity: MapConfig.radarOverlayOpacity,
              child: TileLayer(
                urlTemplate: activeFrame.urlTemplate,
                userAgentPackageName: MapConfig.userAgent,
                maxZoom: MapConfig.rainViewerMaxZoom,
                maxNativeZoom: MapConfig.rainViewerMaxNativeZoom,
                tileProvider: widget.tileProvider,
                subdomains: const [],
              ),
            ),
            _RadarStatusBanner.active(ageLabel: ageLabel),
          ],
        );
      },
      loading: () {
        _stopAnimation();
        logClimaRadarOverlayState(ClimaRadarOverlayState.loading.name);
        return _RadarStatusBanner.loading();
      },
      error: (_, __) {
        _stopAnimation();
        logClimaRadarOverlayState(ClimaRadarOverlayState.unavailable.name);
        return _RadarStatusBanner.unavailable();
      },
    );
  }
}

class _RadarStatusBanner extends StatelessWidget {
  final String message;
  final Color accentColor;
  final Key bannerKey;

  const _RadarStatusBanner({
    required this.message,
    required this.accentColor,
    required this.bannerKey,
  });

  factory _RadarStatusBanner.loading() {
    return const _RadarStatusBanner(
      bannerKey: Key('radar_loading_banner'),
      message: ClimaRadarOverlayMessages.loading,
      accentColor: Colors.lightBlueAccent,
    );
  }

  factory _RadarStatusBanner.active({required String ageLabel}) {
    return _RadarStatusBanner(
      bannerKey: const Key('radar_active_banner'),
      message: climaRadarBannerMessage(
        state: ClimaRadarOverlayState.active,
        activeAgeLabel: ageLabel,
      ),
      accentColor: Colors.lightBlueAccent,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.72),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: accentColor.withValues(alpha: 0.45)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.water_drop_outlined, size: 16, color: accentColor),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
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
