import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/map_state.dart';
import '../../core/state/map_ui_providers.dart';
import '../../modules/auth/services/auth_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/map_logger.dart';
import '../../core/utils/debouncer.dart';
import '../../modules/marketing/presentation/providers/marketing_providers.dart';
import '../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../modules/drawing/presentation/widgets/drawing_layers.dart';
import '../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../modules/drawing/domain/drawing_state.dart';
import '../../modules/drawing/domain/drawing_utils.dart';
import '../../modules/drawing/presentation/widgets/drawing_state_indicator.dart';
import '../../modules/dashboard/providers/location_providers.dart';
import '../../modules/dashboard/domain/location_state.dart';
import '../../modules/dashboard/services/location_service.dart';
import '../../modules/visitas/presentation/controllers/geofence_controller.dart';
import '../../modules/consultoria/occurrences/domain/occurrence.dart' as occ;
import '../../modules/marketing/presentation/screens/novo_case_sheet.dart';
import '../../modules/marketing/presentation/widgets/draft_saved_sheet.dart';
import '../components/map/map_bottom_sheet.dart';
import '../components/map/widgets/map_canvas.dart';
import '../components/map/widgets/map_layers.dart';
import '../../core/config/map_config.dart';
import '../components/map/widgets/map_markers.dart';
import '../components/map/widgets/map_controls_overlay.dart';
import '../components/map/widgets/isolated_marker_layers.dart';
import '../../modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import '../../modules/drawing/presentation/widgets/gps_tracking_overlay.dart';
import '../../core/domain/map_models.dart';
import '../components/map/map_sheet_state.dart';
// ADR-012 — planos/
import '../../modules/planos/presentation/providers/plano_providers.dart';
import 'widgets/plano_block_sheet.dart';
// 🔧 MODAL: imports para showModalBottomSheet dos tipos não-draw
import '../components/map/map_sheets.dart';
import '../../modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart';
import '../../modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import '../../modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';
import '../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../modules/visitas/presentation/widgets/visit_sheet.dart';
import '../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../core/design/sf_icons.dart';

part 'private_map_sheets.dart';

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

// Enum para rastrear o modo armado
enum ArmedMode { none, occurrences, marketing }

