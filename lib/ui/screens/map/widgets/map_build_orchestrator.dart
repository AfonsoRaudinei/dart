// ADR-032 F3 — Orquestrador de build() extraído de private_map_screen.dart.
// Contém toda a lógica de composição do mapa: canvas, layers, overlays, controls, sheet.
// private_map_screen.dart delega 100% do build() para este widget.
//
// Callbacks são injetados pelo State para manter encapsulamento de lógica de negócio.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/session/user_role.dart';
import '../../../../core/utils/map_logger.dart';
import '../../../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../../../modules/drawing/presentation/coordinators/drawing_close_coordinator.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_layers.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_map_gesture_overlay.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_state_indicator.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';
import '../../../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart'
    as occ;
import '../../../../modules/marketing/domain/enums/case_tipo.dart';
import '../../../../modules/settings/presentation/providers/user_profile_provider.dart';
import '../../../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../../../modules/dashboard/domain/location_settings.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../handlers/map_location_handler.dart';
import '../../../components/map/map_attribution_policy.dart';
import '../../../components/map/widgets/map_canvas.dart';
import '../../../components/map/widgets/map_layers.dart';
import '../../../../modules/clima/presentation/widgets/clima_radar_zoom_guard.dart';
import '../../../../modules/clima/presentation/widgets/radar_layer_widget.dart';
import '../../../components/map/widgets/map_markers.dart';
import '../../../components/map/widgets/map_controls_overlay.dart';
import '../../../components/map/widgets/map_offline_widgets.dart';
import '../../../components/map/widgets/isolated_marker_layers.dart';
import '../../../components/map/widgets/map_state_boundaries_layer.dart';
import '../../../components/map/widgets/map_tools_bottom_sheet.dart';
import '../../../components/map/widgets/map_destination_pin.dart';
import '../../../components/map/widgets/producer_map_context_card.dart';
import '../../../components/map/map_sheet_state.dart';
import '../providers/map_armed_mode_provider.dart';
import '../providers/map_ready_state_provider.dart';
import 'armed_mode_banner.dart';
import '../layers/talhao_polygon_layer.dart';
import 'drawing_map_behavior_listener.dart';
import 'map_performance_hosts.dart';

/// Orquestrador do build() de PrivateMapScreen.
///
/// ADR-032 F3: Extrai composição de layers/overlays/controls do build() principal.
/// Reduz private_map_screen.dart de ~708 linhas para <400 linhas.
///
/// Responsabilidades:
/// - Composição do FlutterMap canvas (tiles, layers, markers)
/// - Empilhamento de overlays (GPS, drawing state, armed banner)
/// - Posicionamento de controles (zoom, location, layer switcher)
/// - Gerenciamento do MapBottomSheet no Stack
///
/// Callbacks injetados pelo State para manter lógica de negócio encapsulada.
class MapBuildOrchestrator extends ConsumerWidget {
  final MapController mapController;
  final void Function(MapSheetState? state, String reason) setSheetState;
  final void Function(double lat, double lng) openOccurrenceSheet;
  final void Function(TapPosition tapPos, LatLng latLng) handleMapLongPress;
  final Future<void> Function() finishDrawing;
  final void Function() toggleDrawMode;
  final void Function() centerOnUser;
  final ValueChanged<MapLocationMode> onLocationModeChanged;
  final VoidCallback stopFollowing;
  final void Function() armOccurrenceMode;
  final void Function(CaseTipo tipo) armMarketingMode;
  final void Function(occ.Occurrence occurrence) handleOccurrencePinTap;
  final void Function() applyInitialViewport;
  final Future<void> Function() openCoordinateSearch;
  final Future<void> Function() openMunicipalitySearch;
  final Future<void> Function() downloadOfflineArea;

