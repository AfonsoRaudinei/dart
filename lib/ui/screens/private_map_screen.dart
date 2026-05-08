import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/map_ui_providers.dart';
import '../../modules/auth/services/auth_service.dart';
import '../../core/utils/app_logger.dart';
import '../../core/utils/debouncer.dart';
import '../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../modules/drawing/domain/drawing_state.dart';
import '../../modules/dashboard/providers/location_providers.dart';
import '../../modules/consultoria/occurrences/domain/occurrence.dart' as occ;
import '../components/map/map_sheet_state.dart';
// 🔧 MODAL: imports para showModalBottomSheet dos tipos não-draw
// (conteúdo migrado para map_sheet_content_builder.dart — ADR-031 F3)
import '../../modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';
import 'map/providers/map_armed_mode_provider.dart';
import 'map/providers/map_ready_state_provider.dart';
import 'map/widgets/map_build_orchestrator.dart';
import 'map/handlers/map_location_handler.dart';
import 'map/controllers/map_viewport_controller.dart';
import 'map/controllers/map_sheet_controller.dart';
import 'map/handlers/novo_case_modal_launcher.dart';

// ADR-032 F1: _isMapReady migrado → mapReadyStateProvider (autoDispose).
// Bloqueador restante: _setSheetState (modal state).

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

    // 🐛 BUGFIX: Fechar modal branco (layers/checkIn) antes de renderizar
    // sheet escuro no Stack. Sem isso, o modal fica vivo atrás e reaparece
    // ao fechar o MapBottomSheet. Padrão idêntico ao onTabSelected do orchestrator.
    // R-1: rootNavigator: false garante que o pop nunca escala até o GoRouter raiz,
    // mesmo se isModalOpenProvider dessincronizar por swipe dismiss.
    if (ref.read(isModalOpenProvider) && context.mounted) {
      Navigator.of(context, rootNavigator: false).pop();
      ref.read(modalGenerationProvider.notifier).state++;
      ref.read(isModalOpenProvider.notifier).state = false;
    }

    ref.read(mapSheetStateProvider.notifier).state = state;

    // 🔧 MODAL: draw e occurrences permanecem no Stack;
    // demais tipos abrem como showModalBottomSheet
    if (state == null ||
        state.type == MapSheetType.draw ||
        state.type == MapSheetType.occurrences) {
      return;
    }
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
      isMapReady: ref.read(mapReadyStateProvider),
      isMounted: mounted,
    );
  }

  Future<void> _requestLocationPermission() async {
    await MapLocationHandler.requestPermission(
      ref: ref,
      context: context,
      mapController: _mapController,
      isMapReady: ref.read(mapReadyStateProvider),
    );
  }

  void _centerOnUser() async {
    await MapLocationHandler.centerOnUser(
      ref: ref,
      context: context,
      mapController: _mapController,
      isMapReady: ref.read(mapReadyStateProvider),
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
    // 🛡 LIFECYCLE: Cachear referência do DrawingController para uso
    // seguro no dispose() — ref é invalidado antes de dispose() ser chamado.
    _drawingController = ref.read(drawingControllerProvider);

    // ADR-032 F3: Build orchestrado por MapBuildOrchestrator.
    // Todo o conteúdo do Stack (canvas, layers, overlays, controls, sheet)
    // vive em map/widgets/map_build_orchestrator.dart.
    return MapBuildOrchestrator(
      mapController: _mapController,
      setSheetState: _setSheetState,
      openOccurrenceSheet: _openOccurrenceSheet,
      handleMapLongPress: _handleMapLongPress,
      finishDrawing: _finishDrawing,
      toggleDrawMode: _toggleDrawMode,
      centerOnUser: _centerOnUser,
      armOccurrenceMode: _armOccurrenceMode,
      armMarketingMode: _armMarketingMode,
      handleOccurrencePinTap: _handleOccurrencePinTap,
      applyInitialViewport: _applyInitialViewport,
    );
  }
}