class _PrivateMapScreenState extends ConsumerState<PrivateMapScreen> {
  final MapController _mapController = MapController();
  final _mapEventDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );

  bool _isMapReady = false; // 🔒 Guard: MapController só pode ser usado se true
  ArmedMode _armedMode = ArmedMode.none; // Estado do modo armado

  LatLng? _pendingOccurrenceLocation; // Se != null, abre sheet de ocorrência

  // 🔧 LIFECYCLE: Referência cacheada do DrawingController.
  // Capturada no build() para uso seguro no dispose() SEM ref.read().
  // ref é invalidado em deactivate() (antes de dispose()) — ADR-008.
  dynamic _drawingController;

  // 🔧 MODAL: Controle de modais ativos
  bool _isModalOpen = false;
  int _modalGeneration = 0;

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

  // 🛡 HARDENING DEFINITIVO: Máquina de Decisão de Viewport
  // Determinístico. Idempotente. Sem race loops.
  void _applyInitialViewport() async {
    // � LIFECYCLE GUARD: método async pode executar após dispose.
    // Se o widget foi descartado durante transição de rota, ref está inválido.
    if (!mounted) return;

    // �🔒 Gate 0: Se já aplicado ou abortado, TERMINAR IMEDIATAMENTE.
    final vp = ref.read(viewportStateProvider);
    if (vp == InitialViewportState.applied ||
        vp == InitialViewportState.aborted) {
      return;
    }

    // 🔒 Gate 1: Map Ready
    if (!_isMapReady) {
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForMap;
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    // 🔒 Gate 2: Role Ready
    if (user == null) {
      ref.read(viewportStateProvider.notifier).state =
          InitialViewportState.waitingForData;
      return;
    }

    final role = user.userMetadata?['role'] as String?;
    final isProducer = role == 'produtor';

    // 🔒 Gate 3: Decisão de Estratégia
    if (isProducer) {
      // 🚜 ESTRATÉGIA PRODUTOR
      final fieldsState = ref.read(mapFieldsProvider);

      if (fieldsState.isLoading) {
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.waitingForData;
        return;
      }

      if (fieldsState.hasError ||
          !fieldsState.hasValue ||
          fieldsState.value == null ||
          fieldsState.value!.isEmpty) {
        // Fallback: Sem fazenda → Abortar para usar GPS manual
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.aborted;
        return;
      }

      // Sucesso: Aplicar Viewport
      final fields = fieldsState.value!;
      final allPoints = fields
          .expand((f) => TalhaoMapAdapter.toPolygon(f).points)
          .toList();

      if (allPoints.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(allPoints);
        try {
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
          ref.read(viewportStateProvider.notifier).state =
              InitialViewportState.applied; // ✅ FINALIZADO
        } catch (_) {
          ref.read(viewportStateProvider.notifier).state =
              InitialViewportState.aborted;
        }
      } else {
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.aborted;
      }
    } else {
      // 👤 ESTRATÉGIA CONSUMIDOR (GPS)
      final locationState = ref.read(locationStateProvider);

      if (locationState == LocationState.checking) {
        // Ainda verificando → Aguardar
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.waitingForData;
        return;
      }

      if (locationState == LocationState.permissionDenied ||
          locationState == LocationState.serviceDisabled) {
        // Erro permanente → Abortar (evita loop)
        ref.read(viewportStateProvider.notifier).state =
            InitialViewportState.aborted;
        return;
      }

      if (locationState == LocationState.available) {
        final locationService = LocationService();
        final position = await locationService.getCurrentPosition();

        if (position != null && mounted) {
          _mapController.move(position, 16.0);
          ref.read(viewportStateProvider.notifier).state =
              InitialViewportState.applied; // ✅ FINALIZADO
        } else if (mounted) {
          // Disponível mas posição nula? Aguardar.
          ref.read(viewportStateProvider.notifier).state =
              InitialViewportState.waitingForData;
        }
      }
    }
  }

  void _showGPSRequiredMessage() {
    final state = ref.read(locationStateProvider);
    String message;

    switch (state) {
      case LocationState.permissionDenied:
        message =
            'GPS indisponível: permissão negada. Habilite nas configurações do app.';
        break;
      case LocationState.serviceDisabled:
        message =
            'GPS desligado. Ative o GPS nas configurações do dispositivo.';
        break;
      case LocationState.checking:
        message = 'Aguardando verificação do GPS...';
        break;
      default:
        message = 'GPS indisponível. Funções geográficas bloqueadas.';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _centerOnUser() async {
    // 🔒 Guard: Verificar se o mapa está pronto
    if (!_isMapReady) return;

    // 🚫 Bloqueio: GPS obrigatório para centralizar
    final locationState = ref.read(locationStateProvider);
    if (locationState != LocationState.available) {
      _showGPSRequiredMessage();
      return;
    }

    HapticFeedback.lightImpact();

    // Centralizar na posição atual (obtida do stream)
    final locationService = LocationService();
    final position = await locationService.getCurrentPosition();

    if (position != null && _isMapReady && mounted) {
      _mapController.move(position, 16.0);
    }
  }

  void _armOccurrenceMode() {
    // FIX 1: Entrar em modo seleção — usuário toca no mapa para capturar LatLng
    setState(() => _armedMode = ArmedMode.occurrences);
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
    setState(() {
      _pendingOccurrenceLocation = LatLng(lat, lng); // Trigger Creation Mode
    });
  }

  void _armMarketingMode() {
    setState(() => _armedMode = ArmedMode.marketing);
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
    ref.watch(geofenceControllerProvider);

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

    // Watch drawing state changes to switch layers
    ref.listen(drawingControllerProvider.select((s) => s.currentState), (
      prev,
      next,
    ) {
      // 🛡 LIFECYCLE GUARD: listener pode disparar após dispose do widget
      if (!mounted) return;

      if (next == DrawingState.drawing || next == DrawingState.editing) {
        // Auto-switch to Satellite
        final currentLayer = ref.read(activeLayerProvider);
        if (currentLayer != LayerType.satellite) {
          ref.read(activeLayerProvider.notifier).setLayer(LayerType.satellite);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Modo Satélite ativado para melhor visualização'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }

      // 🆕 SPRINT 5: GPS Tracking → ativar satélite + centralizar no usuário
      if (next == DrawingState.gpsTracking) {
        final currentLayer = ref.read(activeLayerProvider);
        if (currentLayer != LayerType.satellite) {
          ref.read(activeLayerProvider.notifier).setLayer(LayerType.satellite);
        }
        // Centralizar mapa na posição atual do usuário para referência
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          _centerOnUser();
        });
      }

      // 🆕 SPRINT 3: Zoom automático após import KML/KMZ
      // Quando a geometria importada entra em preview, move a câmera para ela
      if (next == DrawingState.importPreview && _isMapReady) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          final geo = ref.read(drawingControllerProvider).liveGeometry;
          final bounds = DrawingUtils.getBoundsLatLng(geo);
          if (bounds != null) {
            try {
              _mapController.fitCamera(
                CameraFit.bounds(
                  bounds: bounds,
                  padding: const EdgeInsets.all(60),
                ),
              );
            } catch (_) {
              // Guard: mapa pode estar em transição — ignora silenciosamente
            }
          }
        });
      }
    });

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
              if (_armedMode == ArmedMode.marketing) {
                setState(() => _armedMode = ArmedMode.none);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _handleMapLongPress(tapPos, point);
                return;
              }

              // 🎯 Prioridade 1b: Verificar modo armado de ocorrências
              if (_armedMode == ArmedMode.occurrences) {
                final lat = point.latitude;
                final lng = point.longitude;

                // Desarmar imediatamente para evitar múltiplos taps
                setState(() => _armedMode = ArmedMode.none);
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

              // Polígonos de talhões
              if (mapFields.hasValue)
                PolygonLayer(
                  polygons: mapFields.value!.map((t) {
                    return TalhaoMapAdapter.toPolygon(
                      t,
                      isSelected: t.id == selectedTalhaoId,
                    );
                  }).toList(),
                ),

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
              if (_armedMode == ArmedMode.occurrences) {
                // Desarmar e fechar o sheet/modal
                setState(() => _armedMode = ArmedMode.none);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                if (_isModalOpen) Navigator.of(context).pop();
                _setSheetState(null, 'Toggle OFF: Closing occurrence sheet');
              } else {
                _armOccurrenceMode();
              }
            },
            onToggleMarketingMode: () {
              if (_armedMode == ArmedMode.marketing) {
                setState(() => _armedMode = ArmedMode.none);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              } else {
                _armMarketingMode();
              }
            },
            isMarketingMode: _armedMode == ArmedMode.marketing,
            isDrawMode: sheetState?.type == MapSheetType.draw,
            isOccurrenceMode: _armedMode == ArmedMode.occurrences,
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
                if (_isModalOpen) Navigator.of(context).pop();
                _setSheetState(
                  null,
                  'MapControlsOverlay: Toggle Close (Source: $source)',
                );
              } else {
                // Switch: se há modal aberto, liberar guarda e fechar antes de abrir novo
                if (_isModalOpen) {
                  Navigator.of(context).pop();
                  _modalGeneration++; // Invalida o whenComplete do modal anterior
                  setState(() => _isModalOpen = false);
                }
                _setSheetState(
                  MapSheetState(type: newType!),
                  'MapControlsOverlay: Select Tab $newType (Source: $source)',
                );
              }
              setState(() {
                _pendingOccurrenceLocation = null;
              });
            },
            ),
          ),

          // � GPS TRACKING OVERLAY (Sprint 5)
          // Exibido apenas quando o usuário está rastreando o perímetro com GPS.
          // Não é um FAB nem nova rota — é um overlay no Stack existente.
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
                creationLocation: _pendingOccurrenceLocation,
                onLocationRequested: _centerOnUser,
              ),
            ),

          // FIX 1 — Indicador visual efêmero: modo seleção de ponto para ocorrência
          if (_armedMode == ArmedMode.occurrences)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_pin,
                          color: Colors.orangeAccent,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Toque no mapa para marcar o ponto',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