  const MapBuildOrchestrator({
    super.key,
    required this.mapController,
    required this.setSheetState,
    required this.openOccurrenceSheet,
    required this.handleMapLongPress,
    required this.finishDrawing,
    required this.toggleDrawMode,
    required this.centerOnUser,
    required this.onLocationModeChanged,
    required this.stopFollowing,
    required this.armOccurrenceMode,
    required this.armMarketingMode,
    required this.handleOccurrencePinTap,
    required this.applyInitialViewport,
    required this.openCoordinateSearch,
    required this.openMunicipalitySearch,
    required this.downloadOfflineArea,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopwatch = Stopwatch()..start();

    final drawingMetrics = ref.watch(drawingMapMetricsProvider);
    final activeLayer = ref.watch(activeLayerProvider);
    final isMapReady = ref.watch(mapReadyStateProvider);
    final tileConfig = MapConfig.tileConfigForLayer(
      activeLayer,
      mapTilerApiKey: MapConfig.kMapTilerApiKey,
    );

    // Seleciona só campos que afetam drag — evita rebuild do canvas no GPS/métricas.
    final freehandInteraction = ref.watch(
      drawingControllerProvider.select(
        (c) => (
          c.currentTool,
          c.currentState,
          c.isFreehandStrokeActive,
        ),
      ),
    );
    final disableMapDrag =
        freehandInteraction.$1 == DrawingTool.freehand &&
        (freehandInteraction.$2 == DrawingState.armed ||
            freehandInteraction.$2 == DrawingState.drawing ||
            freehandInteraction.$3);
    final sketchVertexActive = ref.watch(
      drawingControllerProvider.select(
        (c) =>
            c.selectedSketchVertexIndex != null || c.isDraggingSketchVertex,
      ),
    );
    final polygonSketchMode = ref.watch(
      drawingControllerProvider.select(
        (c) =>
            c.currentTool == DrawingTool.polygon &&
            (c.currentState == DrawingState.drawing ||
                c.currentState == DrawingState.armed) &&
            c.currentPoints.isNotEmpty,
      ),
    );
    final suppressMapMarkerTaps = ref.watch(
      drawingControllerProvider.select((c) => c.suppressesMapContextTaps),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stopwatch.stop();
      MapLogger.logRenderTime(stopwatch.elapsedMilliseconds);
    });

    return DrawingStateOverlay(
      state: drawingMetrics.state,
      tool: drawingMetrics.tool,
      child: Stack(
        children: [
          const MapGeofenceLifecycleHost(),
          ClimaRadarZoomGuard(mapController: mapController),
          MapInitialViewportListener(
            applyInitialViewport: applyInitialViewport,
          ),
          MapCanvas(
            mapController: mapController,
            interactionOptions:
                drawingMetrics.state == DrawingState.editing ||
                    sketchVertexActive
                ? const InteractionOptions(flags: InteractiveFlag.none)
                : disableMapDrag
                ? const InteractionOptions(
                    flags:
                        InteractiveFlag.all &
                        ~InteractiveFlag.rotate &
                        ~InteractiveFlag.drag,
                  )
                : null,
            onMapReady: () {
              // ADR-032 F1: _isMapReady → mapReadyStateProvider
              ref.read(mapReadyStateProvider.notifier).state = true;
              ref
                  .read(mapCameraSnapshotProvider.notifier)
                  .state = MapCameraSnapshot(
                center: mapController.camera.center,
                zoom: mapController.camera.zoom,
                visibleBounds: mapController.camera.visibleBounds,
              );
              applyInitialViewport();
            },
            onTap: (tapPos, point) {
              final drawCtrl = ref.read(drawingControllerProvider);

              if (drawCtrl.currentState == DrawingState.drawing ||
                  drawCtrl.currentState == DrawingState.armed) {
                if (drawCtrl.currentTool != DrawingTool.freehand) {
                  if (drawCtrl.selectedSketchVertexIndex != null ||
                      drawCtrl.isDraggingSketchVertex) {
                    drawCtrl.clearSketchVertexSelection();
                    return;
                  }
                  drawCtrl.appendDrawingPoint(point);
                }
                return;
              }

              if (drawCtrl.suppressesMapContextTaps) {
                return;
              }

              // 🎯 Prioridade 1a: Modo armado marketing
              if (ref.read(armedModeProvider) == ArmedMode.marketing) {
                ref.read(armedModeProvider.notifier).state = ArmedMode.none;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                handleMapLongPress(tapPos, point);
                return;
              }

              // 🎯 Prioridade 1b: Verificar modo armado de ocorrências
              if (ref.read(armedModeProvider) == ArmedMode.occurrences) {
                final lat = point.latitude;
                final lng = point.longitude;

                // Desarmar imediatamente para evitar múltiplos taps
                ref.read(armedModeProvider.notifier).state = ArmedMode.none;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();

                // Abrir sheet de criação de ocorrência com coordenadas
                openOccurrenceSheet(lat, lng);
                return; // Não processar lógica de talhão
              }

              if (drawCtrl.isMultiSelectEnabled ||
                  drawCtrl.currentState == DrawingState.idle ||
                  drawCtrl.currentState == DrawingState.selected) {
                final drawingFeature = drawCtrl.findFeatureAt(point);
                if (drawingFeature != null) {
                  if (drawCtrl.isMultiSelectEnabled) {
                    drawCtrl.toggleFeatureSelection(drawingFeature);
                  } else {
                    drawCtrl.selectFeature(drawingFeature);
                  }
                  HapticFeedback.selectionClick();
                  // 🔧 FIX-DRAW-SYNC: Reutilizar MapBottomSheet existente
                  setSheetState(
                    const MapSheetState(type: MapSheetType.draw),
                    'Feature tap: editing existing drawing',
                  );
                  return;
                }
              }

              // 🎯 Comportamento normal: Seleção de talhão
              final mapFields = ref.read(mapFieldsProvider);
              final fields = mapFields.valueOrNull ?? [];
              final selectedTalhaoId = ref.read(selectedTalhaoIdProvider);
              bool hit = false;

              for (final field in fields) {
                if (field.geometry == null) continue;
                final polygonPoints = TalhaoMapAdapter.toPolygon(field).points;

                if (TalhaoMapAdapter.isPointInside(point, polygonPoints)) {
                  ref.read(selectedTalhaoIdProvider.notifier).state = field.id;
                  hit = true;
                  HapticFeedback.selectionClick();

                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Talhão: ${field.name}'),
                      backgroundColor: PremiumTokens.brandGreen,
                      duration: const Duration(seconds: 1),
                    ),
                  );
                  break; // Stop on first hit
                }
              }

              if (!hit) {
                // Deselect if tapping empty space
                if (selectedTalhaoId != null) {
                  ref.read(selectedTalhaoIdProvider.notifier).state = null;
                  HapticFeedback.lightImpact();
                }
              }
            },
            onLongPress: (tapPos, point) {
              if (ref.read(drawingControllerProvider).suppressesMapContextTaps) {
                return;
              }
              handleMapLongPress(tapPos, point);
            },
            onPositionChanged: (pos, hasGesture) {
              ref
                  .read(mapCameraSnapshotProvider.notifier)
                  .state = MapCameraSnapshot(
                center: pos.center,
                zoom: pos.zoom,
                visibleBounds: pos.visibleBounds,
              );
              if (hasGesture) {
                final locationMode = ref.read(mapLocationModeProvider);
                if (locationMode == MapLocationMode.following ||
                    locationMode == MapLocationMode.northLocked) {
                  ref.read(mapLocationModeProvider.notifier).state =
                      MapLocationMode.idle;
                  stopFollowing();
                }

                MapLogger.logEvent(
                  'Pan/Zoom: Center=${pos.center.latitude.toStringAsFixed(4)},'
                  '${pos.center.longitude.toStringAsFixed(4)} '
                  'Zoom=${pos.zoom.toStringAsFixed(1)}',
                );
                MapLogger.logEvent('Clustering Active: ${pos.zoom < 15}');
              }
            },
            maxZoom: tileConfig.maxZoom,
            children: [
              // Layer base de tiles
              const MapLayersWidget(),

              const MapStateBoundariesLayer(),

              // Cobertura offline baixada para a camada ativa
              const MapOfflineCoverageLayer(),

              // Polígonos de talhões
              // ADR-030 F3: extraído para TalhaoPolygonLayer
              const TalhaoPolygonLayer(),

              // Camada de Desenho
              // 🔧 FIX-DRAW-RACE: Usar ref.read() para evitar referência stale
              DrawingLayerWidget(
                controller: ref.read(drawingControllerProvider),
                onFeatureTap: (feature) {
                  final drawCtrl = ref.read(drawingControllerProvider);
                  if (drawCtrl.suppressesMapContextTaps) return;
                  ref.read(drawingControllerProvider).selectFeature(feature);
                  HapticFeedback.selectionClick();
                },
                onDrawingComplete: finishDrawing,
              ),

              // 🔧 Camada de Edição (Vertex Handles)
              DrawingEditLayer(
                controller: ref.read(drawingControllerProvider),
                mapController: mapController,
                onPolygonClose: () {
                  finishDrawing();
                },
              ),

              // ADR-043 — Radar acima de talhões/desenho, abaixo de markers
              IgnorePointer(
                ignoring: polygonSketchMode,
                child: const ClimaRadarTileLayerWidget(),
              ),

              // 🔒 MARKERS ISOLADOS: Não rebuildam por GPS/zoom/pan
              AbsorbPointer(
                absorbing: suppressMapMarkerTaps,
                child: const MapMarkersWidget(),
              ),

              // Markers de ocorrências (isolados)
              AbsorbPointer(
                absorbing: suppressMapMarkerTaps,
                child: IsolatedOccurrenceMarkersLayer(
                  onOccurrenceTap: handleOccurrencePinTap,
                ),
              ),

              // Markers de Marketing (isolados — Sprint 8 Performance)
              AbsorbPointer(
                absorbing: suppressMapMarkerTaps,
                child: const IsolatedMarketingMarkersLayer(),
              ),

              Consumer(
                builder: (context, ref, _) {
                  final destination = ref.watch(
                    destinationCoordinateMarkerProvider,
                  );
                  if (destination == null) return const SizedBox.shrink();
                  return MarkerLayer(
                    markers: [
                      Marker(
                        point: destination,
                        width: 44,
                        height: 44,
                        alignment: Alignment.bottomCenter,
                        child: const MapDestinationPin(size: 44),
                      ),
                    ],
                  );
                },
              ),

              // 🎯 ÚNICA LAYER QUE REBUILDA: Localização GPS
              const IsolatedUserLocationLayer(),

              RichAttributionWidget(
                attributions: [TextSourceAttribution(tileConfig.attribution)],
                showFlutterMapAttribution: false,
                alignment: AttributionAlignment.bottomLeft,
                // Sem auto-expand: o popup preto parecia "sombra" no mapa.
                // Atribuição continua acessível pelo botão info.
                popupInitialDisplayDuration:
                    kMapAttributionPopupInitialDuration,
                popupBorderRadius: BorderRadius.circular(8),
                popupBackgroundColor: Colors.black.withValues(alpha: 0.72),
              ),
            ],
          ),

          DrawingMapGestureOverlay(
            mapController: mapController,
            isMapReady: isMapReady,
          ),

          RepaintBoundary(
            child: _MapControlsHost(
              mapController: mapController,
              drawingMetrics: drawingMetrics,
              setSheetState: setSheetState,
              centerOnUser: centerOnUser,
              onLocationModeChanged: onLocationModeChanged,
              toggleDrawMode: toggleDrawMode,
              openCoordinateSearch: openCoordinateSearch,
              openMunicipalitySearch: openMunicipalitySearch,
              downloadOfflineArea: downloadOfflineArea,
              armOccurrenceMode: armOccurrenceMode,
              armMarketingMode: armMarketingMode,
              finishDrawing: finishDrawing,
            ),
          ),
          DrawingMapBehaviorListener(
            mapController: mapController,
            isMapReady: isMapReady,
            onCenterOnUser: centerOnUser,
          ),
          const MapGpsOverlaysHost(),
          MapBottomSheetOverlayHost(
            setSheetState: setSheetState,
            onLocationRequested: centerOnUser,
            onFocusDrawingFeature: (feature) =>
                focusDrawingFeatureOnMap(mapController, feature),
          ),
          const ArmedModeBanner(),
        ],
      ),
    );
  }
}

