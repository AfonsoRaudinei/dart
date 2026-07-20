import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/domain/map_models.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../core/state/map_state.dart';
import '../../../theme/premium/design_tokens.dart';

enum MapOfflineVisualState {
  checking,
  offlineActive,
  offlineOutOfCoverage,
  offlineUnavailable,
  onlineCovered,
  onlineUncovered,
}

class MapOfflineStatusPresentation {
  final MapOfflineVisualState state;
  final String title;
  final String message;
  final bool canDownloadCurrentArea;
  final Color accentColor;
  final IconData icon;

  const MapOfflineStatusPresentation({
    required this.state,
    required this.title,
    required this.message,
    required this.canDownloadCurrentArea,
    required this.accentColor,
    required this.icon,
  });
}

MapOfflineStatusPresentation buildMapOfflineStatusPresentation({
  required bool isOnline,
  required bool hasOfflineAreasForLayer,
  required bool hasOfflineCoverageForViewport,
  required bool isCheckingCoverage,
}) {
  if (isCheckingCoverage) {
    return const MapOfflineStatusPresentation(
      state: MapOfflineVisualState.checking,
      title: 'Verificando cobertura offline',
      message: 'Conferindo se a área visível já foi baixada.',
      canDownloadCurrentArea: false,
      accentColor: Color(0xFF5E5CE6),
      icon: Icons.sync_outlined,
    );
  }

  if (!isOnline && hasOfflineCoverageForViewport) {
    return const MapOfflineStatusPresentation(
      state: MapOfflineVisualState.offlineActive,
      title: 'Mapa offline ativo',
      message: 'A área visível está coberta pelo cache local.',
      canDownloadCurrentArea: false,
      accentColor: PremiumTokens.brandGreen,
      icon: Icons.download_done_rounded,
    );
  }

  if (!isOnline && hasOfflineAreasForLayer) {
    return const MapOfflineStatusPresentation(
      state: MapOfflineVisualState.offlineOutOfCoverage,
      title: 'Fora da área baixada',
      message:
          'Esta região não está coberta offline. Volte para uma área baixada ou baixe esta região quando ficar online.',
      canDownloadCurrentArea: false,
      accentColor: Color(0xFFFF9F0A),
      icon: Icons.warning_amber_rounded,
    );
  }

  if (!isOnline) {
    return const MapOfflineStatusPresentation(
      state: MapOfflineVisualState.offlineUnavailable,
      title: 'Sem cobertura offline',
      message:
          'Nenhuma área desta camada foi baixada. Conecte-se à internet para preparar o uso em campo.',
      canDownloadCurrentArea: false,
      accentColor: Color(0xFFFF453A),
      icon: Icons.cloud_off_rounded,
    );
  }

  if (hasOfflineCoverageForViewport) {
    return const MapOfflineStatusPresentation(
      state: MapOfflineVisualState.onlineCovered,
      title: 'Área disponível offline',
      message: 'A área visível já pode ser usada sem internet.',
      canDownloadCurrentArea: true,
      accentColor: PremiumTokens.brandGreen,
      icon: Icons.verified_rounded,
    );
  }

  return const MapOfflineStatusPresentation(
    state: MapOfflineVisualState.onlineUncovered,
    title: 'Baixe a área visível',
    message:
        'Esta região ainda não está no cache local. Baixe agora para operar offline em campo.',
    canDownloadCurrentArea: true,
    accentColor: Color(0xFF0A84FF),
    icon: Icons.download_for_offline_rounded,
  );
}

String mapLayerLabel(LayerType layerType) {
  switch (layerType) {
    case LayerType.standard:
      return 'Padrão';
    case LayerType.satellite:
      return 'Satélite';
    case LayerType.relevo:
      return 'Relevo';
  }
}

class _OfflineStatusSnapshot {
  final LayerType activeLayer;
  final int areasForLayerCount;
  final MapOfflineStatusPresentation presentation;

  const _OfflineStatusSnapshot({
    required this.activeLayer,
    required this.areasForLayerCount,
    required this.presentation,
  });
}

_OfflineStatusSnapshot? _watchOfflineStatusSnapshot(WidgetRef ref) {
  final camera = ref.watch(mapCameraSnapshotProvider);
  if (camera == null) return null;

  final activeLayer = ref.watch(activeLayerProvider);
  final tileConfig = MapConfig.tileConfigForLayer(
    activeLayer,
    mapTilerApiKey: MapConfig.kMapTilerApiKey,
  );
  final cacheService = ref.watch(offlineTileCacheServiceProvider);
  final layerKey = cacheService.layerKeyFromTemplate(tileConfig.urlTemplate);
  final areasForLayer = ref.watch(
    offlineMapAreasProvider.select(
      (areas) => areas.where((area) => area.layerKey == layerKey).toList(),
    ),
  );
  final coverageQuery = OfflineCoverageQuery(
    layerKey: layerKey,
    lat: camera.center.latitude,
    lng: camera.center.longitude,
    south: camera.visibleBounds.south,
    west: camera.visibleBounds.west,
    north: camera.visibleBounds.north,
    east: camera.visibleBounds.east,
    zoom: camera.zoom.round(),
  );
  final coverageAsync = ref.watch(offlineCoverageProvider(coverageQuery));
  final isOnline = ref.watch(isOnlineProvider).asData?.value ?? false;
  final presentation = buildMapOfflineStatusPresentation(
    isOnline: isOnline,
    hasOfflineAreasForLayer: areasForLayer.isNotEmpty,
    hasOfflineCoverageForViewport: coverageAsync.asData?.value ?? false,
    isCheckingCoverage: coverageAsync.isLoading,
  );

  return _OfflineStatusSnapshot(
    activeLayer: activeLayer,
    areasForLayerCount: areasForLayer.length,
    presentation: presentation,
  );
}

