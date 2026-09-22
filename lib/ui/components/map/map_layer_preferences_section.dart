import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/cerrado_satellite_overlay.dart';
import '../../../core/services/local_geotiff_service.dart';
import '../../../core/state/map_state.dart';
import '../../../core/state/map_ui_providers.dart';

/// Ajustes de mapa que se fazem uma vez. A ficha do mapa não mostra mais isto.
class MapLayerPreferencesSection extends ConsumerWidget {
  const MapLayerPreferencesSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final labels = ref.watch(mapSatelliteLabelsEnabledProvider);
    final cerrado = ref.watch(cerradoSatelliteOverlayEnabledProvider);
    final borders = ref.watch(mapStateBoundariesEnabledProvider);
    final wms = ref.watch(externalWmsLayerProvider);
    final raster = ref.watch(externalRasterLayerProvider);
    final camera = ref.watch(mapCameraSnapshotProvider);
    final inCerrado = camera != null &&
        CerradoSatelliteOverlay.isWithinBounds(
          camera.center.latitude,
          camera.center.longitude,
        );

    return Column(
      children: [
        SwitchListTile(
          title: const Text('Nomes e estradas'),
          subtitle: Text(
            labels
                ? 'Mostra cidades, estradas e contexto sobre o satélite.'
                : 'Satélite puro, sem labels.',
          ),
          value: labels,
          onChanged: (enabled) {
            HapticFeedback.selectionClick();
            ref.read(mapSatelliteLabelsEnabledProvider.notifier).setEnabled(enabled);
          },
        ),
        SwitchListTile(
          title: const Text('Satélite Cerrado (INPE)'),
          subtitle: Text(
            inCerrado
                ? 'Mosaico INPE (${CerradoSatelliteOverlay.acquisitionLabel}).'
                : 'Disponível no bioma Cerrado. Imagens INPE '
                    '${CerradoSatelliteOverlay.acquisitionLabel}.',
          ),
          value: cerrado,
          onChanged: (enabled) {
            HapticFeedback.selectionClick();
            ref
                .read(cerradoSatelliteOverlayEnabledProvider.notifier)
                .setEnabled(enabled);
          },
        ),
        SwitchListTile(
          title: const Text('Divisas estaduais'),
          subtitle: Text(
            borders
                ? 'Exibe limites oficiais das UFs (IBGE) sobre o mapa.'
                : 'Oculta as fronteiras estaduais.',
          ),
          value: borders,
          onChanged: (enabled) {
            HapticFeedback.selectionClick();
            ref
                .read(mapStateBoundariesEnabledProvider.notifier)
                .setEnabled(enabled);
          },
        ),
        SwitchListTile(
          title: const Text('WMS Externa'),
          subtitle: Text(
            wms.enabled
                ? 'Ative somente se você tiver a URL de um servidor WMS.'
                : 'Desativada: o mapa usa apenas as camadas padrão do SoloForte. '
                    'Ative somente se você tiver a URL de um servidor WMS.',
          ),
          value: wms.enabled,
          onChanged: (enabled) {
            ref.read(externalWmsLayerProvider.notifier).update(
                  wms.copyWith(enabled: enabled),
                );
          },
        ),
        ListTile(
          title: const Text('Configurar WMS'),
          subtitle: Text(
            wms.layers.isEmpty ? 'URL do servidor' : 'Ativa: ${wms.layers}',
          ),
          onTap: () => showMapWmsConfigDialog(context, ref, wms),
        ),
        SwitchListTile(
          title: const Text('Raster Custom (XYZ/GeoTIFF)'),
          subtitle: const Text(
            'Desativado: nenhuma imagem extra é exibida. Ative para '
            'importar ortofoto, GeoTIFF ou tiles XYZ configurados.',
          ),
          value: raster.enabled,
          onChanged: (enabled) {
            ref.read(externalRasterLayerProvider.notifier).update(
                  raster.copyWith(enabled: enabled),
                );
          },
        ),
        ListTile(
          title: const Text('Configurar Raster'),
          subtitle: Text(raster.enabled ? 'GeoTIFF' : 'Toque para definir a fonte'),
          onTap: () => showMapRasterConfigDialog(context, ref, raster),
        ),
      ],
    );
  }
}