class _MapControlsHost extends ConsumerWidget {
  const _MapControlsHost({
    required this.mapController,
    required this.drawingMetrics,
    required this.setSheetState,
    required this.centerOnUser,
    required this.onLocationModeChanged,
    required this.toggleDrawMode,
    required this.openCoordinateSearch,
    required this.openMunicipalitySearch,
    required this.downloadOfflineArea,
    required this.armOccurrenceMode,
    required this.armMarketingMode,
    required this.finishDrawing,
  });

  final MapController mapController;
  final DrawingMapMetrics drawingMetrics;
  final void Function(MapSheetState? state, String reason) setSheetState;
  final VoidCallback centerOnUser;
  final ValueChanged<MapLocationMode> onLocationModeChanged;
  final VoidCallback toggleDrawMode;
  final Future<void> Function() openCoordinateSearch;
  final Future<void> Function() openMunicipalitySearch;
  final Future<void> Function() downloadOfflineArea;
  final VoidCallback armOccurrenceMode;
  final void Function(CaseTipo tipo) armMarketingMode;
  final Future<void> Function() finishDrawing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDrawMode = ref.watch(
      mapSheetStateProvider.select((s) => s?.type == MapSheetType.draw),
    );
    final isMapReady = ref.watch(mapReadyStateProvider);
    final isProdutor = ref.watch(
      currentUserRoleProvider.select((r) => r.isProdutor),
    );
    final armedMode = ref.watch(armedModeProvider);

