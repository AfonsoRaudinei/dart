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
import '../../modules/marketing/presentation/widgets/marketing_case_marker.dart';
import '../../modules/marketing/presentation/widgets/marketing_case_sheet.dart';
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
import '../../modules/marketing/presentation/screens/novo_case_sheet.dart';
import '../../modules/marketing/presentation/widgets/draft_saved_sheet.dart';
import '../components/map/map_bottom_sheet.dart';
import '../components/map/widgets/map_canvas.dart';
import '../components/map/widgets/map_layers.dart';
import '../components/map/widgets/map_markers.dart';
import '../components/map/widgets/map_controls_overlay.dart';
import '../components/map/widgets/isolated_marker_layers.dart';
import '../../modules/drawing/presentation/widgets/drawing_edit_layer.dart';
import '../../core/domain/map_models.dart';
import '../components/map/map_sheet_state.dart';
// ADR-012 — planos/
import '../../modules/planos/presentation/providers/plano_providers.dart';
import 'widgets/plano_block_sheet.dart';
// 🔧 MODAL: imports para showModalBottomSheet dos tipos não-draw
import '../components/map/map_sheets.dart';
import '../../modules/consultoria/occurrences/presentation/widgets/occurrence_list_sheet.dart';
import '../../modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import '../../modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import '../../modules/visitas/presentation/widgets/visit_sheet.dart';
import '../../modules/visitas/presentation/controllers/visit_controller.dart';
import '../../modules/agenda/presentation/providers/agenda_provider.dart';
import '../../modules/agenda/domain/enums/event_status.dart';
import '../../modules/map/design/sf_icons.dart';

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

  // 🔧 MODAL: Controle de modais ativos
  bool _isModalOpen = false;
  int _modalGeneration = 0;

  @override
  void initState() {
    super.initState();
    // Inicializar GPS ao carregar a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationStateProvider.notifier).init();
      ref.read(geofenceControllerProvider); // Start Geofence Monitoring

      // Bootstrap silencioso: garantir perfil completo.
      // Fire-and-forget — sem await, sem loading, sem rebuild.
      // Cobre edge case de perfil eternamente vazio após email confirmation.
      ref.read(authServiceProvider.notifier).ensureProfileComplete().catchError(
        (e) {
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
          // Pré-seleciona cliente no DrawingController existente
          ref
              .read(drawingControllerProvider)
              .setClienteAtivo(clienteIdParam);
          // Abre o painel de desenho (mecanismo já existente)
          _setSheetState(
            const MapSheetState(type: MapSheetType.draw),
            'query_param_modo_desenho',
          );
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
    ref.read(drawingControllerProvider).cancelOperation();

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
    // 🔒 Gate 0: Se já aplicado ou abortado, TERMINAR IMEDIATAMENTE.
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
    // � BUGFIX: Abrir formulário de criação diretamente
    _openOccurrenceCreationSheet();
  }

  void _openOccurrenceCreationSheet() async {
    // Obter posição atual ou usar centro do mapa
    final locationService = LocationService();
    final position = await locationService.getCurrentPosition();

    // 🛡 HARDENING: Guard após await — widget pode ter sido desmontado
    if (!mounted) return;

    final lat = position?.latitude ?? _mapController.camera.center.latitude;
    final lng = position?.longitude ?? _mapController.camera.center.longitude;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => OccurrenceCreationSheet(
        latitude: lat,
        longitude: lng,
        onCancel: () => Navigator.of(context).pop(),
        onConfirm: (data) {
          ref.read(occurrenceControllerProvider).createOccurrence(
            type: data.type,
            description: data.description,
            photoPath: data.photoPath,
            lat: lat,
            long: lng,
            category: data.category,
            status: 'draft',
            cultivar: data.cultivar,
            dataPlantio: data.dataPlantio,
            estadioFenologico: data.estadioFenologico,
            tipoOcorrencia: data.tipoOcorrencia,
            amostraSolo: data.amostraSolo,
            recomendacoes: data.recomendacoes,
            metricasJson: data.metricasJson,
            nutrientesJson: data.nutrientesJson,
            categoriasJson: data.categoriasJson,
            notasCategoriasJson: data.notasCategoriasJson,
            fotosCategoriasJson: data.fotosCategoriasJson,
          );

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Ocorrência registrada com sucesso!'),
              backgroundColor: PremiumTokens.brandGreen,
            ),
          );

          Navigator.of(context).pop();
        },
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

  void _handleMapLongPress(TapPosition tapPos, LatLng latLng) {
    if (!mounted) return;

    // Abre NovoCaseSheet sempre — verificação de plano ocorre no onPublicar
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Flexible(
              child: NovoCaseSheet(
                lat: latLng.latitude,
                lng: latLng.longitude,
                onClose: () => Navigator.of(context).pop(),
                onPublicar: (newCase) async {
                  // Verifica plano APÓS preenchimento do formulário
                  final plano = ref.read(planoAtivoProvider).valueOrNull;

                  if (plano == null || plano.expirado) {
                    // Sem plano → salva como rascunho
                    try {
                      await ref
                          .read(marketingCasesProvider.notifier)
                          .saveAsDraft(newCase);

                      if (!mounted) return;

                      // Fecha o NovoCaseSheet
                      Navigator.of(context).pop();

                      // Exibe DraftSavedSheet e captura decisão do usuário.
                      // O modal fecha por conta própria (Navigator.pop interno).
                      // A navegação ocorre AQUI, no contexto do PrivateMapScreen.
                      final goToPlanos = await DraftSavedSheet.show(context);

                      if (!mounted) return;
                      if (goToPlanos == true) {
                        context.go('/planos');
                      }
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erro ao salvar rascunho: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                    return;
                  }

                  // Com plano → verifica limite de cases publicados
                  final cases =
                      ref.read(marketingCasesProvider).valueOrNull ?? [];
                  final casesPublicados = cases
                      .where(
                        (c) =>
                            c.status.toValue() == 'published' &&
                            c.ativo &&
                            c.deletadoEm == null,
                      )
                      .length;

                  if (casesPublicados >= plano.limiteCases) {
                    // Limite atingido
                    if (!mounted) return;
                    Navigator.of(context).pop(); // Fecha NovoCaseSheet
                    PlanoBlockSheet.show(
                      context,
                      motivo: 'limite_atingido',
                      planoLabel: plano.plano.label,
                    );
                    return;
                  }

                  // Publica normalmente
                  Navigator.of(context).pop(); // Fecha o sheet

                  final saved = await ref
                      .read(marketingCasesProvider.notifier)
                      .publishCase(newCase);

                  if (!mounted) return;
                  if (saved != null) {
                    HapticFeedback.heavyImpact();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text('Case publicado com sucesso! 📈'),
                          ],
                        ),
                        backgroundColor: const Color(0xFF34C759),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Row(
                          children: [
                            Icon(
                              Icons.cloud_off,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Sem conexão — case salvo localmente e será sincronizado.',
                              ),
                            ),
                          ],
                        ),
                        backgroundColor: Colors.orange.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
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
        backgroundColor: PremiumTokens.brandGreen,
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
    // Transição para reviewing é suficiente — sem sincronizaçao local necessária
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
    final sheetState = ref.watch(mapSheetStateProvider);

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
      final vp = ref.read(viewportStateProvider);
      if (vp != InitialViewportState.applied &&
          vp != InitialViewportState.aborted &&
          _isMapReady) {
        _applyInitialViewport();
      }
    });

    // Observar disponibilidade de GPS (para Outros)
    ref.listen(locationStateProvider, (prev, next) {
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

              // Markers de Marketing (apenas cases publicados)
              if (ref.watch(marketingCasesProvider).hasValue)
                MarkerLayer(
                  markers:
                      (ref
                              .watch(marketingCasesProvider)
                              .value!
                              .where(
                                (c) =>
                                    c.status.toValue() == 'published' &&
                                    c.ativo &&
                                    c.deletadoEm == null,
                              )
                              .toList()
                            ..sort(
                              (a, b) => b.visibilidade.index.compareTo(
                                a.visibilidade.index,
                              ),
                            ))
                          .map((mCase) {
                            return Marker(
                              point: LatLng(mCase.lat, mCase.lng),
                              width: 100,
                              height: 100,
                              alignment: Alignment.center,
                              child: MarketingCaseMarker(
                                marketingCase: mCase,
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  MarketingCaseSheet.show(context, mCase);
                                },
                              ),
                            );
                          })
                          .toList(),
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
            isCheckInActive:
                ref.watch(visitControllerProvider).valueOrNull?.status ==
                'active',
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

          // 🛡 CONSOLIDATION: DrawingSheet permanece no Stack (draw type)
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
        ],
      ),
    );
  }

  // 🔧 MODAL: Abre os tipos publications/occurrences/checkIn/layers como modal nativo
  void _openSheetAsModal(BuildContext context, MapSheetState state) {
    if (_isModalOpen) return;
    if (!mounted) return;
    setState(() => _isModalOpen = true);
    final gen = ++_modalGeneration;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.15),
      enableDrag: true,
      isDismissible: true,
      builder: (modalContext) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        snap: true,
        snapSizes: const [0.5, 0.9],
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).dividerColor.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Expanded(child: _buildSheetContent(state, scrollController)),
            ],
          ),
        ),
      ),
    ).whenComplete(() {
      if (mounted && gen == _modalGeneration) {
        setState(() => _isModalOpen = false);
        final currentState = ref.read(mapSheetStateProvider);
        if (currentState?.type == state.type) {
          _setSheetState(null, 'Modal: whenComplete dismiss');
        }
      }
    });
  }

  // 🔧 MODAL: Conteúdo específico por tipo (recebe scrollController do DraggableScrollableSheet)
  Widget _buildSheetContent(
    MapSheetState state,
    ScrollController scrollController,
  ) {
    switch (state.type) {
      case MapSheetType.layers:
        return SingleChildScrollView(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          child: LayersSheet(onClose: () => Navigator.of(context).pop()),
        );
      case MapSheetType.occurrences:
        if (state.isCreatingOccurrence && _pendingOccurrenceLocation != null) {
          final lat = _pendingOccurrenceLocation!.latitude;
          final lng = _pendingOccurrenceLocation!.longitude;
          // 🐛 BUGFIX: Usar OccurrenceCreationSheet (formulário correto, schema v14)
          return OccurrenceCreationSheet(
            latitude: lat,
            longitude: lng,
            scrollController: scrollController,
            onCancel: () => Navigator.of(context).pop(),
            onConfirm: (data) {
              ref.read(occurrenceControllerProvider).createOccurrence(
                type: data.type,
                description: data.description,
                photoPath: data.photoPath,
                lat: lat,
                long: lng,
                category: data.category,
                status: 'draft',
                cultivar: data.cultivar,
                dataPlantio: data.dataPlantio,
                estadioFenologico: data.estadioFenologico,
                tipoOcorrencia: data.tipoOcorrencia,
                amostraSolo: data.amostraSolo,
                recomendacoes: data.recomendacoes,
                metricasJson: data.metricasJson,
                nutrientesJson: data.nutrientesJson,
                categoriasJson: data.categoriasJson,
                notasCategoriasJson: data.notasCategoriasJson,
                fotosCategoriasJson: data.fotosCategoriasJson,
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ocorrência registrada com sucesso!'),
                  backgroundColor: PremiumTokens.brandGreen,
                ),
              );
              Navigator.of(context).pop();
            },
          );
        }
        // R1: showHandle + showDecoration false evitam duplicação visual com o modal
        // R2: scrollController conectado ao DraggableScrollableSheet para drag-to-dismiss
        return OccurrenceListSheet(
          scrollController: scrollController,
          showHandle: false,
          showDecoration: false,
          mapBounds: null,
          onClose: () => Navigator.of(context).pop(),
          onOccurrenceTap: (occurrence) {
            AppLogger.debug(
              'Ocorrência tocada: ${occurrence.id}',
              tag: 'MapSheet',
            );
          },
          onRequestNewOccurrence: () {
            // 🐛 BUGFIX: Fechar lista e abrir formulário de criação diretamente
            Navigator.of(context).pop();
            _openOccurrenceCreationSheet();
          },
        );
      case MapSheetType.checkIn:
        return Consumer(
          builder: (ctx, widgetRef, _) {
            final visitState = widgetRef.watch(visitControllerProvider);
            final isActive = visitState.value?.status == 'active';
            if (isActive) {
              return _buildActiveVisitContent(widgetRef);
            }
            return VisitSheet(
              preSelectedClienteId: state.preSelectedClienteId,
              onConfirm: (clientId, areaId, activity) {
                widgetRef
                    .read(visitControllerProvider.notifier)
                    .startSession(clientId, areaId, activity, 0.0, 0.0);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Visita iniciada. Bom trabalho!'),
                    backgroundColor: PremiumTokens.brandGreenDark,
                  ),
                );
                Navigator.of(context).pop();
              },
            );
          },
        );
      case MapSheetType.draw:
        // Nunca deve chegar aqui — draw permanece no Stack
        return const SizedBox.shrink();
    }
  }

  // 🔧 MODAL: UI de visita ativa no checkIn sheet
  Widget _buildActiveVisitContent(WidgetRef widgetRef) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(SFIcons.checkCircle, size: 64, color: PremiumTokens.brandGreen),
          const SizedBox(height: 16),
          Text(
            'Visita em Andamento',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () async {
              final agendaState = widgetRef.read(agendaProvider);
              final activeSession = agendaState.sessions
                  .where((s) => s.endAtReal == null)
                  .firstOrNull;
              if (activeSession == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Nenhuma visita ativa encontrada.'),
                    ),
                  );
                }
                return;
              }
              final linkedEvent = agendaState.events
                  .where((e) => e.visitSessionId == activeSession.id)
                  .firstOrNull;
              if (linkedEvent == null) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Evento vinculado não encontrado.'),
                    ),
                  );
                }
                return;
              }
              try {
                if (linkedEvent.status == EventStatus.emAndamento) {
                  await widgetRef
                      .read(agendaProvider.notifier)
                      .finalizeEvent(linkedEvent.id);
                }
                await widgetRef
                    .read(agendaProvider.notifier)
                    .completeEvent(linkedEvent.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Visita encerrada com sucesso.'),
                    ),
                  );
                  Navigator.of(context).pop();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro ao encerrar visita: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumTokens.alertError,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: const Text('Encerrar Visita'),
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
    } else {
      // 🎯 Se já está em algum modo (drawing, armed), cancela a operação
      controller.cancelOperation();
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
