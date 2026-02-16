import 'package:flutter/material.dart';
import '../../modules/map/design/sf_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/map_state.dart';
import '../../core/utils/map_logger.dart';
import '../../core/utils/debouncer.dart';
import '../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../modules/consultoria/services/talhao_map_adapter.dart';
import '../../modules/drawing/presentation/widgets/drawing_sheet.dart';
import '../../modules/drawing/presentation/widgets/drawing_layers.dart';
import '../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../modules/drawing/domain/drawing_state.dart';
import '../../modules/drawing/presentation/widgets/drawing_state_indicator.dart';
import '../../modules/dashboard/providers/location_providers.dart';
import '../../modules/dashboard/domain/location_state.dart';
import '../../modules/dashboard/services/location_service.dart';
import '../../modules/visitas/presentation/controllers/geofence_controller.dart';
import '../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../modules/consultoria/occurrences/domain/occurrence.dart' as occ;
import '../components/map/map_occurrence_sheet.dart';
import '../../core/domain/publicacao.dart';
import '../components/map/widgets/map_canvas.dart';
import '../components/map/widgets/map_layers.dart';
import '../components/map/widgets/map_markers.dart';
import '../components/map/widgets/map_controls_overlay.dart';
import '../components/map/widgets/isolated_marker_layers.dart';

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

  bool _hasInitialFocused = false;
  bool _isMapReady = false; // 🔒 Guard: MapController só pode ser usado se true
  bool _isDrawMode = false;
  ArmedMode _armedMode = ArmedMode.none; // Estado do modo armado

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

  void _handleAutoZoom(List<Publicacao>? pubs) {
    if (_hasInitialFocused || pubs == null || pubs.isEmpty) return;

    // 🔒 Guard: Só executar se o mapa estiver pronto
    if (!_isMapReady) return;

    // "Contexto Inicial Inteligente" - First Load Only
    _hasInitialFocused = true;

    try {
      final points = pubs.map((e) => LatLng(e.latitude, e.longitude)).toList();
      if (points.isNotEmpty) {
        final bounds = LatLngBounds.fromPoints(points);
        // Slightly delay to allow map to render size
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_isMapReady && mounted) {
            _mapController.fitCamera(
              CameraFit.bounds(
                bounds: bounds,
                padding: const EdgeInsets.all(50),
              ),
            );
          }
        });
      }
    } catch (_) {}
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

  void _openOccurrenceSheet(double lat, double lng) async {
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6, // Reduzir um pouco para não cobrir tudo de cara
        minChildSize: 0.4,
        maxChildSize: 0.9,
        expand: false,
        snap: true,
        builder: (_, controller) => MapOccurrenceSheet(
          scrollController: controller,
          latitude: lat,
          longitude: lng,
          onConfirm: (category, urgency, description) {
            ref
                .read(occurrenceControllerProvider)
                .createOccurrence(
                  type: urgency,
                  description: description,
                  lat: lat,
                  long: lng,
                  category: category,
                  status: 'draft',
                );

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Ocorrência registrada com sucesso!'),
                backgroundColor: SoloForteColors.greenIOS,
              ),
            );
          },
        ),
      ),
    );
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

    // Auto-focus Logic (mantido para zoom inicial)
    ref.listen(publicacoesDataProvider, (prev, next) {
      if (next.hasValue && !_hasInitialFocused) {
        _handleAutoZoom(next.value);
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
              setState(() => _isMapReady = true);

              // Tentar executar auto-zoom pendente após o mapa estar pronto
              if (!_hasInitialFocused) {
                final pubs = ref.read(publicacoesDataProvider).valueOrNull;
                if (pubs != null && pubs.isNotEmpty) {
                  _handleAutoZoom(pubs);
                }
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
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    isScrollControlled: true,
                    builder: (_) => DrawingSheet(controller: drawCtrl),
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
            isDrawMode: _isDrawMode,
          ),

          // Controles de finalização de desenho
          if (drawingState == DrawingState.drawing)
            Positioned(
              bottom: 100,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Botão Concluir
                  FloatingActionButton(
                    heroTag: 'complete_drawing',
                    backgroundColor: SoloForteColors.greenIOS,
                    onPressed: () async {
                      final controller = ref.read(drawingControllerProvider);

                      // Verificar se há pontos suficientes
                      if (controller.liveGeometry == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Adicione pelo menos 3 pontos para criar um polígono',
                            ),
                            duration: Duration(seconds: 2),
                          ),
                        );
                        return;
                      }

                      // Abrir sheet para adicionar metadados
                      // O sheet irá usar liveGeometry para criar a feature
                      await showModalBottomSheet(
                        context: context,
                        backgroundColor: Colors.transparent,
                        isScrollControlled: true,
                        builder: (_) => DrawingSheet(controller: controller),
                      );

                      // Desativar modo desenho
                      setState(() => _isDrawMode = false);
                    },
                    child: const Icon(SFIcons.check, color: Colors.white),
                  ),
                  const SizedBox(height: 12),
                  // Botão Cancelar
                  FloatingActionButton(
                    heroTag: 'cancel_drawing',
                    backgroundColor: Colors.redAccent,
                    onPressed: () {
                      final controller = ref.read(drawingControllerProvider);
                      controller.cancelOperation();

                      // Desativar modo desenho
                      setState(() => _isDrawMode = false);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Desenho cancelado'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: const Icon(SFIcons.close, color: Colors.white),
                  ),
                ],
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
      // 🎯 Se está idle, abre a seleção de ferramentas (BottomSheet)
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        useRootNavigator: true, // Garante que abra sobre a shell se necessário
        builder: (_) => DrawingSheet(controller: controller),
      ).then((_) {
        // Após fechar o sheet, sincronizamos o estado local
        if (mounted) {
          setState(() {
            _isDrawMode = controller.currentState != DrawingState.idle;
          });
        }
      });
    } else {
      // 🎯 Se já está em algum modo (drawing, armed), cancela a operação
      controller.cancelOperation();
      setState(() => _isDrawMode = false);

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