Future<void> showMapWmsConfigDialog(
  BuildContext context,
  WidgetRef ref,
  ExternalWmsLayerConfig current,
) async {
  final urlController = TextEditingController(text: current.baseUrl);
  final layersController = TextEditingController(text: current.layers);
  final formatController = TextEditingController(text: current.format);
  final versionController = TextEditingController(text: current.version);
  final crsController = TextEditingController(text: current.crs);

  await showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Configurar WMS'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: urlController,
              decoration: const InputDecoration(labelText: 'Base URL WMS'),
            ),
            TextField(
              controller: layersController,
              decoration: const InputDecoration(labelText: 'Layers'),
            ),
            TextField(
              controller: formatController,
              decoration: const InputDecoration(labelText: 'Format'),
            ),
            TextField(
              controller: versionController,
              decoration: const InputDecoration(labelText: 'Version'),
            ),
            TextField(
              controller: crsController,
              decoration: const InputDecoration(labelText: 'CRS/SRS'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () {
            ref.read(externalWmsLayerProvider.notifier).update(
                  current.copyWith(
                    baseUrl: urlController.text.trim(),
                    layers: layersController.text.trim(),
                    format: formatController.text.trim().isEmpty
                        ? 'image/png'
                        : formatController.text.trim(),
                    version: versionController.text.trim().isEmpty
                        ? '1.1.1'
                        : versionController.text.trim(),
                    crs: crsController.text.trim().isEmpty
                        ? 'EPSG:3857'
                        : crsController.text.trim(),
                  ),
                );
            Navigator.of(ctx).pop();
          },
          child: const Text('Salvar'),
        ),
      ],
    ),
  );
}

Future<void> showMapRasterConfigDialog(
  BuildContext context,
  WidgetRef ref,
  ExternalRasterLayerConfig current,
) async {
  final urlController = TextEditingController(text: current.urlTemplate);
  final endpointController = TextEditingController(
    text: current.geoTiffTileEndpoint,
  );
  final opacityController = TextEditingController(
    text: current.opacity.toStringAsFixed(2),
  );
  var isGeoTiff = current.isGeoTiff;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setLocal) => AlertDialog(
        title: const Text('Configurar Raster'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Fonte GeoTIFF (COG URL)'),
                value: isGeoTiff,
                onChanged: (v) => setLocal(() => isGeoTiff = v),
              ),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  labelText: isGeoTiff
                      ? 'URL do GeoTIFF/COG'
                      : 'URL Template ({z}/{x}/{y})',
                ),
              ),
              if (isGeoTiff)
                TextField(
                  controller: endpointController,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint tiles (ex.: https://titiler.xyz)',
                  ),
                ),
              TextField(
                controller: opacityController,
                decoration: const InputDecoration(labelText: 'Opacidade 0-1'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _importLocalGeoTiff(ctx, ref, current),
                icon: const Icon(Icons.upload_file_outlined),
                label: const Text('Importar GeoTIFF local'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              final opacity = double.tryParse(opacityController.text) ?? 0.75;
              final navigator = Navigator.of(ctx);
              await const LocalGeoTiffService().deleteImportedOverlay(
                current.localPngPath,
              );
              ref.read(externalRasterLayerProvider.notifier).update(
                    current.copyWith(
                      urlTemplate: urlController.text.trim(),
                      opacity: opacity.clamp(0.05, 1.0),
                      isGeoTiff: isGeoTiff,
                      geoTiffTileEndpoint: endpointController.text.trim().isEmpty
                          ? 'https://titiler.xyz'
                          : endpointController.text.trim(),
                      clearLocalGeoTiff: true,
                    ),
                  );
              navigator.pop();
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    ),
  );
}

Future<void> _importLocalGeoTiff(
  BuildContext context,
  WidgetRef ref,
  ExternalRasterLayerConfig current,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['tif', 'tiff'],
  );
  final path = result?.files.single.path;
  if (path == null) return;

  try {
    final imported = await const LocalGeoTiffService().importFile(path);
    await const LocalGeoTiffService().deleteImportedOverlay(
      current.localPngPath,
    );
    ref.read(externalRasterLayerProvider.notifier).update(
          current.copyWith(
            enabled: true,
            localPngPath: imported.pngPath,
            localSouth: imported.south,
            localWest: imported.west,
            localNorth: imported.north,
            localEast: imported.east,
          ),
        );
    if (!context.mounted) return;
    Navigator.of(context).pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('GeoTIFF local importado com sucesso.')),
    );
  } on LocalGeoTiffException catch (e) {
    if (!context.mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(e.message)));
  }
}
