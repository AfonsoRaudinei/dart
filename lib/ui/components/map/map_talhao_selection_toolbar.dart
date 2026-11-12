import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/layout_constants.dart';
import '../../../core/contracts/i_ndvi_field_presenter_provider.dart';
import '../../../core/contracts/ndvi_latest_summary.dart';
import '../../../core/domain/talhao_condicao.dart';
import '../../../core/state/map_ndvi_overlay.dart';
import '../../../core/state/map_ui_providers.dart';
import '../../../modules/ndvi/domain/entities/ndvi_image.dart';
import '../../../modules/ndvi/domain/ndvi_image_utils.dart';
import '../../../modules/ndvi/presentation/providers/ndvi_date_nav_provider.dart';
import '../../../modules/ndvi/presentation/providers/ndvi_providers.dart';
import '../../../modules/drawing/domain/drawing_feature_actions_mode.dart';
import '../../../modules/drawing/domain/drawing_state.dart';
import '../../../modules/drawing/domain/models/drawing_models.dart';
import '../../../modules/drawing/presentation/drawing_compact_selection_actions.dart';
import '../../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../screens/map/handlers/visit_check_in_talhoes.dart';
import 'map_sheet_state.dart';

/// Geometria, Dados e, quando há id, NDVI + P&B + Status.
/// Teste não entra na contagem de Status.
int talhaoSelectionToolbarChipCount({
  required bool showNdvi,
  bool includeStatus = true,
}) {
  if (!showNdvi) return 2;
  return includeStatus ? 5 : 4;
}

/// Talhão cujo painel de condição está aberto neste card. null = fechado.
final mapTalhaoStatusPanelFieldIdProvider = StateProvider<String?>(
  (ref) => null,
);

/// Largura de cada chip. 5×58 + 4 divisores = 294, dentro dos 300 úteis em 375.
const _talhaoToolbarChipWidth = 58.0;

/// Toolbar contextual (ícone + label curto) ancorada na feature selecionada
/// no fluxo compact — espírito Apple Maps.
class MapTalhaoSelectionToolbar extends ConsumerStatefulWidget {
  const MapTalhaoSelectionToolbar({
    super.key,
    required this.mapController,
    required this.setSheetState,
    this.onCollapseDrawSheet,
  });

  final MapController mapController;
  final void Function(MapSheetState? state, String reason) setSheetState;
  final VoidCallback? onCollapseDrawSheet;

  static const double toolbarHeight = 52;
  static const double horizontalPadding = 12;
  static const double edgeMargin = 8;

  @override
  ConsumerState<MapTalhaoSelectionToolbar> createState() =>
      _MapTalhaoSelectionToolbarState();
}

