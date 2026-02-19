import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/state/map_state.dart';
import '../../core/utils/map_logger.dart';
import '../../core/utils/debouncer.dart';
import '../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../modules/drawing/presentation/widgets/drawing_layers.dart';
import '../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../modules/drawing/domain/drawing_state.dart';
import '../../modules/drawing/presentation/widgets/drawing_state_indicator.dart';
import '../../modules/dashboard/providers/location_providers.dart';
import '../../modules/dashboard/domain/location_state.dart';
import '../../modules/dashboard/services/location_service.dart';
import '../../modules/visitas/presentation/controllers/geofence_controller.dart';
import '../../modules/consultoria/occurrences/domain/occurrence.dart' as occ;
import '../components/map/map_bottom_sheet.dart';
import '../../core/domain/publicacao.dart';
import '../components/map/widgets/map_canvas.dart';
import '../components/map/widgets/map_layers.dart';
import '../components/map/widgets/map_markers.dart';
import '../components/map/widgets/map_controls_overlay.dart';
import '../components/map/widgets/isolated_marker_layers.dart';
import '../../modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import '../../core/domain/map_models.dart';
import '../components/map/map_sheet_state.dart'; // 🛡 REFATORAÇÃO: Modelo compartilhado

// 🛡 HARDENING: Máquina de estados para inicialização determinística
enum InitialViewportState {
  idle,
  waitingForMap,
  waitingForData,
  applied,
  aborted,
}

class PrivateMapScreen extends ConsumerStatefulWidget {
  const PrivateMapScreen({super.key});

  @override
  ConsumerState<PrivateMapScreen> createState() => _PrivateMapScreenState();
}

// Enum para rastrear o modo armado
enum ArmedMode { none, occurrences }

class _PrivateMapScreenState extends ConsumerState<PrivateMapScreen> {
  final MapController _mapController = MapController();
  final _mapEventDebouncer = Debouncer(
    delay: const Duration(milliseconds: 300),
  );

  // 🛡 Estado da máquina de inicialização (substitui boolean simples)
  InitialViewportState _viewportState = InitialViewportState.idle;

  bool _isMapReady = false; // 🔒 Guard: MapController só pode ser usado se true
  bool _isDrawMode = false;
  ArmedMode _armedMode = ArmedMode.none; // Estado do modo armado

  // 🛡 REFATORAÇÃO: Estado explícito do MapBottomSheet (null = fechado)
  MapSheetState? _sheetState;
  LatLng? _pendingOccurrenceLocation; // Se != null, abre sheet em modo Create

  // ── Publicações canônicas (estado local ao mapa — ADR-007) ──
  final List<Publicacao> _publicacoes = _getMockPublicacoes();

