import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/config/map_config.dart';
import '../../../core/constants/layout_constants.dart';
import '../../../core/domain/map_models.dart';
import '../../../core/state/map_state.dart';
import '../../../core/ui/sheets/sheet_tokens.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import 'widgets/map_offline_widgets.dart';
import '../../theme/premium/design_tokens.dart';

class LayersSheet extends ConsumerWidget {
  static const _accent = PremiumTokens.brandGreenDark;

  final VoidCallback? onClose; // 🔧 FIX: Callback de fechamento externo
  final Future<void> Function()? onCoordinateSearch;
  final Future<void> Function()? onMunicipalitySearch;
  final Future<void> Function()? onDownloadOfflineArea;
  final bool renderTilePreviews;

  const LayersSheet({
    super.key,
    this.onClose,
    this.onCoordinateSearch,
    this.onMunicipalitySearch,
    this.onDownloadOfflineArea,
    this.renderTilePreviews = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLayer = ref.watch(activeLayerProvider);

    // Material (não Container/DecoratedBox) evita assert Flutter 3.44+
    // "ListTile background/ink may be invisible" sob fundo colorido.
    final isIos = soloForteSheetIsIos(context);
    final bg = isIos
        ? SoloForteSheetSkinIos.background
        : SoloForteSheetTokens.sheetBackground;
    final radius = isIos
        ? SoloForteSheetSkinIos.sheetRadius
        : SoloForteSheetTokens.borderRadius;

    return Material(
      color: bg,
      borderRadius: BorderRadius.vertical(top: Radius.circular(radius)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Camadas',
                    style: TextStyle(
                      fontSize: isIos ? 16 : SoloForteSheetTokens.titleFontSize,
                      fontWeight: isIos
                          ? FontWeight.w700
                          : SoloForteSheetTokens.titleWeight,
                      color: isIos
                          ? SoloForteSheetSkinIos.titleColor
                          : SoloForteSheetTokens.titleColor,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      onClose ??
                      () => Navigator.of(context, rootNavigator: false).pop(),
                  child: Text(
                    'Cancelar',
                    style: TextStyle(
                      color: isIos
                          ? SoloForteSheetSkinIos.ghostText
                          : _accent,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: isIos
                ? SoloForteSheetSkinIos.rowDivider
                : SoloForteSheetTokens.divider,
          ),
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
                            LayerType.standard,
                            mapTilerApiKey: MapConfig.kMapTilerApiKey,
                          ),
                          label: 'Mapa',
                          isSelected: currentLayer == LayerType.standard,
                          renderTilePreview: renderTilePreviews,
                          onTap: () => ref
                              .read(activeLayerProvider.notifier)
                              .setLayer(LayerType.standard),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                MapOfflineStatusCard(
                  onDownloadOfflineArea: onDownloadOfflineArea,
                ),
                if (onMunicipalitySearch != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.location_city_outlined,
                      color: isIos
                          ? SoloForteSheetSkinIos.iconStroke
                          : Colors.white70,
                    ),
                    title: Text(
                      'Ir para município',
                      style: TextStyle(
                        color: isIos
                            ? SoloForteSheetSkinIos.titleColor
                            : Colors.white,
                      ),
                    ),
                    onTap: onMunicipalitySearch,
                  ),
                if (onCoordinateSearch != null)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.search_rounded,
                      color: isIos
                          ? SoloForteSheetSkinIos.iconStroke
                          : Colors.white70,
                    ),
                    title: Text(
                      'Ir para coordenada',
                      style: TextStyle(
                        color: isIos
                            ? SoloForteSheetSkinIos.titleColor
                            : Colors.white,
                      ),
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
    final isIos = soloForteSheetIsIos(context);
    final labelColor = isIos
        ? (isSelected
            ? SoloForteSheetSkinIos.titleColor
            : SoloForteSheetSkinIos.subtitleColor)
        : (isSelected ? Colors.white : Colors.white60);
    final selectionBorder = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : _accent;

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
                            color: selectionBorder,
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
                color: labelColor,
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