class _MapTalhaoSelectionToolbarState
    extends ConsumerState<MapTalhaoSelectionToolbar> {
  String? _condicaoOverrideFieldId;
  TalhaoCondicao? _condicaoOverride;

  TalhaoCondicao _condicaoFor(DrawingFeature feature) {
    if (_condicaoOverrideFieldId != null &&
        _condicaoOverrideFieldId != feature.id) {
      _condicaoOverrideFieldId = null;
      _condicaoOverride = null;
    }
    if (_condicaoOverrideFieldId == feature.id && _condicaoOverride != null) {
      return _condicaoOverride!;
    }
    return TalhaoCondicao.resolve(feature.properties.cor);
  }

  Future<void> _persistCondicao(String fieldId, TalhaoCondicao condicao) async {
    try {
      await applyVisitTalhaoCondicao(ref, fieldId: fieldId, condicao: condicao);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível marcar a condição.')),
      );
      return;
    }
    if (!mounted) return;
    setState(() {
      _condicaoOverrideFieldId = fieldId;
      _condicaoOverride = condicao;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(drawingControllerProvider);
    final sheetIsDraw = ref.watch(
      mapSheetStateProvider.select((s) => s?.type == MapSheetType.draw),
    );

    if (!_shouldShow(controller, sheetIsDraw)) {
      return const SizedBox.shrink();
    }

    final feature = controller.selectedFeature!;
    ref.watch(mapCameraSnapshotProvider);

    final anchor = drawingFeatureAnchorLatLng(feature);
    if (anchor == null) return const SizedBox.shrink();

    final screenPoint = widget.mapController.camera.latLngToScreenPoint(anchor);
    final size = MediaQuery.sizeOf(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    final toolbarWidth = _estimateToolbarWidth(feature);
    final showNdvi = feature.id.isNotEmpty;
    final isTestOverlay = feature.properties.tipo == DrawingType.teste;
    final showStatus = showNdvi && !isTestOverlay;
    final condicao = _condicaoFor(feature);
    final overlayFieldId = ref.watch(mapNdviOverlayFieldIdProvider);
    final dateChoices = ref.watch(mapNdviDateChoicesProvider);
    final dateSelection = ref.watch(mapNdviSelectedDateProvider);
    final dateError = ref.watch(mapNdviOverlayDateErrorProvider);
    final statusPanelFieldId = ref.watch(mapTalhaoStatusPanelFieldIdProvider);
    final showStatusPanel = showStatus && statusPanelFieldId == feature.id;
    final ndviOverlayHere =
        overlayFieldId != null && overlayFieldId == feature.id;
    final choiceImages = dateChoices.asData?.value ?? const <NdviImage>[];
    final showDateRow =
        !showStatusPanel &&
        ndviOverlayHere &&
        (dateChoices.isLoading ||
            dateChoices.hasError ||
            choiceImages.isNotEmpty);
    final showDateError =
        !showStatusPanel &&
        ndviOverlayHere &&
        dateError != null &&
        dateSelection != null &&
        dateError.fieldId == feature.id &&
        dateSelection.fieldId == feature.id &&
        dateError.dateKey == dateSelection.dateKey;
    final resolvedToolbarHeight =
        MapTalhaoSelectionToolbar.toolbarHeight +
        (showDateRow ? _mapNdviDateRowHeight : 0) +
        (showDateError ? _mapNdviDateErrorHeight : 0) +
        (showStatusPanel ? _mapNdviDateRowHeight : 0);

    ref.listen(mapNdviOverlaySummaryProvider, (previous, next) {
      _refreshDateChoicesAfterRaster(ref, next.asData?.value);
    });

    final offset = clampMapToolbarOffset(
      screenPoint: Offset(screenPoint.x, screenPoint.y),
      viewportSize: size,
      toolbarWidth: toolbarWidth,
      toolbarHeight: resolvedToolbarHeight,
      topInset: topInset,
      bottomInset: bottomInset,
      edgeMargin: MapTalhaoSelectionToolbar.edgeMargin,
    );

    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Material(
        elevation: 3,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        color: Colors.transparent,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xF7FFFFFF),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: MapTalhaoSelectionToolbar.toolbarHeight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ToolbarChip(
                          key: const Key('map_talhao_toolbar_edit_geometry'),
                          icon: Icons.edit_location_alt_outlined,
                          label: 'Geometria',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            DrawingCompactSelectionActions.editGeometry(
                              controller,
                            );
                          },
                        ),
                        _divider,
                        _ToolbarChip(
                          key: const Key('map_talhao_toolbar_edit_metadata'),
                          icon: Icons.edit_note_outlined,
                          label: 'Dados',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            DrawingCompactSelectionActions.requestMetadataSheet(
                              ref,
                            );
                            widget.setSheetState(
                              const MapSheetState(type: MapSheetType.draw),
                              'compact toolbar: edit metadata',
                            );
                          },
                        ),
                        if (showNdvi) ...[
                          _divider,
                          _ToolbarChip(
                            key: const Key('map_talhao_toolbar_ndvi'),
                            icon: Icons.grass_rounded,
                            label: 'NDVI',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _closeTalhaoStatusPanel(ref);
                              DrawingCompactSelectionActions.showNdviMap(
                                ref,
                                feature,
                                onCollapseWhileEditing:
                                    widget.onCollapseDrawSheet,
                              );
                            },
                          ),
                          _divider,
                          _ToolbarChip(
                            key: const Key('map_talhao_toolbar_bw'),
                            icon: Icons.filter_b_and_w_outlined,
                            label: 'P&B',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              _closeTalhaoStatusPanel(ref);
                              DrawingCompactSelectionActions.showMonochromeMap(
                                ref,
                                feature,
                                onCollapseWhileEditing:
                                    widget.onCollapseDrawSheet,
                              );
                            },
                          ),
                        ],
                        if (showStatus) ...[
                          _divider,
                          _ToolbarChip(
                            key: const Key('map_talhao_toolbar_status'),
                            icon: Icons.circle,
                            iconColor: Color(condicao.argb),
                            label: 'Status',
                            onTap: () {
                              HapticFeedback.lightImpact();
                              final open = ref.read(
                                mapTalhaoStatusPanelFieldIdProvider,
                              );
                              ref
                                  .read(
                                    mapTalhaoStatusPanelFieldIdProvider
                                        .notifier,
                                  )
                                  .state = open == feature.id
                                  ? null
                                  : feature.id;
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (showDateRow)
                    _MapNdviDateBar(
                      fieldId: feature.id,
                      fieldName: feature.properties.nome,
                      areaHa: feature.properties.areaHa,
                      choices: dateChoices,
                      selection: dateSelection,
                      barWidth: toolbarWidth,
                    ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    alignment: Alignment.topCenter,
                    child: showStatusPanel
                        ? _TalhaoCondicaoPanel(
                            current: condicao,
                            barWidth: toolbarWidth,
                            onSelect: (selected) =>
                                _persistCondicao(feature.id, selected),
                          )
                        : const SizedBox(width: 0, height: 0),
                  ),
                  if (showDateError)
                    _NdviDateErrorLine(
                      width: toolbarWidth,
                      onRetry: () {
                        ref.invalidate(mapNdviOverlaySummaryProvider);
                      },
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const Widget _divider = SizedBox(
    width: 1,
    height: 28,
    child: DecoratedBox(decoration: BoxDecoration(color: Color(0x1A000000))),
  );

  static bool _shouldShow(DrawingController controller, bool sheetIsDraw) {
    if (sheetIsDraw) return false;
    if (controller.isMultiSelectEnabled) return false;
    if (controller.featureActionsMode != DrawingFeatureActionsMode.compact) {
      return false;
    }
    if (controller.currentState != DrawingState.selected) return false;
    if (controller.interactionMode != DrawingInteraction.normal) return false;
    return controller.selectedFeature != null;
  }

  static double _estimateToolbarWidth(DrawingFeature feature) =>
      estimateMapTalhaoToolbarWidth(feature);
}

@visibleForTesting
double estimateMapTalhaoToolbarWidth(DrawingFeature feature) {
  final chips = talhaoSelectionToolbarChipCount(
    showNdvi: feature.id.isNotEmpty,
    includeStatus: feature.properties.tipo != DrawingType.teste,
  );
  return chips * _talhaoToolbarChipWidth + (chips - 1);
}

void _closeTalhaoStatusPanel(WidgetRef ref) {
  ref.read(mapTalhaoStatusPanelFieldIdProvider.notifier).state = null;
}

class _ToolbarChip extends StatelessWidget {
  const _ToolbarChip({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor = const Color(0xFF1D1D1F),
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _talhaoToolbarChipWidth,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1D1D1F),
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

/// Centroide simples do polígono para ancorar a toolbar.
LatLng? drawingFeatureAnchorLatLng(DrawingFeature feature) {
  final points = <LatLng>[];
  final geometry = feature.geometry;

  if (geometry is DrawingPolygon) {
    for (final ring in geometry.coordinates) {
      points.addAll(ring.map((p) => LatLng(p[1], p[0])));
    }
  } else if (geometry is DrawingMultiPolygon) {
    for (final polygon in geometry.coordinates) {
      for (final ring in polygon) {
        points.addAll(ring.map((p) => LatLng(p[1], p[0])));
      }
    }
  }

  if (points.isEmpty) return null;

  var sumLat = 0.0;
  var sumLng = 0.0;
  for (final p in points) {
    sumLat += p.latitude;
    sumLng += p.longitude;
  }
  return LatLng(sumLat / points.length, sumLng / points.length);
}

/// Posiciona a toolbar acima do ponto de ancoragem, com clamp nas bordas.
Offset clampMapToolbarOffset({
  required Offset screenPoint,
  required Size viewportSize,
  required double toolbarWidth,
  required double toolbarHeight,
  double topInset = 0,
  double bottomInset = 0,
  double edgeMargin = MapTalhaoSelectionToolbar.edgeMargin,
  double anchorGap = 12,
}) {
  var left = screenPoint.dx - toolbarWidth / 2;
  var top = screenPoint.dy - toolbarHeight - anchorGap;

  final minLeft = edgeMargin;
  final rightColumnReserve =
      kMapActionColumnRightInset + kMapActionColumnButtonSize;
  final maxLeft = math.max(
    edgeMargin,
    viewportSize.width - toolbarWidth - edgeMargin - rightColumnReserve,
  );
  final minTop = topInset + edgeMargin;
  final maxTop = math.max(
    minTop,
    viewportSize.height -
        bottomInset -
        kFabSafeArea -
        toolbarHeight -
        edgeMargin,
  );

  left = left.clamp(minLeft, maxLeft);
  top = top.clamp(minTop, maxTop);

  return Offset(left, top);
}

const _mapNdviDateRowHeight = 48.0;

class _TalhaoCondicaoPanel extends StatelessWidget {
  const _TalhaoCondicaoPanel({
    required this.current,
    required this.barWidth,
    required this.onSelect,
  });

  final TalhaoCondicao current;
  final double barWidth;
  final Future<void> Function(TalhaoCondicao condicao) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: barWidth,
      height: _mapNdviDateRowHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Row(
          children: [
            for (final condicao in TalhaoCondicao.values) ...[
              Expanded(
                child: _CondicaoPill(
                  key: Key('map_talhao_condicao_${condicao.name}'),
                  condicao: condicao,
                  selected: condicao == current,
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await onSelect(condicao);
                  },
                ),
              ),
              if (condicao != TalhaoCondicao.values.last)
                const SizedBox(width: 4),
            ],
          ],
        ),
      ),
    );
  }
}

class _CondicaoPill extends StatelessWidget {
  const _CondicaoPill({
    super.key,
    required this.condicao,
    required this.selected,
    required this.onTap,
  });

  final TalhaoCondicao condicao;
  final bool selected;
  final Future<void> Function() onTap;

  @override
  Widget build(BuildContext context) {
    final fill = Color(condicao.argb);
    final onFill = fill.computeLuminance() > 0.6
        ? const Color(0xFF1D1D1F)
        : const Color(0xFFFFFFFF);
    return Material(
      color: fill,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? const Color(0xFF1D1D1F)
                  : const Color(0x00000000),
              width: selected ? 2 : 0,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              condicao.label,
              maxLines: 1,
              style: TextStyle(
                color: onFill,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const _mapNdviDateErrorHeight = 36.0;
const _mapNdviRecentDateCount = 4;

void _refreshDateChoicesAfterRaster(WidgetRef ref, NdviLatestSummary? summary) {
  final fieldId = ref.read(mapNdviOverlayFieldIdProvider);
  if (summary == null || fieldId == null || fieldId.isEmpty) return;
  final images = ref.read(ndviImagesProvider(fieldId)).asData?.value;
  if (images == null) return;
  final key = ndviImageDateKey(summary.imageDate);
  for (final image in images) {
    if (ndviImageDateKey(image.imageDate) != key) continue;
    final summaryHasRaster =
        (summary.localPath != null && summary.localPath!.isNotEmpty) ||
        (summary.imageUrl != null && summary.imageUrl!.trim().isNotEmpty);
    if (!ndviImageHasRenderableData(image) && summaryHasRaster) {
      ref.invalidate(ndviImagesProvider(fieldId));
    }
    return;
  }
}

/// Abre o histórico. Se o usuário trocar a data no sheet, o mapa passa a
/// exibir essa data. Se o sheet só for aberto e fechado, a data do mapa fica.
Future<void> _openMapNdviHistoryFromToolbar(
  WidgetRef ref,
  BuildContext context, {
  required String fieldId,
  required String fieldName,
  double? areaHa,
}) async {
  var changed = false;
  final subscription = ref.listenManual<int>(ndviDateIndexProvider(fieldId), (
    previous,
    next,
  ) {
    if (previous != next) changed = true;
  });
  try {
    await ref
        .read(ndviFieldPresenterProvider)
        .showTalhaoSheet(
          context,
          fieldId: fieldId,
          fieldName: fieldName,
          areaHa: areaHa,
        );
    if (!changed) return;
    final images = await ref.read(ndviImagesProvider(fieldId).future);
    if (images.isEmpty) return;
    final index = ref.read(ndviDateIndexProvider(fieldId));
    final safeIndex = index.clamp(0, images.length - 1);
    ref
        .read(mapNdviSelectedDateProvider.notifier)
        .select(
          MapNdviDateSelection(
            fieldId: fieldId,
            dateKey: ndviImageDateKey(images[safeIndex].imageDate),
          ),
        );
  } finally {
    subscription.close();
  }
}

class _MapNdviDateBar extends ConsumerWidget {
  const _MapNdviDateBar({
    required this.fieldId,
    required this.fieldName,
    required this.areaHa,
    required this.choices,
    required this.selection,
    required this.barWidth,
  });

  final String fieldId;
  final String fieldName;
  final double? areaHa;
  final AsyncValue<List<NdviImage>> choices;
  final MapNdviDateSelection? selection;
  final double barWidth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return choices.when(
      loading: () => const SizedBox(
        height: _mapNdviDateRowHeight,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      error: (_, __) => _NdviDateErrorLine(
        width: barWidth,
        onRetry: () => ref.invalidate(ndviImagesProvider(fieldId)),
      ),
      data: (images) {
        if (images.isEmpty) return const SizedBox.shrink();
        final sorted = [...images]
          ..sort((a, b) => b.imageDate.compareTo(a.imageDate));
        final recent = sorted.take(_mapNdviRecentDateCount).toList();
        final selectedKey = selection != null && selection!.fieldId == fieldId
            ? selection!.dateKey
            : ndviImageDateKey(recent.first.imageDate);
        return SizedBox(
          width: barWidth,
          height: _mapNdviDateRowHeight,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              children: [
                for (final image in recent) ...[
                  ChoiceChip(
                    key: Key(
                      'map_talhao_ndvi_date_${ndviImageDateKey(image.imageDate)}',
                    ),
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                    label: Text(
                      ndviDateChipLabel(
                        image.imageDate,
                        cloudCoverage: image.cloudCoverage,
                      ),
                    ),
                    selected: ndviImageDateKey(image.imageDate) == selectedKey,
                    onSelected: (_) {
                      HapticFeedback.lightImpact();
                      ref
                          .read(mapNdviSelectedDateProvider.notifier)
                          .select(
                            MapNdviDateSelection(
                              fieldId: fieldId,
                              dateKey: ndviImageDateKey(image.imageDate),
                            ),
                          );
                    },
                  ),
                  const SizedBox(width: 6),
                ],
                TextButton(
                  key: const Key('map_talhao_ndvi_date_more'),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    _openMapNdviHistoryFromToolbar(
                      ref,
                      context,
                      fieldId: fieldId,
                      fieldName: fieldName,
                      areaHa: areaHa,
                    );
                  },
                  child: const Text('ver mais'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _NdviDateErrorLine extends StatelessWidget {
  const _NdviDateErrorLine({required this.width, required this.onRetry});

  final double width;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: _mapNdviDateErrorHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: [
            const Expanded(
              child: Text(
                'Erro ao carregar imagens NDVI',
                key: Key('map_talhao_ndvi_date_error'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ),
            GestureDetector(
              key: const Key('map_talhao_ndvi_date_retry'),
              onTap: onRetry,
              child: const Text(
                'Tentar novamente',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0A84FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
