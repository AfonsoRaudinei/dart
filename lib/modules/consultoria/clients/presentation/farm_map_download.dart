import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_controller.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_plan.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

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

  final controller = ref.read(farmMapDownloadControllerProvider.notifier);
  if (!controller.isRunningFor(farmId)) {
    unawaited(
      controller.startDownload(
        farmId: farmId,
        plan: plan,
        layerKey: layerKey,
        urlTemplate: tileConfig.urlTemplate,
        subdomains: tileConfig.subdomains,
        headers: {'User-Agent': MapConfig.userAgent},
      ),
    );
  }

  if (!context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _FarmMapDownloadProgressDialog(farmId: farmId),
  );
}

class _FarmMapDownloadProgressDialog extends ConsumerStatefulWidget {
  final String farmId;

  const _FarmMapDownloadProgressDialog({required this.farmId});

  @override
  ConsumerState<_FarmMapDownloadProgressDialog> createState() =>
      _FarmMapDownloadProgressDialogState();
}

class _FarmMapDownloadProgressDialogState
    extends ConsumerState<_FarmMapDownloadProgressDialog> {
  @override
  void initState() {
    super.initState();
    ref.listenManual<Map<String, FarmMapDownloadJob>>(
      farmMapDownloadControllerProvider,
      (previous, next) {
        final job = next[widget.farmId];
        final wasRunning = previous?[widget.farmId]?.isRunning ?? false;
        if (wasRunning && job != null && !job.isRunning && mounted) {
          Navigator.of(context).pop();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final job = ref.watch(farmMapDownloadControllerProvider)[widget.farmId];
    final progress = job?.progress ??
        const OfflinePrefetchProgress(
          total: 0,
          processed: 0,
          downloaded: 0,
          skipped: 0,
          failed: 0,
        );

    return AlertDialog(
      title: const Text('Baixando mapa da fazenda'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: progress.fraction),
          const SizedBox(height: 12),
          Text('${progress.processed} de ${progress.total} tiles'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Continuar em segundo plano'),
        ),
        TextButton(
          onPressed: () {
            ref
                .read(farmMapDownloadControllerProvider.notifier)
                .cancel(widget.farmId);
          },
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

bool farmHasDrawablePolygons(List<FarmLinkedFieldSummary>? fields) {
  if (fields == null) return false;
  return fields.any((field) => field.vertices.length >= 3);
}

/// Linha própria, abaixo de Talhões. A linha Mapa | NDVI | Novo não tem espaço.
class FarmMapDownloadButton extends ConsumerWidget {
  final String farmId;
  final List<FarmLinkedFieldSummary>? fields;

  const FarmMapDownloadButton({
    super.key,
    required this.farmId,
    required this.fields,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = farmHasDrawablePolygons(fields);
    final color = enabled ? PremiumTokens.brandGreen : Colors.grey;
    final job = ref.watch(farmMapDownloadControllerProvider)[farmId];
    final isDownloading = job?.isRunning ?? false;

    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton.icon(
            onPressed: enabled
                ? () => downloadFarmSatelliteMap(
                      context: context,
                      ref: ref,
                      farmId: farmId,
                      fields: fields!,
                    )
                : null,
            icon: Icon(Icons.download_rounded, color: color),
            label: Text(
              'Baixar mapa',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
          if (isDownloading)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                'Baixando mapa… ${job!.percent}%',
                style: const TextStyle(
                  color: PremiumTokens.brandGreen,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