  @override
  void initState() {
    super.initState();
    // Inicializar GPS ao carregar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationStateProvider.notifier).init();
      ref.read(geofenceControllerProvider); // Start Geofence Monitoring
    });
  }

  @override
  void dispose() {
    // 🔧 LIFECYCLE EXPLÍCITO: Reset do DrawingController ao sair da tela
    // Provider SEM autoDispose → controle manual obrigatório
    // cancelOperation() limpa: estado, geometria, pontos, preview e volta para idle
    ref.read(drawingControllerProvider).cancelOperation();

    _mapEventDebouncer.dispose();
    super.dispose();
  }

  // 🔎 INSTRUMENTATION: Rastrear quem altera o estado
  void _setSheetState(MapSheetState? state, String reason) {
    debugPrint(
      '🕵️ SHEET CHANGE | old=${_sheetState?.type} | new=${state?.type} | reason=$reason',
    );

    // 🔧 FIX-DRAW-SYNC: Sincronizar DrawingController com MapSheetState
    // Se está SAINDO do modo desenho, cancelar desenho automaticamente
    if (_sheetState?.type == MapSheetType.draw &&
        state?.type != MapSheetType.draw) {
      debugPrint('🎨 AUTO-CANCEL: Saindo do modo desenho');
      ref.read(drawingControllerProvider).selectTool('none');
    }

    setState(() {
      _sheetState = state;
    });
  }

  // 🛡 HARDENING DEFINITIVO: Máquina de Decisão de Viewport
  // Determinístico. Idempotente. Sem race loops.
  void _applyInitialViewport() async {
    // 🔒 Gate 0: Se já aplicado ou abortado, TERMINAR IMEDIATAMENTE.
    if (_viewportState == InitialViewportState.applied ||
        _viewportState == InitialViewportState.aborted) {
      return;
    }

    // 🔒 Gate 1: Map Ready
    if (!_isMapReady) {
      _viewportState = InitialViewportState.waitingForMap;
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    // 🔒 Gate 2: Role Ready
    if (user == null) {
      _viewportState = InitialViewportState.waitingForData;
      return;
    }

    final role = user.userMetadata?['role'] as String?;
    final isProducer = role == 'produtor';

    // 🔒 Gate 3: Decisão de Estratégia
    if (isProducer) {
      // 🚜 ESTRATÉGIA PRODUTOR
      final fieldsState = ref.read(mapFieldsProvider);

      if (fieldsState.isLoading) {
        _viewportState = InitialViewportState.waitingForData;
        return;
      }

      if (fieldsState.hasError ||
          !fieldsState.hasValue ||
          fieldsState.value == null ||
          fieldsState.value!.isEmpty) {
        // Fallback: Sem fazenda → Abortar para usar GPS manual
        _viewportState = InitialViewportState.aborted;
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
          _viewportState = InitialViewportState.applied; // ✅ FINALIZADO
        } catch (_) {
          _viewportState = InitialViewportState.aborted;
        }
      } else {
        _viewportState = InitialViewportState.aborted;
      }
    } else {
      // 👤 ESTRATÉGIA CONSUMIDOR (GPS)
      final locationState = ref.read(locationStateProvider);

      if (locationState == LocationState.checking) {
        // Ainda verificando → Aguardar
        _viewportState = InitialViewportState.waitingForData;
        return;
      }

      if (locationState == LocationState.permissionDenied ||
          locationState == LocationState.serviceDisabled) {
        // Erro permanente → Abortar (evita loop)
        _viewportState = InitialViewportState.aborted;
        return;
      }

      if (locationState == LocationState.available) {
        final locationService = LocationService();
        final position = await locationService.getCurrentPosition();

        if (position != null && mounted) {
          _mapController.move(position, 16.0);
          _viewportState = InitialViewportState.applied; // ✅ FINALIZADO
        } else {
          // Disponível mas posição nula? Aguardar.
          _viewportState = InitialViewportState.waitingForData;
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
    // 🔧 FIX: Abrir o sheet de ocorrências primeiro
    _setSheetState(
      const MapSheetState(
        type: MapSheetType.occurrences,
        isCreatingOccurrence: false,
      ),
      'ArmOccurrenceMode: Opening occurrence sheet',
    );
    
    // Armar o modo para quando clicar no mapa
    setState(() => _armedMode = ArmedMode.occurrences);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Toque no mapa para registrar a ocorrência'),
        duration: Duration(seconds: 2),
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

  void _handleOccurrencePinTap(occ.Occurrence occurrence) {
    HapticFeedback.lightImpact();
    // Implement what happens when an occurrence pin is tapped
    // For example, show a detailed sheet or dialog for the occurrence
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ocorrência: ${occurrence.description}'),
        backgroundColor: SoloForteColors.greenIOS,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // 🔧 Helper to finish drawing
  Future<void> _finishDrawing() async {
    final controller = ref.read(drawingControllerProvider);

    // 🔒 GUARD: Evitar re-entrância ou chamadas duplicadas (Fix Duplication)
    // Só processar se estiver no estado de desenho
    if (controller.currentState != DrawingState.drawing) {
      return;
    }

    // Verificar se há pontos suficientes
    if (controller.liveGeometry == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos 3 pontos para criar um polígono'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // 🔧 CHANGE STATE: Mudar para modo de revisão
    // Isso prepara o controller para exibir o formulário correto no sheet
    controller.completeDrawing();

    // 🔒 VALIDATION: Garantir que a transição ocorreu com sucesso
    // Se a máquina de estados rejeitou (ex: validação falhou), não processar
    if (controller.currentState != DrawingState.reviewing) {
      return;
    }

    // 🔧 FIX: O DrawingSheet no MapBottomSheet já está observando o estado
    // Não precisa abrir modal separado - o sheet unificado já reage ao estado
    // Apenas sincronizar UI local
    if (mounted) {
      setState(() => _isDrawMode = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stopwatch = Stopwatch()..start();
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

    // Watch drawing state changes to switch layers
    ref.listen(drawingControllerProvider.select((s) => s.currentState), (
      prev,
      next,
    ) {
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
    });

    // 🔒 LISTENERS PARA FOCO INICIAL (Idempotentes)
    // Observar carregamento dos fields (para Produtores)
    ref.listen(mapFieldsProvider, (prev, next) {
      if (_viewportState != InitialViewportState.applied &&
          _viewportState != InitialViewportState.aborted &&
          _isMapReady) {
        _applyInitialViewport();
      }
    });

    // Observar disponibilidade de GPS (para Outros)
    ref.listen(locationStateProvider, (prev, next) {
      if (_viewportState != InitialViewportState.applied &&
          _viewportState != InitialViewportState.aborted &&
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
              // 🎯 Prioridade 1: Verificar modo armado de ocorrências
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
                      backgroundColor: SoloForteColors.greenIOS,
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

              // Markers de publicações locais (isolados)
              IsolatedLocalPublicationMarkersLayer(
                localPublications: _publicacoes,
              ),

              // Markers de ocorrências (isolados)
              IsolatedOccurrenceMarkersLayer(
                onOccurrenceTap: _handleOccurrencePinTap,
              ),

              // 🎯 ÚNICA LAYER QUE REBUILDA: Localização GPS
              const IsolatedUserLocationLayer(),
            ],
          ),

          // Controles do mapa (Consumer isolado)
          MapControlsOverlay(
            onCenterUser: _centerOnUser,
            onToggleDrawMode: _toggleDrawMode,
            onToggleOccurrenceMode: () {
              if (_armedMode == ArmedMode.occurrences) {
                // Desarmar e fechar o sheet
                setState(() => _armedMode = ArmedMode.none);
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                _setSheetState(null, 'Toggle OFF: Closing occurrence sheet');
              } else {
                _armOccurrenceMode();
              }
            },
            isDrawMode: _isDrawMode,
            isOccurrenceMode: _armedMode == ArmedMode.occurrences,
            drawingState: drawingState,
            onFinishDrawing: _finishDrawing,
            onCancelDrawing: () {
              ref.read(drawingControllerProvider).cancelOperation();
              setState(() => _isDrawMode = false);
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
            currentCenter: _isMapReady
                ? _mapController.camera.center
                : const LatLng(0, 0),
            currentZoom: _isMapReady ? _mapController.camera.zoom : 13.0,
            onTabSelected: (index, source) {
              // 🛡 REFATORAÇÃO: Mapear index para MapSheetType
              final sheetTypeMap = {
                1: MapSheetType.publications,
                2: MapSheetType.occurrences,
                3: MapSheetType.checkIn,
                4: MapSheetType.layers,
              };

              final currentType = _sheetState?.type;
              final newType = sheetTypeMap[index];

              if (currentType == newType) {
                // Toggle: fechar se já está aberto
                _setSheetState(
                  null,
                  'MapControlsOverlay: Toggle Close (Source: $source)',
                );
              } else {
                // Abrir nova tab
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

          // 🛡 CONSOLIDATION: Main BottomSheet
          // Conditional mount as requested
          if (_sheetState != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: MapBottomSheet(
                drawingController: ref.read(drawingControllerProvider),
                state: _sheetState!,
                onStateChange: (newState) {
                  _setSheetState(newState, 'MapBottomSheet: State Changed');
                  // Limpar pending location se mudar de tab
                  if (newState.type != MapSheetType.occurrences) {
                    setState(() => _pendingOccurrenceLocation = null);
                  }
                },
                onClose: () {
                  _setSheetState(null, 'MapBottomSheet: onClose');
                  setState(() {
                    _pendingOccurrenceLocation = null;
                  });
                },
                creationLocation: _pendingOccurrenceLocation,
                onOccurrenceArmed: _armOccurrenceMode,
                onLocationRequested: _centerOnUser,
              ),
            ),
        ],
      ),
    );
  }

  void _toggleDrawMode() {
    HapticFeedback.mediumImpact();
    final controller = ref.read(drawingControllerProvider);

    if (controller.currentState == DrawingState.idle) {
      // 🔧 FIX: Usar MapBottomSheet unificado ao invés de modal separado
      _setSheetState(
        const MapSheetState(type: MapSheetType.draw),
        'ToggleDrawMode: Opening draw sheet',
      );
      setState(() => _isDrawMode = true);
    } else {
      // 🎯 Se já está em algum modo (drawing, armed), cancela a operação
      controller.cancelOperation();
      setState(() => _isDrawMode = false);
      
      // Fechar o sheet também
      _setSheetState(null, 'ToggleDrawMode: Cancel and close');

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Desenho cancelado'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

// ════════════════════════════════════════════════════════════════════
// DADOS MOCK DE PUBLICAÇÃO (ADR-007)
// Estado local ao mapa. Sem provider global. Sem módulo externo.
// Será substituído por repositório real quando backend estiver pronto.
// ════════════════════════════════════════════════════════════════════

List<Publicacao> _getMockPublicacoes() {
  return [
    Publicacao(
      id: 'pub-001',
      latitude: -23.552,
      longitude: -46.635,
      createdAt: DateTime.now().subtract(const Duration(days: 5)),
      status: 'published',
      isVisible: true,
      type: PublicacaoType.resultado,
      title: 'Resultado Safra Soja',
      description: 'Aumento de 38% na produtividade após tratamento.',
      clientName: 'Fazenda Santa Rita',
      areaName: 'Talhão 12',
      media: const [
        MediaItem(id: 'm1', path: '', caption: 'Foto resultado', isCover: true),
      ],
    ),
    Publicacao(
      id: 'pub-002',
      latitude: -23.545,
      longitude: -46.625,
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
      status: 'published',
      isVisible: true,
      type: PublicacaoType.comparativo,
      title: 'Antes e Depois — Irrigação',
      description: 'Redução de 65% no consumo de água.',
      clientName: 'Granja São Pedro',
      areaName: 'Área Norte',
      media: const [
        MediaItem(id: 'm2', path: '', caption: 'Antes', isCover: true),
        MediaItem(id: 'm3', path: '', caption: 'Depois'),
      ],
    ),
    Publicacao(
      id: 'pub-003',
      latitude: -23.558,
      longitude: -46.642,
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      status: 'published',
      isVisible: true,
      type: PublicacaoType.caseSucesso,
      title: 'Case Produtividade Milho',
      description: 'Economia de R\$ 22k na safra com manejo correto.',
      clientName: 'Sítio Boa Esperança',
      media: const [
        MediaItem(
          id: 'm4',
          path: '',
          caption: 'Resultado final',
          isCover: true,
        ),
      ],
    ),
  ];
}
