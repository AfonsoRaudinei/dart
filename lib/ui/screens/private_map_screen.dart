import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/map_state.dart';
import '../../core/state/map_ui_providers.dart';
import '../../modules/auth/services/auth_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/map_logger.dart';
import '../../core/utils/debouncer.dart';
import '../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../modules/drawing/presentation/widgets/drawing_layers.dart';
import '../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../modules/drawing/domain/drawing_state.dart';
import '../../modules/drawing/presentation/widgets/drawing_state_indicator.dart';
import '../../modules/dashboard/providers/location_providers.dart';
import '../../modules/consultoria/occurrences/domain/occurrence.dart' as occ;
import '../components/map/map_bottom_sheet.dart';
import '../components/map/widgets/map_canvas.dart';
import '../components/map/widgets/map_layers.dart';
import '../components/map/widgets/radar_layer_widget.dart';
import '../../core/config/map_config.dart';
import '../components/map/widgets/map_markers.dart';
import '../components/map/widgets/map_controls_overlay.dart';
import '../components/map/widgets/isolated_marker_layers.dart';
import '../../modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import '../../modules/drawing/presentation/widgets/gps_tracking_overlay.dart';
import '../../core/domain/map_models.dart';
import '../components/map/map_sheet_state.dart';
// 🔧 MODAL: imports para showModalBottomSheet dos tipos não-draw
// (conteúdo migrado para map_sheet_content_builder.dart — ADR-031 F3)
import '../../modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';
import '../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../core/contracts/i_field_lookup_geofence_provider.dart';
import 'map/providers/map_armed_mode_provider.dart';
import 'map/widgets/armed_mode_banner.dart';
import 'map/layers/talhao_polygon_layer.dart';
import 'map/widgets/drawing_map_behavior_listener.dart';
import 'map/handlers/map_location_handler.dart';
import 'map/controllers/map_viewport_controller.dart';
import 'map/controllers/map_sheet_controller.dart';
import 'map/handlers/novo_case_modal_launcher.dart';


// ════════════════════════════════════════════════════════════════
// GOVERNANCE ADR-025 — DT-025-5
// Este arquivo está em ~900 linhas. PROIBIDO adicionar código inline.
// Toda nova funcionalidade DEVE ser extraída para widget separado em
// lib/ui/components/map/ e apenas referenciada aqui. Ver ADR-025 §6.
// ════════════════════════════════════════════════════════════════
class PrivateMapScreen extends ConsumerStatefulWidget {
  const PrivateMapScreen({super.key});

  @override
  ConsumerState<PrivateMapScreen> createState() => _PrivateMapScreenState();
}

