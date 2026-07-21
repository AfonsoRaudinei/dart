import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/map_config.dart';
import '../../../core/constants/layout_constants.dart';
import '../../../core/design/sf_icons.dart';
import '../../../core/domain/map_models.dart';
import '../../../core/services/local_geotiff_service.dart';
import '../../../core/contracts/i_radar_overlay_controller_provider.dart';
import '../../../core/state/map_state.dart';
import '../../../core/ui/sheets/sheet_tokens.dart';
import 'widgets/map_offline_widgets.dart';
import '../../theme/premium/design_tokens.dart';
import '../../../modules/clima/presentation/providers/radar_providers.dart';

class LayersSheet extends ConsumerWidget {
  static const _accent = PremiumTokens.brandGreenDark;

  final VoidCallback? onClose; // 🔧 FIX: Callback de fechamento externo
  final Future<void> Function()? onCoordinateSearch;
  final Future<void> Function()? onDownloadOfflineArea;
  final bool renderTilePreviews;

  const LayersSheet({
    super.key,
    this.onClose,
    this.onCoordinateSearch,
    this.onDownloadOfflineArea,
    this.renderTilePreviews = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLayer = ref.watch(activeLayerProvider);
    final showMarkers = ref.watch(showMarkersProvider);
    final showRadar = ref.watch(climaRadarEnabledProvider);
    final wms = ref.watch(externalWmsLayerProvider);
    final raster = ref.watch(externalRasterLayerProvider);

    return Container(
      decoration: const BoxDecoration(
        color: SoloForteSheetTokens.sheetBackground,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(SoloForteSheetTokens.borderRadius),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Camadas',
                    style: TextStyle(
                      fontSize: SoloForteSheetTokens.titleFontSize,
                      fontWeight: SoloForteSheetTokens.titleWeight,
                      color: SoloForteSheetTokens.titleColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      onClose ??
                      () => Navigator.of(context, rootNavigator: false).pop(),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: _accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: SoloForteSheetTokens.divider),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = ((constraints.maxWidth - 24) / 4).clamp(
                      72.0,
                      96.0,
                    );
                    final itemHeight = itemWidth * 0.75;

                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _MapPreviewTile(
                          width: itemWidth,
                          height: itemHeight,
                          tileConfig: MapConfig.tileConfigForLayer(
                            LayerType.satellite,
                            mapTilerApiKey: MapConfig.kMapTilerApiKey,
                          ),
                          label: 'Satélite',
                          isSelected: currentLayer == LayerType.satellite,
                          renderTilePreview: renderTilePreviews,
                          onTap: () => ref
                              .read(activeLayerProvider.notifier)
                              .setLayer(LayerType.satellite),
                        ),
                        _MapPreviewTile(
                          width: itemWidth,
                          height: itemHeight,
                          tileConfig: MapConfig.tileConfigForLayer(
                            LayerType.relevo,
                            mapTilerApiKey: MapConfig.kMapTilerApiKey,
                          ),
                          label: 'Relevo',
                          isSelected: currentLayer == LayerType.relevo,
                          renderTilePreview: renderTilePreviews,
                          onTap: () => ref
                              .read(activeLayerProvider.notifier)
                              .setLayer(LayerType.relevo),
                        ),
                        _OverlayToggleTile(
                          width: itemWidth,
                          height: itemHeight,
                          label: 'Pinos',
                          isSelected: showMarkers,
                          activeAsset: _LayerAssets.pinsActive,
                          inactiveAsset: _LayerAssets.pinsInactive,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref.read(showMarkersProvider.notifier).toggle();
                          },
                        ),
                        _OverlayToggleTile(
                          width: itemWidth,
                          height: itemHeight,
                          label: 'Chuva',
                          isSelected: showRadar,
                          activeAsset: _LayerAssets.rainActive,
                          inactiveAsset: _LayerAssets.rainInactive,
                          onTap: () {
                            HapticFeedback.lightImpact();
                            final enabling = !showRadar;
                            ref
                                .read(radarOverlayControllerProvider)
                                .setEnabled(
                                  enabling,
                                  preferSatelliteLayer: enabling,
                                );
                          },
                        ),
                      ],
                    );
                  },
                ),
                if (showRadar) ...[
                  const SizedBox(height: 12),
                  const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 14, color: Colors.white60),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Mostra a chuva em tempo real (áreas em azul). '
                          'Use a camada Satélite para melhor contraste. '
                          'Pode não haver chuva na sua região agora.',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                MapOfflineStatusCard(
                  onDownloadOfflineArea: onDownloadOfflineArea,
                ),
                const SizedBox(height: kFabSafeArea),
                const Divider(color: SoloForteSheetTokens.divider),
                const SizedBox(height: 8),
                _AdvancedLayerTile(
                  icon: SFIcons.layers,
                  title: 'WMS Externa',
                  statusLabel: wms.enabled
                      ? (wms.layers.isEmpty ? 'Ativa' : 'Ativa: ${wms.layers}')
                      : 'Desativada',
                  enabled: wms.enabled,
                  hint: wms.enabled
                      ? 'Sobrepõe um mapa técnico externo (limites, hidrografia, '
                            'uso do solo). Toque no item para configurar a URL do servidor.'
                      : 'Desativada: o mapa usa apenas as camadas padrão do SoloForte. '
                            'Ative somente se você tiver a URL de um servidor WMS.',
                  onToggle: (v) {
                    ref
                        .read(externalWmsLayerProvider.notifier)
                        .update(wms.copyWith(enabled: v));
                  },
                  onConfigure: () => _showWmsConfigDialog(context, ref, wms),
                ),
                _AdvancedLayerTile(
                  icon: SFIcons.photoLibrary,
                  title: 'Raster Custom (XYZ/GeoTIFF)',
                  statusLabel: raster.enabled
                      ? (raster.hasLocalGeoTiff
                            ? 'Ativo · GeoTIFF local'
                            : raster.isGeoTiff
                            ? 'Ativo · GeoTIFF remoto'
                            : 'Ativo · XYZ')
                      : 'Desativado',
                  enabled: raster.enabled,
                  hint: raster.enabled
                      ? 'Sobrepõe uma imagem personalizada no mapa (ortofoto, NDVI, '
                            'mapa XYZ). Toque no item para trocar a fonte ou a opacidade.'
                      : 'Desativado: nenhuma imagem extra é exibida. Ative para '
                            'importar ortofoto, GeoTIFF ou tiles XYZ configurados.',
                  onToggle: (v) {
                    ref
                        .read(externalRasterLayerProvider.notifier)
                        .update(raster.copyWith(enabled: v));
                  },
                  onConfigure: () =>
                      _showRasterConfigDialog(context, ref, raster),
                ),
                if (onCoordinateSearch != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(
                      Icons.search_rounded,
                      color: Colors.white70,
                    ),
                    title: const Text(
                      'Ir para coordenada',
                      style: TextStyle(color: Colors.white),
                    ),
                    onTap: onCoordinateSearch,
                  ),
                const SizedBox(height: kFabSafeArea),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showWmsConfigDialog(
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
              ref
                  .read(externalWmsLayerProvider.notifier)
                  .update(
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

  Future<void> _showRasterConfigDialog(
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
    bool isGeoTiff = current.isGeoTiff;

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
                ref
                    .read(externalRasterLayerProvider.notifier)
                    .update(
                      current.copyWith(
                        urlTemplate: urlController.text.trim(),
                        opacity: opacity.clamp(0.05, 1.0),
                        isGeoTiff: isGeoTiff,
                        geoTiffTileEndpoint:
                            endpointController.text.trim().isEmpty
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
      ref
          .read(externalRasterLayerProvider.notifier)
          .update(
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
}

class _MapPreviewTile extends StatelessWidget {
  static const _accent = PremiumTokens.brandGreenDark;

  final double width;
  final double height;
  final MapLayerTileConfig tileConfig;
  final String label;
  final bool isSelected;
  final bool renderTilePreview;
  final VoidCallback onTap;

  const _MapPreviewTile({
    required this.width,
    required this.height,
    required this.tileConfig,
    required this.label,
    required this.isSelected,
    required this.renderTilePreview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _LayerGridTile(
      width: width,
      height: height,
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      child: renderTilePreview
          ? FlutterMap(
              options: const MapOptions(
                initialCenter: LatLng(-10.69, -48.39),
                initialZoom: 13.0,
                interactionOptions: InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: tileConfig.urlTemplate,
                  fallbackUrl: tileConfig.fallbackUrl,
                  subdomains: tileConfig.subdomains,
                  maxZoom: tileConfig.maxZoom,
                  maxNativeZoom: tileConfig.maxNativeZoom,
                  retinaMode:
                      tileConfig.retinaMode &&
                      RetinaMode.isHighDensity(context),
                ),
              ],
            )
          : DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    _accent.withValues(alpha: 0.16),
                  ],
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.white54,
                  size: 22,
                ),
              ),
            ),
    );
  }
}

class _LayerAssets {
  static const pinsInactive = 'assets/images/map_pins_inactive.jpg';
  static const pinsActive = 'assets/images/map_pins_active.jpg';
  static const rainInactive = 'assets/images/map_rain_inactive.jpg';
  static const rainActive = 'assets/images/map_rain_active.jpg';
}

/// Tile de toggle para Pinos e Radar de Chuva.
class _OverlayToggleTile extends StatelessWidget {
  final double width;
  final double height;
  final String label;
  final bool isSelected;
  final String activeAsset;
  final String inactiveAsset;
  final VoidCallback onTap;

  const _OverlayToggleTile({
    required this.width,
    required this.height,
    required this.label,
    required this.isSelected,
    required this.activeAsset,
    required this.inactiveAsset,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _LayerGridTile(
      width: width,
      height: height,
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      child: Image.asset(
        isSelected ? activeAsset : inactiveAsset,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// Moldura unificada dos quatro tiles da grade (satélite, relevo, pinos, chuva).
///
/// A borda de seleção é pintada por cima, sem alterar o tamanho do conteúdo —
/// evita desalinhamento visual entre tiles com imagem e tiles com mapa.
class _LayerGridTile extends StatelessWidget {
  static const _accent = PremiumTokens.brandGreenDark;
  static const _radius = 12.0;
  static const _borderWidth = 2.0;

  final double width;
  final double height;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  const _LayerGridTile({
    required this.width,
    required this.height,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(child: child),
                  if (isSelected)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_radius),
                          border: Border.all(
                            color: _accent,
                            width: _borderWidth,
                          ),
                        ),
                      ),
                    ),
                  if (isSelected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: _LayerSelectedBadge(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: width,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdvancedLayerTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String statusLabel;
  final bool enabled;
  final String hint;
  final ValueChanged<bool> onToggle;
  final VoidCallback onConfigure;

  const _AdvancedLayerTile({
    required this.icon,
    required this.title,
    required this.statusLabel,
    required this.enabled,
    required this.hint,
    required this.onToggle,
    required this.onConfigure,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: Icon(icon, color: Colors.white70),
          title: Text(title, style: const TextStyle(color: Colors.white)),
          subtitle: Text(
            statusLabel,
            style: const TextStyle(color: Colors.white60),
          ),
          trailing: Switch(value: enabled, onChanged: onToggle),
          onTap: onConfigure,
        ),
        Padding(
          padding: const EdgeInsets.only(left: 40, right: 8, bottom: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 14, color: Colors.white60),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LayerSelectedBadge extends StatelessWidget {
  const _LayerSelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: PremiumTokens.brandGreenDark,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 12),
    );
  }
}