    return MapControlsOverlay(
      onCenterUser: centerOnUser,
      onLocationModeChanged: onLocationModeChanged,
      onToggleDrawMode: toggleDrawMode,
      onOpenMapTools: () => MapToolsBottomSheet.show(
        context: context,
        drawingController: ref.read(drawingControllerProvider),
        onCoordinateSearch: openCoordinateSearch,
        onMunicipalitySearch: openMunicipalitySearch,
        onDownloadOfflineArea: downloadOfflineArea,
      ),
      onToggleOccurrenceMode: () {
        if (armedMode == ArmedMode.occurrences) {
          ref.read(armedModeProvider.notifier).state = ArmedMode.none;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          if (ref.read(isModalOpenProvider)) {
            Navigator.of(context).pop();
          }
          setSheetState(null, 'Toggle OFF: Closing occurrence sheet');
        } else {
          armOccurrenceMode();
        }
      },
      onCreateResultadoCase: () => armMarketingMode(CaseTipo.resultado),
      onCreateAntesDepoisCase: () => armMarketingMode(CaseTipo.antesDepois),
      onCreateAvaliacaoCase: () => armMarketingMode(CaseTipo.avaliacao),
      isMarketingMode: armedMode == ArmedMode.marketing,
      isDrawMode: isDrawMode,
      isOccurrenceMode: armedMode == ArmedMode.occurrences,
      isCheckInActive: ref.watch(
        visitControllerProvider.select(
          (v) => v.valueOrNull?.status == 'active',
        ),
      ),
      showCheckInAction: !isProdutor,
      topLeftCard: isProdutor
          ? ProducerMapContextCard(
              onFocusFarm: (fields) {
                final points = fields
                    .expand((field) => TalhaoMapAdapter.toPolygon(field).points)
                    .toList(growable: false);
                if (points.isEmpty) return false;
                mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(56),
                  ),
                );
                return true;
              },
              onFocusField: (field) {
                final points = TalhaoMapAdapter.toPolygon(field).points;
                if (points.isEmpty) return false;
                mapController.fitCamera(
                  CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(points),
                    padding: const EdgeInsets.all(56),
                  ),
                );
                return true;
              },
            )
          : null,
      drawingState: drawingMetrics.state,
      onFinishDrawing: finishDrawing,
      onCancelDrawing: () {
        ref.read(drawingControllerProvider).cancelOperation();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Desenho cancelado'),
            duration: Duration(seconds: 2),
          ),
        );
      },
      onSaveEdit: () => ref.read(drawingControllerProvider).saveEdit(),
      onCancelEdit: () => ref.read(drawingControllerProvider).cancelEdit(),
      onUndoEdit: () => ref.read(drawingControllerProvider).undoEdit(),
      onRedoEdit: () => ref.read(drawingControllerProvider).redoEdit(),
      onUndoDrawing: () =>
          ref.read(drawingControllerProvider).undoDrawingPoint(),
      canUndo: drawingMetrics.canUndo,
      canRedo: drawingMetrics.canRedo,
      hasSelfIntersection: drawingMetrics.hasSelfIntersection,
      measurementAreaHa: drawingMetrics.measureAreaHa,
      measurementPerimeterKm: drawingMetrics.measurePerimeterKm,
      measurementAzimuthDeg: drawingMetrics.measureAzimuthDeg,
      gpsAccuracyM: drawingMetrics.gpsAccuracyM ?? 0,
      currentCenter: isMapReady
          ? mapController.camera.center
          : const LatLng(0, 0),
      currentZoom: isMapReady ? mapController.camera.zoom : 13.0,
      onTabSelected: (index, source) async {
        final sheetTypeMap = {
          2: MapSheetType.occurrences,
          3: MapSheetType.checkIn,
          4: MapSheetType.layers,
        };

        final currentType = ref.read(mapSheetStateProvider)?.type;
        final newType = sheetTypeMap[index];

        if (currentType == MapSheetType.draw && currentType != newType) {
          final decision = await DrawingCloseCoordinator.handle(
            context,
            controller: ref.read(drawingControllerProvider),
            intent: DrawingCloseIntent.switchPanel,
          );
          if (!decision.shouldCloseSheet) {
            return;
          }
          if (!context.mounted) {
            return;
          }
        }

        if (currentType == newType) {
          if (ref.read(isModalOpenProvider)) {
            Navigator.of(context).pop();
          }
          setSheetState(
            null,
            'MapControlsOverlay: Toggle Close (Source: $source)',
          );
        } else {
          if (newType == MapSheetType.checkIn) {
            final isActive =
                ref.read(visitControllerProvider).valueOrNull?.status ==
                'active';
            if (!isActive) {
              final locationFix = ref.read(locationStreamProvider).valueOrNull;
              final accuracyM = locationFix?.accuracyM;
              if (!isGnssAccuracyAcceptableForCheckIn(accuracyM)) {
                if (accuracyM != null) {
                  MapLocationHandler.showGpsLowAccuracyMessage(
                    context: context,
                    accuracyMeters: locationFix!.effectiveAccuracyM,
                  );
                } else {
                  MapLocationHandler.showGPSRequiredMessage(
                    ref: ref,
                    context: context,
                  );
                }
                return;
              }
            }
          }

          if (ref.read(isModalOpenProvider)) {
            Navigator.of(context).pop();
            ref.read(modalGenerationProvider.notifier).state++;
            ref.read(isModalOpenProvider.notifier).state = false;
          }
          setSheetState(
            MapSheetState(type: newType!),
            'MapControlsOverlay: Select Tab $newType (Source: $source)',
          );
        }
        ref.read(pendingOccurrenceLocationProvider.notifier).state = null;
      },
    );
  }
}
