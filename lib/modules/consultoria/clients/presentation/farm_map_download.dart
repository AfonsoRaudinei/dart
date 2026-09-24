import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_plan.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';

/// Baixa o satélite que cobre os talhões da fazenda e registra a área
/// no mesmo cache que o mapa principal lê offline.
Future<void> downloadFarmSatelliteMap({
  required BuildContext context,
  required WidgetRef ref,
  required String farmId,
  required List<FarmLinkedFieldSummary> fields,
}) async {
  final isOnline = ref.read(isOnlineProvider).asData?.value ?? false;
  if (!isOnline) {
    _snack(
      context,
      'Sem internet. Conecte-se para baixar o mapa desta fazenda.',
    );
    return;
  }

  final FarmMapDownloadPlan? plan;
  try {
    plan = buildFarmMapDownloadPlan(
      polygons: fields.map((field) => field.vertices),
    );
  } on OfflineTileCacheException catch (error) {
    _snack(context, error.message);
    return;
  }
  if (plan == null) {
    _snack(context, 'Nenhum talhão desenhado para baixar o mapa.');
    return;
  }

  final labelsEnabled = ref.read(mapSatelliteLabelsEnabledProvider);
  final tileConfig = MapConfig.tileConfigForLayer(
    LayerType.satellite,
    mapTilerApiKey: MapConfig.kMapTilerApiKey,
    satelliteWithLabels: labelsEnabled,
  );
  final cacheService = ref.read(offlineTileCacheServiceProvider);
  final layerKey = cacheService.layerKeyFromTemplate(tileConfig.urlTemplate);

  var cancelRequested = false;
  final progress = ValueNotifier(
    OfflinePrefetchProgress(
      total: plan.tileCount,
      processed: 0,
      downloaded: 0,
      skipped: 0,
      failed: 0,
    ),
  );

  if (!context.mounted) {
    progress.dispose();
    return;
  }

  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Baixando mapa da fazenda'),
        content: ValueListenableBuilder<OfflinePrefetchProgress>(
          valueListenable: progress,
          builder: (_, value, __) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LinearProgressIndicator(value: value.fraction),
                const SizedBox(height: 12),
                Text('${value.processed} de ${value.total} tiles'),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => cancelRequested = true,
            child: const Text('Cancelar'),
          ),
        ],
      );
    },
  );

  late final OfflinePrefetchResult result;
  try {
    result = await cacheService.prefetchArea(
      layerKey: layerKey,
      urlTemplate: tileConfig.urlTemplate,
      subdomains: tileConfig.subdomains,
      south: plan.south,
      west: plan.west,
      north: plan.north,
      east: plan.east,
      minZoom: plan.minZoom,
      maxZoom: plan.maxZoom,
      headers: {'User-Agent': MapConfig.userAgent},
      onProgress: (value) => progress.value = value,
      shouldCancel: () => cancelRequested,
    );
  } on OfflineTileCacheException catch (error) {
    if (context.mounted) Navigator.of(context).pop();
    progress.dispose();
    if (context.mounted) _snack(context, error.message);
    return;
  }

  if (context.mounted) Navigator.of(context).pop();
  progress.dispose();
  if (!context.mounted) return;

  if (!result.isComplete) {
    _snack(
      context,
      result.cancelled
          ? 'Download do mapa cancelado.'
          : 'Download incompleto: ${result.failed} tile(s) falharam. Tente novamente.',
    );
    return;
  }

  final center = LatLng(
    (plan.south + plan.north) / 2,
    (plan.west + plan.east) / 2,
  );
  OfflineMapAreaConfig? existing;
  for (final area in ref.read(offlineMapAreasProvider)) {
    if (area.layerKey == layerKey &&
        area.covers(
          layerKey: layerKey,
          lat: center.latitude,
          lng: center.longitude,
          zoom: plan.minZoom.toDouble(),
        )) {
      existing = area;
      break;
    }
  }

  ref.read(offlineMapAreasProvider.notifier).updateArea(
        existing != null
            ? existing.mergeWithViewport(
                south: plan.south,
                west: plan.west,
                north: plan.north,
                east: plan.east,
                minZoom: plan.minZoom.toDouble(),
                maxZoom: plan.maxZoom.toDouble(),
                createdAt: result.downloaded > 0
                    ? DateTime.now()
                    : existing.createdAt,
              )
            : OfflineMapAreaConfig(
                id: 'farm:$farmId',
                layerKey: layerKey,
                south: plan.south,
                west: plan.west,
                north: plan.north,
                east: plan.east,
                minZoom: plan.minZoom.toDouble(),
                maxZoom: plan.maxZoom.toDouble(),
                createdAt: DateTime.now(),
              ),
      );

  _snack(
    context,
    'Mapa da fazenda baixado: ${result.downloaded} tile(s) novo(s), '
    '${result.skipped} já existente(s).',
  );
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}