class _PrivateMapScreenState extends ConsumerState<PrivateMapScreen> {
  final MapController _mapController = MapController();
  final _mapEventDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );

  bool _isMapReady = false; // 🔒 Guard: MapController só pode ser usado se true

  // 🔧 LIFECYCLE: Referência cacheada do DrawingController.
  // Capturada no build() para uso seguro no dispose() SEM ref.read().
  // ref é invalidado em deactivate() (antes de dispose()) — ADR-008.
  dynamic _drawingController;

  @override
  void initState() {
    super.initState();
    // Inicializar GPS ao carregar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 🛡 LIFECYCLE GUARD: Se o widget foi disposed durante a transição
      // de rota (duplo evento onAuthStateChange do Supabase), o ref já
      // está invalidado. Sem este guard → BadState crash na inicialização.
      if (!mounted) return;

      ref.read(locationStateProvider.notifier).init();
      _requestLocationPermission();

      // Bootstrap silencioso: garantir perfil completo.
      // Fire-and-forget — sem await, sem loading, sem rebuild.
      // Cobre edge case de perfil eternamente vazio após email confirmation.
      ref.read(authServiceProvider.notifier).ensureProfileComplete().catchError(
        (e) {
          // 🛡 LIFECYCLE GUARD: callback async pode executar após dispose
          if (!mounted) return;
          AppLogger.debug(
            'Profile bootstrap silencioso falhou (não-crítico): $e',
            tag: 'MapBootstrap',
          );
        },
      );

      // 🗺️ MAP-FIRST: Leitura de query params provenientes de DetalheCliente
      // Exemplo: /map?modo=desenho&clienteId=X&clienteNome=Fulano
      // Ativa DrawingMode com o cliente pré-selecionado — NÃO cria nova lógica.
      if (mounted) {
        final uri = GoRouterState.of(context).uri;
        final modoParam = uri.queryParameters['modo'];
        final clienteIdParam = uri.queryParameters['clienteId'];

        if (modoParam == 'desenho' && clienteIdParam != null) {
          AppLogger.debug(
            'MAP-FIRST: recebido modo=desenho clienteId=$clienteIdParam',
            tag: 'PrivateMap',
          );
          // Pré-seleciona cliente via DrawingClientNotifier (ADR-019)
          ref
              .read(drawingClientProvider.notifier)
              .setClienteAtivo(clienteIdParam);
          // Abre o painel de desenho (mecanismo já existente)
          _setSheetState(
            const MapSheetState(type: MapSheetType.draw),
            'query_param_modo_desenho',
          );
        }

        // 🆕 SPRINT 3: modo=importar — abre painel e dispara seletor de arquivo
        if (modoParam == 'importar') {
          AppLogger.debug(
            'MAP-FIRST: recebido modo=importar clienteId=$clienteIdParam',
            tag: 'PrivateMap',
          );
          if (clienteIdParam != null) {
            ref
                .read(drawingClientProvider.notifier)
                .setClienteAtivo(clienteIdParam);
          }
          _setSheetState(
            const MapSheetState(type: MapSheetType.draw),
            'query_param_modo_importar',
          );
          // Aguarda o sheet estar montado antes de abrir a UI de import
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ref.read(drawingControllerProvider).startImportMode();
            }
          });
        }

        // P5: modo=visita — abre checkIn sheet com cliente pré-selecionado
        if (modoParam == 'visita' && clienteIdParam != null) {
          AppLogger.debug(
            'MAP-FIRST: recebido modo=visita clienteId=$clienteIdParam',
            tag: 'PrivateMap',
          );
          _setSheetState(
            MapSheetState(
              type: MapSheetType.checkIn,
              preSelectedClienteId: clienteIdParam,
            ),
            'query_param_modo_visita',
          );
        }
      }
    });
  }

  @override
  void dispose() {
    // 🔧 LIFECYCLE EXPLÍCITO: Reset do DrawingController ao sair da tela
    // Provider SEM autoDispose → controle manual obrigatório
    // cancelOperation() limpa: estado, geometria, pontos, preview e volta para idle
    //
    // 🛡 ADR-008: ref é invalidado em deactivate() (antes de dispose()).
    // Usar referência cacheada em _drawingController, capturada no build().
    // NUNCA usar ref.read() aqui — causa BadState crash.
    _drawingController?.cancelOperation();

    _mapEventDebouncer.dispose();
    super.dispose();
  }

  // 🔎 INSTRUMENTATION: Rastrear quem altera o estado
  void _setSheetState(MapSheetState? state, String reason) {
    final currentSheet = ref.read(mapSheetStateProvider);
    AppLogger.debug(
      'SHEET CHANGE | old=${currentSheet?.type} | new=${state?.type} | reason=$reason',
      tag: 'PrivateMap',
    );

    // 🔧 FIX-DRAW-SYNC: Sincronizar DrawingController com MapSheetState
    // Se está SAINDO do modo desenho, cancelar desenho automaticamente
    if (currentSheet?.type == MapSheetType.draw &&
        state?.type != MapSheetType.draw) {
      AppLogger.debug('AUTO-CANCEL: Saindo do modo desenho', tag: 'PrivateMap');
      ref.read(drawingControllerProvider).selectTool('none');
    }

    ref.read(mapSheetStateProvider.notifier).state = state;

    // 🔧 MODAL: draw permanece no Stack; demais tipos abrem como showModalBottomSheet
    if (state == null || state.type == MapSheetType.draw) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _openSheetAsModal(context, state);
    });
  }

  void _setModalOpen(bool value) {
    if (!mounted) return;
    ref.read(isModalOpenProvider.notifier).state = value;
  }

  // ── _handleMapLongPress ── delegate ADR-031 F5 ─────────────────────────
  void _handleMapLongPress(TapPosition tapPos, LatLng latLng) {
    NovoCaseModalLauncher.launch(
      position: latLng,
      context: context,
      ref: ref,
    );
  }

  // ── _openSheetAsModal ── delegate ADR-031 F4 ───────────────────────────
  void _openSheetAsModal(BuildContext ctx, MapSheetState state) {
    MapSheetController.openSheet(
      ctx,
      ref,
      state,
      _armOccurrenceMode,
      _setSheetState,
      _setModalOpen,
    );
  }

  // ── _finishDrawing ─────────────────────────────────────────────────────
  Future<void> _finishDrawing() async {
    final controller = ref.read(drawingControllerProvider);
    if (controller.currentState != DrawingState.drawing) return;
    if (controller.liveGeometry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos 3 pontos para criar um polígono'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }
    controller.completeDrawing();
    if (controller.currentState != DrawingState.reviewing) return;
  }

  // ── _toggleDrawMode ── delegate ADR-031 F4 ────────────────────────────
  void _toggleDrawMode() {
    MapSheetController.toggleDrawMode(context, ref, _setSheetState);
  }

  // HARDENING DEFINITIVO: Máquina de Decisão de Viewport
  // Determinístico. Idempotente. Sem race loops.
  // ADR-030 F6: lógica extraída para MapViewportController
  void _applyInitialViewport() async {
    await MapViewportController.apply(
      ref: ref,
      mapController: _mapController,
      isMapReady: _isMapReady,
      isMounted: mounted,
    );
  }

  Future<void> _requestLocationPermission() async {
    await MapLocationHandler.requestPermission(
      ref: ref,
      context: context,
      mapController: _mapController,
      isMapReady: _isMapReady,
    );
  }

  void _centerOnUser() async {
    await MapLocationHandler.centerOnUser(
      ref: ref,
      context: context,
      mapController: _mapController,
      isMapReady: _isMapReady,
    );
  }

  void _armOccurrenceMode() {
    // FIX 1: Entrar em modo seleção — usuário toca no mapa para capturar LatLng
    ref.read(armedModeProvider.notifier).state = ArmedMode.occurrences;
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toque no mapa para marcar o ponto da ocorrência'),
        duration: Duration(seconds: 10),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }


  void _openOccurrenceSheet(double lat, double lng) async {
    // 🛡 CONSOLIDATION: Redirect to MapBottomSheet
    if (!mounted) return;

    // Usando setter instrumentado
    _setSheetState(
      const MapSheetState(
        type: MapSheetType.occurrences,
        isCreatingOccurrence: true,
      ),
      'OpenOccurrenceSheet (Create Mode)',
    );
    ref.read(pendingOccurrenceLocationProvider.notifier).state =
        LatLng(lat, lng); // Trigger Creation Mode
  }

  void _armMarketingMode() {
    ref.read(armedModeProvider.notifier).state = ArmedMode.marketing;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toque no mapa para localizar o case de marketing'),
        duration: Duration(seconds: 2),
      ),
    );
  }


  void _handleOccurrencePinTap(occ.Occurrence occurrence) {
    if (!mounted) return;
    OccurrenceDetailSheet.show(context, occurrence);
  }

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();

    // 🛡 LIFECYCLE: Cachear referência do DrawingController para uso
    // seguro no dispose() — ref é invalidado antes de dispose() ser chamado.
    _drawingController = ref.read(drawingControllerProvider);

    // Mantém GeofenceController ativo somente durante o ciclo de vida desta tela.
    ref.watch(iFieldLookupGeofenceProvider);

    // Apenas providers necessários para lógica de tap e polígonos
    final mapFields = ref.watch(mapFieldsProvider);
    final selectedTalhaoId = ref.watch(selectedTalhaoIdProvider);
    // ⚡ Otimização: Observar apenas currentState e currentTool (não toda a lista de features)
    // 🔧 FIX-DRAW-RACE: NÃO usar ref.watch para o controller usado em callbacks
    // Usar ref.read() nos callbacks evita race conditions com referências stale
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

    // 🔒 LISTENERS PARA FOCO INICIAL (Idempotentes)
    // Observar carregamento dos fields (para Produtores)
    ref.listen(mapFieldsProvider, (prev, next) {
      // 🛡 LIFECYCLE GUARD: listener pode disparar após dispose do widget
      if (!mounted) return;

      final vp = ref.read(viewportStateProvider);
      if (vp != InitialViewportState.applied &&
          vp != InitialViewportState.aborted &&
          _isMapReady) {
        _applyInitialViewport();
      }
    });

    // Observar disponibilidade de GPS (para Outros)
    ref.listen(locationStateProvider, (prev, next) {
      // 🛡 LIFECYCLE GUARD: listener pode disparar após dispose do widget
      if (!mounted) return;

      final vp = ref.read(viewportStateProvider);
      if (vp != InitialViewportState.applied &&
          vp != InitialViewportState.aborted &&
          _isMapReady) {
        _applyInitialViewport();
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
            mapController: _mapController,
            onMapReady: () {
              // Mark map as ready FIRST
              if (mounted) {
                // Ao montar, marcamos como pronto.
                // setState trigger rebuild, permitindo que Overlay use controller depois.
                setState(() => _isMapReady = true);

                // Trigger viewport logic immediately
                _applyInitialViewport();
              }
            },
            onTap: (tapPos, point) {
              // 🎯 Prioridade 1a: Modo armado marketing
              if (ref.read(armedModeProvider) == ArmedMode.marketing) {
                ref.read(armedModeProvider.notifier).state = ArmedMode.none;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _handleMapLongPress(tapPos, point);
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
                _openOccurrenceSheet(lat, lng);
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
                  // Em vez de abrir novo modal, navegar o sheet persistente
                  _setSheetState(
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
                // Lazy parse for hit test (optimization: cache parsed polygons if needed)
                // Here purely for hit detection
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
            onLongPress: _handleMapLongPress,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture) {
                _mapEventDebouncer.run(() {
                  MapLogger.logEvent(
                    'Pan/Zoom: Center=${pos.center.latitude.toStringAsFixed(4)},${pos.center.longitude.toStringAsFixed(4)} Zoom=${pos.zoom.toStringAsFixed(1)}',
                  );
                  bool isClusteringActive = pos.zoom < 15;
                  MapLogger.logEvent('Clustering Active: $isClusteringActive');
                });
              }
            },
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
                onDrawingComplete: _finishDrawing,
              ),

              // 🔧 Camada de Edição (Vertex Handles)
              DrawingEditLayer(
                controller: ref.read(drawingControllerProvider),
                mapController: _mapController,
              ),

              // 🔒 MARKERS ISOLADOS: Não rebuildam por GPS/zoom/pan
              // Markers globais (MapMarkersWidget já otimizado)
              const MapMarkersWidget(),

              // Markers de ocorrências (isolados)
              IsolatedOccurrenceMarkersLayer(
                onOccurrenceTap: _handleOccurrencePinTap,
              ),

              // Markers de Marketing (isolados — Sprint 8 Performance)
              const IsolatedMarketingMarkersLayer(),

              // 🎯 ÚNICA LAYER QUE REBUILDA: Localização GPS
              const IsolatedUserLocationLayer(),

              // ⚖️ ATRIBUIÇÃO LEGAL: © Google — exibida somente no layer satellite
              // Obrigatória pelos Termos de Serviço do Google Maps Platform
              if (ref.watch(activeLayerProvider) == LayerType.satellite)
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      MapConfig.googleAttribution,
                    ),
                  ],
                ),
            ],
          ),

          // Controles do mapa (Consumer isolado + RepaintBoundary Sprint 8)
          RepaintBoundary(
            child: MapControlsOverlay(
            onCenterUser: _centerOnUser,
            onToggleDrawMode: _toggleDrawMode,
            onToggleOccurrenceMode: () {
              if (ref.read(armedModeProvider) == ArmedMode.occurrences) {
                // Desarmar e fechar o sheet/modal
                ref.read(armedModeProvider.notifier).state = ArmedMode.none;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (ref.read(isModalOpenProvider)) Navigator.of(context).pop();
                _setSheetState(null, 'Toggle OFF: Closing occurrence sheet');
              } else {
                _armOccurrenceMode();
              }
            },
            onToggleMarketingMode: () {
              if (ref.read(armedModeProvider) == ArmedMode.marketing) {
                ref.read(armedModeProvider.notifier).state = ArmedMode.none;
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              } else {
                _armMarketingMode();
              }
            },
            isMarketingMode: ref.watch(armedModeProvider) == ArmedMode.marketing,
            isDrawMode: sheetState?.type == MapSheetType.draw,
            isOccurrenceMode: ref.watch(armedModeProvider) == ArmedMode.occurrences,
            isCheckInActive: ref.watch(
              visitControllerProvider.select(
                (v) => v.valueOrNull?.status == 'active',
              ),
            ),
            drawingState: drawingState,
            onFinishDrawing: _finishDrawing,
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
            onUndoDrawing:
                () => ref.read(drawingControllerProvider).undoDrawingPoint(),
            canUndo: canUndo,
            canRedo: canRedo,
            isRadarActive: ref.watch(showRadarProvider),
            onToggleRadar: () => ref
                .read(showRadarProvider.notifier)
                .state = !ref.read(showRadarProvider),
            currentCenter: _isMapReady
                ? _mapController.camera.center
                : const LatLng(0, 0),
            currentZoom: _isMapReady ? _mapController.camera.zoom : 13.0,
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
                if (ref.read(isModalOpenProvider)) Navigator.of(context).pop();
                _setSheetState(
                  null,
                  'MapControlsOverlay: Toggle Close (Source: $source)',
                );
              } else {
                // Switch: se há modal aberto, liberar guarda e fechar antes de abrir novo
                if (ref.read(isModalOpenProvider)) {
                  Navigator.of(context).pop();
                  ref.read(modalGenerationProvider.notifier).state++; // Invalida o whenComplete do modal anterior
                  ref.read(isModalOpenProvider.notifier).state = false;
                }
                _setSheetState(
                  MapSheetState(type: newType!),
                  'MapControlsOverlay: Select Tab $newType (Source: $source)',
                );
              }
              ref.read(pendingOccurrenceLocationProvider.notifier).state = null;
            },
            ),
          ),

          // � GPS TRACKING OVERLAY (Sprint 5)
          // Exibido apenas quando o usuário está rastreando o perímetro com GPS.
          // Não é um FAB nem nova rota — é um overlay no Stack existente.
          // ADR-030 F4: DrawingMapBehaviorListener — side effects de drawing no mapa
          DrawingMapBehaviorListener(
            mapController: _mapController,
            isMapReady: _isMapReady,
            onCenterOnUser: _centerOnUser,
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

          // �🛡 CONSOLIDATION: DrawingSheet permanece no Stack (draw type)
          // Tipos publications/occurrences/checkIn/layers usam showModalBottomSheet
          if (sheetState != null && sheetState.type == MapSheetType.draw)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MapBottomSheet(
                drawingController: ref.read(drawingControllerProvider),
                state: sheetState,
                onStateChange: (newState) {
                  _setSheetState(newState, 'MapBottomSheet: State Changed');
                },
                onClose: () {
                  _setSheetState(null, 'MapBottomSheet: onClose');
                },
                creationLocation: ref.read(pendingOccurrenceLocationProvider),
                onLocationRequested: _centerOnUser,
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
