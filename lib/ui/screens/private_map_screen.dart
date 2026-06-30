import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/state/map_ui_providers.dart';
import '../../core/state/map_state.dart';
import '../../core/config/map_config.dart';
import '../../core/config/map_secrets.dart';
import '../../core/services/offline_tile_cache_service.dart';
import '../../core/utils/coordinate_parser.dart';
import '../../modules/auth/services/auth_service.dart';
import '../../core/utils/app_logger.dart';
import '../../modules/drawing/presentation/providers/drawing_provider.dart';
import '../../modules/drawing/domain/drawing_state.dart';
import '../../modules/drawing/domain/models/drawing_models.dart';
import '../../modules/dashboard/providers/location_providers.dart';
import '../../modules/consultoria/occurrences/domain/occurrence.dart' as occ;
import '../../modules/marketing/domain/enums/case_tipo.dart';
import '../components/map/map_sheet_state.dart';
// 🔧 MODAL: imports para sheets dos tipos não-draw
// (conteúdo migrado para map_sheet_content_builder.dart — ADR-031 F3)
import '../../modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';
import 'map/providers/map_armed_mode_provider.dart';
import 'map/providers/map_ready_state_provider.dart';
import '../../modules/map/presentation/providers/map_location_mode_provider.dart';
import 'map/widgets/map_build_orchestrator.dart';
import 'map/handlers/map_location_handler.dart';
import 'map/controllers/map_viewport_controller.dart';
import 'map/controllers/map_sheet_controller.dart';
import 'map/handlers/novo_case_modal_launcher.dart';
import 'map/handlers/map_first_query_handler.dart';

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
  // 🔧 LIFECYCLE: Referência cacheada do DrawingController.
  // Capturada no build() para uso seguro no dispose() SEM ref.read().
  // ref é invalidado em deactivate() (antes de dispose()) — ADR-008.
  dynamic _drawingController;
  CaseTipo? _pendingMarketingCaseTipo;
  String? _handledMapFirstUri;

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
    });
  }

  void _scheduleMapFirstQueryHandling(Uri uri) {
    final key = uri.toString();
    if (_handledMapFirstUri == key) return;
    _handledMapFirstUri = key;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      MapFirstQueryHandler.handle(
        uri: uri,
        ref: ref,
        setSheetState: _setSheetState,
        armOccurrenceMode: _armOccurrenceMode,
        focusDrawing: _focusDrawingFromQuery,
      );
    });
  }

  Future<void> _focusDrawingFromQuery(
    String drawingId, {
    required bool edit,
  }) async {
    final controller = ref.read(drawingControllerProvider);
    await controller.loadFeatures();
    if (!mounted) return;

    DrawingFeature? feature;
    for (final item in controller.features) {
      if (item.id == drawingId) {
        feature = item;
        break;
      }
    }

    if (feature == null) {
      AppLogger.warning(
        'Drawing informado na rota não foi encontrado: $drawingId',
        tag: 'PrivateMap',
      );
      return;
    }

    controller.selectFeature(feature);
    MapViewportController.focusDrawingFeature(
      mapController: _mapController,
      feature: feature,
    );

    if (edit) {
      controller.startEditMode();
    }
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
    MapLocationHandler.stopFollowing();

    super.dispose();
  }

  // 🔎 INSTRUMENTATION: Rastrear quem altera o estado
  void _setSheetState(MapSheetState? state, String reason) {
    if (state != null) {
      _pendingMarketingCaseTipo = null;
    }
    final currentSheet = ref.read(mapSheetStateProvider);
    AppLogger.debug(
      'SHEET CHANGE | old=${currentSheet?.type} | new=${state?.type} | reason=$reason',
      tag: 'PrivateMap',
    );

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
    // demais tipos abrem como sheet modal padronizado
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
    final initialTipo = _pendingMarketingCaseTipo;
    _pendingMarketingCaseTipo = null;
    NovoCaseModalLauncher.launch(
      position: latLng,
      context: context,
      ref: ref,
      initialTipo: initialTipo,
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
    _setSheetState(
      const MapSheetState(type: MapSheetType.draw),
      'FinishDrawing: Opening draw review sheet',
    );
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

  void _handleLocationModeChanged(MapLocationMode mode) {
    switch (mode) {
      case MapLocationMode.idle:
        MapLocationHandler.stopFollowing();
        break;
      case MapLocationMode.following:
      case MapLocationMode.northLocked:
        MapLocationHandler.startFollowing(
          // Riverpod 2.x exposes the provider stream; this keeps the existing
          // GPS source and avoids creating another location pipeline.
          // ignore: deprecated_member_use
          locationStream: ref.read(locationStreamProvider.stream),
          mapController: _mapController,
          isMapReady: ref.read(mapReadyStateProvider),
        );
        break;
    }
  }

  void _armOccurrenceMode() {
    // FIX 1: Entrar em modo seleção — usuário toca no mapa para capturar LatLng
    _pendingMarketingCaseTipo = null;
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

  Future<void> _openCoordinateSearch() async {
    final controller = TextEditingController();
    final value = await showDialog<String>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Ir para coordenada'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: 'Ex: -10.1823,-48.3331 | 22K 788000 8872000',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: const Text('Ir'),
            ),
          ],
        );
      },
    );
    if (!mounted || value == null || value.isEmpty) return;

    final parsed = CoordinateParser.parse(value);
    if (parsed == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Formato inválido. Use decimal, DMS/DDM (com hemisfério) ou UTM.',
          ),
        ),
      );
      return;
    }

    _mapController.move(parsed, 17.0);
    ref.read(destinationCoordinateMarkerProvider.notifier).state = parsed;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Destino: ${parsed.latitude.toStringAsFixed(6)}, '
          '${parsed.longitude.toStringAsFixed(6)}',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _downloadOfflineArea() async {
    final minZoomController = TextEditingController(text: '12');
    final maxZoomController = TextEditingController(text: '18');

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Baixar área offline'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Será usada a área visível atual do mapa (bounding box).',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: minZoomController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Zoom mínimo'),
            ),
            TextField(
              controller: maxZoomController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Zoom máximo'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Baixar'),
          ),
        ],
      ),
    );
    if (!mounted || submitted != true) return;

    final minZoom = int.tryParse(minZoomController.text) ?? 12;
    final maxZoom = int.tryParse(maxZoomController.text) ?? 18;
    final bounds = _mapController.camera.visibleBounds;
    final south = bounds.south;
    final north = bounds.north;
    final west = bounds.west;
    final east = bounds.east;

    final activeLayer = ref.read(activeLayerProvider);
    final tileConfig = MapConfig.tileConfigForLayer(
      activeLayer,
      mapTilerApiKey: kMapTilerApiKey,
    );
    final cacheService = ref.read(offlineTileCacheServiceProvider);
    final layerKey = cacheService.layerKeyFromTemplate(tileConfig.urlTemplate);
    late final int estimatedTiles;
    try {
      estimatedTiles = cacheService.estimateTileCount(
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: minZoom,
        maxZoom: maxZoom,
      );
      if (estimatedTiles > OfflineTileCacheService.maxTileDownloadCount) {
        throw OfflineTileCacheException(
          'Área excede o limite de '
          '${OfflineTileCacheService.maxTileDownloadCount} tiles '
          '($estimatedTiles solicitados). Reduza o zoom máximo ou aproxime o mapa.',
        );
      }
    } on OfflineTileCacheException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    bool cancelRequested = false;
    final progress = ValueNotifier(
      OfflinePrefetchProgress(
        total: estimatedTiles,
        processed: 0,
        downloaded: 0,
        skipped: 0,
        failed: 0,
      ),
    );
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Baixando área offline'),
        content: ValueListenableBuilder<OfflinePrefetchProgress>(
          valueListenable: progress,
          builder: (_, value, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              LinearProgressIndicator(value: value.fraction),
              const SizedBox(height: 12),
              Text('${value.processed} de ${value.total} tiles'),
              if (value.failed > 0) Text('Falhas: ${value.failed}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => cancelRequested = true,
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );

    late final OfflinePrefetchResult result;
    try {
      result = await cacheService.prefetchArea(
        layerKey: layerKey,
        urlTemplate: tileConfig.urlTemplate,
        subdomains: tileConfig.subdomains,
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: minZoom,
        maxZoom: maxZoom,
        headers: {'User-Agent': MapConfig.userAgent},
        onProgress: (value) => progress.value = value,
        shouldCancel: () => cancelRequested,
      );
    } on OfflineTileCacheException catch (e) {
      if (mounted) Navigator.of(context, rootNavigator: true).pop();
      progress.dispose();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    progress.dispose();
    if (!mounted) return;
    if (!result.isComplete) {
      final message = result.cancelled
          ? 'Download offline cancelado.'
          : 'Download incompleto: ${result.failed} tile(s) falharam. Tente novamente.';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      return;
    }

    ref
        .read(offlineMapAreasProvider.notifier)
        .addArea(
          OfflineMapAreaConfig(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            layerKey: layerKey,
            south: south,
            west: west,
            north: north,
            east: east,
            minZoom: minZoom.toDouble(),
            maxZoom: maxZoom.toDouble(),
            createdAt: DateTime.now(),
          ),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Área offline baixada: ${result.downloaded} tile(s) novo(s), '
          '${result.skipped} já existente(s)'
          ' (${south.toStringAsFixed(4)},${west.toStringAsFixed(4)})'
          ' → (${north.toStringAsFixed(4)},${east.toStringAsFixed(4)})',
        ),
      ),
    );
  }

  void _openOccurrenceSheet(double lat, double lng) async {
    // 🛡 CONSOLIDATION: Redirect to MapBottomSheet
    if (!mounted) return;

    // O ponto precisa existir antes do sheet para evitar o primeiro frame em 0,0.
    ref.read(pendingOccurrenceLocationProvider.notifier).state = LatLng(
      lat,
      lng,
    );

    // Usando setter instrumentado
    _setSheetState(
      const MapSheetState(
        type: MapSheetType.occurrences,
        isCreatingOccurrence: true,
      ),
      'OpenOccurrenceSheet (Create Mode)',
    );
  }

  void _armMarketingMode(CaseTipo tipo) {
    _pendingMarketingCaseTipo = tipo;
    ref.read(armedModeProvider.notifier).state = ArmedMode.marketing;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Toque no mapa para localizar o case de ${_caseTipoLabel(tipo)}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _caseTipoLabel(CaseTipo tipo) {
    switch (tipo) {
      case CaseTipo.resultado:
        return 'resultado';
      case CaseTipo.antesDepois:
        return 'antes/depois';
      case CaseTipo.avaliacao:
        return 'avaliação';
    }
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
    _scheduleMapFirstQueryHandling(GoRouterState.of(context).uri);

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
      onLocationModeChanged: _handleLocationModeChanged,
      stopFollowing: MapLocationHandler.stopFollowing,
      armOccurrenceMode: _armOccurrenceMode,
      armMarketingMode: _armMarketingMode,
      handleOccurrencePinTap: _handleOccurrencePinTap,
      applyInitialViewport: _applyInitialViewport,
      openCoordinateSearch: _openCoordinateSearch,
      downloadOfflineArea: _downloadOfflineArea,
    );
  }
}
