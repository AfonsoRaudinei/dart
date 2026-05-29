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
import '../../../../core/config/map_secrets.dart';
import '../../../../core/utils/map_logger.dart';
import '../../../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../../../modules/drawing/domain/drawing_state.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_layers.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_state_indicator.dart';
import '../../../../modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import '../../../../modules/drawing/presentation/widgets/gps_tracking_overlay.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/dashboard/providers/location_providers.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';
import '../../../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../../../modules/consultoria/occurrences/domain/occurrence.dart'
    as occ;
import '../../../../modules/marketing/domain/enums/case_tipo.dart';
import '../../../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../../../core/contracts/i_field_lookup_geofence_provider.dart';
import '../../../components/map/map_bottom_sheet.dart';
import '../../../components/map/widgets/map_canvas.dart';
import '../../../components/map/widgets/map_layers.dart';
import '../../../components/map/widgets/radar_layer_widget.dart';
import '../../../components/map/widgets/map_markers.dart';
import '../../../components/map/widgets/map_controls_overlay.dart';
import '../../../components/map/widgets/isolated_marker_layers.dart';
import '../../../components/map/widgets/map_tools_bottom_sheet.dart';
import '../../../components/map/map_sheet_state.dart';
import '../providers/map_armed_mode_provider.dart';
import '../providers/map_ready_state_provider.dart';
import 'armed_mode_banner.dart';
import '../layers/talhao_polygon_layer.dart';
import 'drawing_map_behavior_listener.dart';

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
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stopwatch = Stopwatch()..start();

    // Mantém GeofenceController ativo somente durante o ciclo de vida desta tela.
    ref.watch(iFieldLookupGeofenceProvider);

    // Apenas providers necessários para lógica de tap e polígonos
    final mapFields = ref.watch(mapFieldsProvider);
    final selectedTalhaoId = ref.watch(selectedTalhaoIdProvider);
    // ⚡ Otimização: Observar apenas currentState e currentTool
    // 🔧 FIX-DRAW-RACE: NÃO usar ref.watch para o controller usado em callbacks
    final drawingState = ref.watch(
      drawingControllerProvider.select((c) => c.currentState),
    );
    final drawingTool = ref.watch(
      drawingControllerProvider.select((c) => c.currentTool),
    );
    // Sprint 2: Undo/Redo — observar canUndo/canRedo granularmente
    final canUndo = ref.watch(
      drawingControllerProvider.select((c) => c.canUndo),
    );
    final canRedo = ref.watch(
      drawingControllerProvider.select((c) => c.canRedo),
    );
    final sheetState = ref.watch(mapSheetStateProvider);
    final isMapReady = ref.watch(mapReadyStateProvider);
    final activeLayer = ref.watch(activeLayerProvider);
    final tileConfig = MapConfig.tileConfigForLayer(
      activeLayer,
      mapTilerApiKey: kMapTilerApiKey,
    );

    // 🔒 LISTENERS PARA FOCO INICIAL (Idempotentes)
    // Observar carregamento dos fields (para Produtores)
    ref.listen(mapFieldsProvider, (prev, next) {
      final vp = ref.read(viewportStateProvider);
      if (vp != InitialViewportState.applied &&
          vp != InitialViewportState.aborted &&
          ref.read(mapReadyStateProvider)) {
        applyInitialViewport();
      }
    });

    // Observar disponibilidade de GPS (para Outros)
    ref.listen(locationStateProvider, (prev, next) {
      final vp = ref.read(viewportStateProvider);
      if (vp != InitialViewportState.applied &&
          vp != InitialViewportState.aborted &&
          ref.read(mapReadyStateProvider)) {
        applyInitialViewport();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      stopwatch.stop();
      MapLogger.logRenderTime(stopwatch.elapsedMilliseconds);
    });

    return DrawingStateOverlay(
      state: drawingState,
      tool: drawingTool,
      child: Stack(
        children: [
          MapCanvas(
            mapController: mapController,
            onMapReady: () {
              // ADR-032 F1: _isMapReady → mapReadyStateProvider
              ref.read(mapReadyStateProvider.notifier).state = true;
              applyInitialViewport();
            },
            onTap: (tapPos, point) {
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

              // 🎯 Prioridade 2: Drawing Module (Interação)
              // 🔧 FIX-DRAW-RACE: Usar ref.read() para sempre acessar estado atual
              final drawCtrl = ref.read(drawingControllerProvider);
              if (drawCtrl.currentState == DrawingState.drawing ||
                  drawCtrl.currentState == DrawingState.armed) {
                drawCtrl.appendDrawingPoint(point);
                return;
              }

              if (drawCtrl.currentState == DrawingState.idle ||
                  drawCtrl.currentState == DrawingState.reviewing) {
                final drawingFeature = drawCtrl.findFeatureAt(point);
                if (drawingFeature != null) {
                  drawCtrl.selectFeature(drawingFeature);
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
              final fields = mapFields.valueOrNull ?? [];
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
            onLongPress: handleMapLongPress,
            onPositionChanged: (pos, hasGesture) {
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

              // ADR-028 — Overlay de radar de precipitação (RainViewer)
              const RadarLayerWidget(),

              // Polígonos de talhões
              // ADR-030 F3: extraído para TalhaoPolygonLayer
              const TalhaoPolygonLayer(),

              // Camada de Desenho
              // 🔧 FIX-DRAW-RACE: Usar ref.read() para evitar referência stale
              DrawingLayerWidget(
                controller: ref.read(drawingControllerProvider),
                onFeatureTap: (feature) {
                  ref.read(drawingControllerProvider).selectFeature(feature);
                  HapticFeedback.selectionClick();
                },
                onDrawingComplete: finishDrawing,
              ),

              // 🔧 Camada de Edição (Vertex Handles)
              DrawingEditLayer(
                controller: ref.read(drawingControllerProvider),
                mapController: mapController,
              ),

              // 🔒 MARKERS ISOLADOS: Não rebuildam por GPS/zoom/pan
              const MapMarkersWidget(),

              // Markers de ocorrências (isolados)
              IsolatedOccurrenceMarkersLayer(
                onOccurrenceTap: handleOccurrencePinTap,
              ),

              // Markers de Marketing (isolados — Sprint 8 Performance)
              const IsolatedMarketingMarkersLayer(),

              // 🎯 ÚNICA LAYER QUE REBUILDA: Localização GPS
              const IsolatedUserLocationLayer(),

              RichAttributionWidget(
                attributions: [TextSourceAttribution(tileConfig.attribution)],
                showFlutterMapAttribution: false,
                alignment: AttributionAlignment.bottomLeft,
                popupInitialDisplayDuration: const Duration(seconds: 2),
                popupBorderRadius: BorderRadius.circular(8),
                popupBackgroundColor: Colors.black.withValues(alpha: 0.72),
              ),
            ],
          ),

          // Controles do mapa (Consumer isolado + RepaintBoundary Sprint 8)
          RepaintBoundary(
            child: MapControlsOverlay(
              onCenterUser: centerOnUser,
              onLocationModeChanged: onLocationModeChanged,
              onToggleDrawMode: toggleDrawMode,
              onOpenMapTools: () => MapToolsBottomSheet.show(
                context: context,
                drawingController: ref.read(drawingControllerProvider),
              ),
              onToggleOccurrenceMode: () {
                if (ref.read(armedModeProvider) == ArmedMode.occurrences) {
                  // Desarmar e fechar o sheet/modal
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
              onCreateAntesDepoisCase: () =>
                  armMarketingMode(CaseTipo.antesDepois),
              onCreateAvaliacaoCase: () => armMarketingMode(CaseTipo.avaliacao),
              isMarketingMode:
                  ref.watch(armedModeProvider) == ArmedMode.marketing,
              isDrawMode: sheetState?.type == MapSheetType.draw,
              isOccurrenceMode:
                  ref.watch(armedModeProvider) == ArmedMode.occurrences,
              isCheckInActive: ref.watch(
                visitControllerProvider.select(
                  (v) => v.valueOrNull?.status == 'active',
                ),
              ),
              drawingState: drawingState,
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
              onCancelEdit: () =>
                  ref.read(drawingControllerProvider).cancelEdit(),
              onUndoEdit: () => ref.read(drawingControllerProvider).undoEdit(),
              onRedoEdit: () => ref.read(drawingControllerProvider).redoEdit(),
              onUndoDrawing: () =>
                  ref.read(drawingControllerProvider).undoDrawingPoint(),
              canUndo: canUndo,
              canRedo: canRedo,
              currentCenter: isMapReady
                  ? mapController.camera.center
                  : const LatLng(0, 0),
              currentZoom: isMapReady ? mapController.camera.zoom : 13.0,
              onTabSelected: (index, source) {
                // 🛡 REFATORAÇÃO: Mapear index para MapSheetType
                final sheetTypeMap = {
                  2: MapSheetType.occurrences,
                  3: MapSheetType.checkIn,
                  4: MapSheetType.layers,
                };

                final currentType = sheetState?.type;
                final newType = sheetTypeMap[index];

                if (currentType == newType) {
                  // Toggle: fechar modal se aberto
                  if (ref.read(isModalOpenProvider)) {
                    Navigator.of(context).pop();
                  }
                  setSheetState(
                    null,
                    'MapControlsOverlay: Toggle Close (Source: $source)',
                  );
                } else {
                  // Switch: se há modal aberto, liberar guarda e fechar antes de abrir novo
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
                ref.read(pendingOccurrenceLocationProvider.notifier).state =
                    null;
              },
            ),
          ),

          // 🛤 GPS TRACKING OVERLAY (Sprint 5)
          // Exibido apenas quando o usuário está rastreando o perímetro com GPS.
          // ADR-030 F4: DrawingMapBehaviorListener — side effects de drawing no mapa
          DrawingMapBehaviorListener(
            mapController: mapController,
            isMapReady: isMapReady,
            onCenterOnUser: centerOnUser,
          ),
          if (drawingState == DrawingState.gpsTracking)
            RepaintBoundary(
              child: ListenableBuilder(
                listenable: ref.read(drawingControllerProvider),
                builder: (context, _) => GpsTrackingOverlay(
                  controller: ref.read(drawingControllerProvider),
                ),
              ),
            ),

          // 🛡 CONSOLIDATION: DrawingSheet e OccurrenceSheet permanecem no Stack
          // Tipos checkIn/layers continuam usando sheet modal padronizado
          if (sheetState != null &&
              (sheetState.type == MapSheetType.draw ||
                  sheetState.type == MapSheetType.occurrences))
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MapBottomSheet(
                drawingController: ref.read(drawingControllerProvider),
                state: sheetState,
                onStateChange: (newState) {
                  setSheetState(newState, 'MapBottomSheet: State Changed');
                },
                onClose: () {
                  setSheetState(null, 'MapBottomSheet: onClose');
                },
                creationLocation: ref.read(pendingOccurrenceLocationProvider),
                onLocationRequested: centerOnUser,
              ),
            ),

          // FIX 1 — Indicador visual efêmero: modo seleção de ponto para ocorrência
          // ADR-030 F2: extraído para ArmedModeBanner
          const ArmedModeBanner(),
        ],
      ),
    );
  }
}