class MapOfflineStatusOverlay extends ConsumerWidget {
  final Future<void> Function()? onDownloadOfflineArea;

  const MapOfflineStatusOverlay({super.key, this.onDownloadOfflineArea});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = _watchOfflineStatusSnapshot(ref);
    if (snapshot == null) return const SizedBox.shrink();

    final safeTop = MediaQuery.of(context).padding.top;
    final presentation = snapshot.presentation;
    final areasLabel = snapshot.areasForLayerCount == 1
        ? '1 área'
        : '${snapshot.areasForLayerCount} áreas';

    return Positioned(
      top: safeTop + 64,
      right: 12,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 248),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF101214).withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: presentation.accentColor.withValues(alpha: 0.55),
            ),
            boxShadow: const [
              BoxShadow(
                color: Colors.black54,
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      presentation.icon,
                      size: 18,
                      color: presentation.accentColor,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        presentation.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${mapLayerLabel(snapshot.activeLayer)} • $areasLabel baixadas',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  presentation.message,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.82),
                    fontSize: 12,
                    height: 1.28,
                  ),
                ),
                if (presentation.canDownloadCurrentArea &&
                    onDownloadOfflineArea != null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 34,
                    child: FilledButton.tonalIcon(
                      onPressed: onDownloadOfflineArea,
                      icon: const Icon(Icons.download_for_offline_rounded),
                      label: Text(
                        presentation.state ==
                                MapOfflineVisualState.onlineCovered
                            ? 'Atualizar área'
                            : 'Baixar área',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: presentation.accentColor.withValues(
                          alpha: 0.18,
                        ),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class MapOfflineStatusCard extends ConsumerWidget {
  final Future<void> Function()? onDownloadOfflineArea;

  const MapOfflineStatusCard({super.key, this.onDownloadOfflineArea});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = _watchOfflineStatusSnapshot(ref);
    if (snapshot == null) return const SizedBox.shrink();

    final presentation = snapshot.presentation;
    final areasCount = snapshot.areasForLayerCount;
    final areasLabel = areasCount == 1
        ? '1 área salva'
        : '$areasCount áreas salvas';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D21),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: presentation.accentColor.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: presentation.accentColor.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Icon(
                  presentation.icon,
                  color: presentation.accentColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mapa offline',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      presentation.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _OfflineMetaPill(
                label: 'Camada ${mapLayerLabel(snapshot.activeLayer)}',
              ),
              _OfflineMetaPill(label: areasLabel),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            presentation.message,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.86),
              fontSize: 13,
              height: 1.32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'A moldura verde no mapa marca a cobertura já baixada da camada atual.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.62),
              fontSize: 12,
              height: 1.28,
            ),
          ),
          if (onDownloadOfflineArea != null) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: presentation.canDownloadCurrentArea
                    ? onDownloadOfflineArea
                    : null,
                icon: const Icon(Icons.download_for_offline_rounded),
                label: Text(
                  presentation.canDownloadCurrentArea
                      ? 'Baixar área visível'
                      : 'Download indisponível sem internet',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: presentation.canDownloadCurrentArea
                      ? presentation.accentColor
                      : Colors.white12,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.white10,
                  disabledForegroundColor: Colors.white54,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MapOfflineCoverageLayer extends ConsumerWidget {
  const MapOfflineCoverageLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLayer = ref.watch(activeLayerProvider);
    final tileConfig = MapConfig.tileConfigForLayer(
      activeLayer,
      mapTilerApiKey: MapConfig.kMapTilerApiKey,
    );
    final cacheService = ref.watch(offlineTileCacheServiceProvider);
    final layerKey = cacheService.layerKeyFromTemplate(tileConfig.urlTemplate);
    final camera = ref.watch(mapCameraSnapshotProvider);
    final areas = ref.watch(
      offlineMapAreasProvider.select(
        (allAreas) =>
            allAreas.where((area) => area.layerKey == layerKey).toList(),
      ),
    );
    if (areas.isEmpty) return const SizedBox.shrink();

    final zoom = camera?.zoom ?? 0;
    final center = camera?.center;

    return IgnorePointer(
      child: PolygonLayer(
        polygons: [
          for (final area in areas)
            Polygon(
              points: [
                LatLng(area.south, area.west),
                LatLng(area.north, area.west),
                LatLng(area.north, area.east),
                LatLng(area.south, area.east),
              ],
              color:
                  area.covers(
                    layerKey: layerKey,
                    lat: center?.latitude ?? area.south,
                    lng: center?.longitude ?? area.west,
                    zoom: zoom,
                  )
                  ? PremiumTokens.brandGreen.withValues(alpha: 0.14)
                  : const Color(0x990A84FF).withValues(alpha: 0.12),
              borderColor:
                  area.covers(
                    layerKey: layerKey,
                    lat: center?.latitude ?? area.south,
                    lng: center?.longitude ?? area.west,
                    zoom: zoom,
                  )
                  ? PremiumTokens.brandGreen
                  : const Color(0xFF0A84FF),
              borderStrokeWidth: 2.2,
            ),
        ],
      ),
    );
  }
}

class _OfflineMetaPill extends StatelessWidget {
  final String label;

  const _OfflineMetaPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.84),
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
