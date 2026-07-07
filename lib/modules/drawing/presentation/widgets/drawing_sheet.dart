import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../coordinators/drawing_close_coordinator.dart';
import '../controllers/drawing_controller.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/models/gps_walk_session.dart';
import '../../domain/drawing_state.dart';
import '../../domain/repositories/i_clients_repository.dart';
import '../providers/drawing_client_provider.dart';
import '../providers/gps_walk_providers.dart';
import '../providers/drawing_export_provider.dart';
import '../../../dashboard/providers/location_providers.dart';
import '../../../../core/constants/layout_constants.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../../core/utils/share_position.dart';
import 'components/drawing_tool_selector.dart';
import 'components/drawing_actions_bar.dart';
import 'drawing_info_edit_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import 'gps_walk_controls_overlay.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

part 'drawing_sheet_builders_a.dart';
part 'drawing_sheet_builders_b.dart';
part 'drawing_sheet_widgets.dart';

// Responsabilidade: container/shell do sheet de desenho
// (layout, estado e ciclo de vida; não concentra os itens de ferramenta).
// Os itens de ferramenta ficam em:
// lib/modules/drawing/presentation/widgets/components/drawing_tool_selector.dart
class DrawingSheet extends ConsumerStatefulWidget {
  final DrawingController controller;
  final ScrollController? scrollController;
  final ValueChanged<DrawingFeature>? onFocusFeature;
  final VoidCallback? onGpsMeasureStarted;
  final VoidCallback? onSaved;
  final VoidCallback? onClose;

  const DrawingSheet({
    super.key,
    required this.controller,
    this.scrollController,
    this.onFocusFeature,
    this.onGpsMeasureStarted,
    this.onSaved,
    this.onClose,
  });

  @override
  ConsumerState<DrawingSheet> createState() => _DrawingSheetState();
}

class _DrawingSheetState extends ConsumerState<DrawingSheet> {
  String? _selectedToolKey;
  bool _isSaving = false;
  bool _isEditingMetadata = false;

  // 🆕 ESTADO LOCAL PARA REVISÃO COMPLETA
  final _formKey = GlobalKey<FormState>();

  // Hierarquia: Cliente -> Fazenda -> Talhão
  Client? _selectedClient;
  Farm? _selectedFarm;
  final bool _isConsultant = true; // TODO: Obter do AuthProvider

  Color _selectedColor = PremiumTokens.brandGreen;

  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Auto-load clients via DrawingClientNotifier (ADR-019)
      if (_isConsultant) {
        ref.read(drawingClientProvider.notifier).loadClients();
      }
      // Sincronizar pré-seleção inicial
      _syncPreSelectedContext(ref.read(drawingClientProvider));
    });

    // Suggest logical name
    _nomeController.text = "Talhão Novo";
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  /// Aplica pré-seleção de cliente/fazenda proveniente do fluxo Map-First.
  /// Chamado via ref.listen e no postFrameCallback inicial.
  void _syncPreSelectedContext(DrawingClientState clientState) {
    final preClientId = clientState.preSelectedClientId;
    if (preClientId == null || !mounted) return;

    Client? nextClient = _selectedClient;
    final clientMatches = clientState.clients.where((c) => c.id == preClientId);
    if (clientMatches.isNotEmpty) {
      nextClient = clientMatches.first;
    } else if (_selectedClient == null &&
        clientState.preSelectedClientName != null) {
      nextClient = Client(
        id: preClientId,
        name: clientState.preSelectedClientName!,
      );
    }

    Farm? nextFarm = _selectedFarm;
    final preFarmId = clientState.preSelectedFarmId;
    if (preFarmId != null) {
      final farmMatches = clientState.farms.where((f) => f.id == preFarmId);
      if (farmMatches.isNotEmpty) {
        nextFarm = farmMatches.first;
      } else if ((_selectedFarm == null || _selectedFarm!.id != preFarmId) &&
          clientState.preSelectedFarmName != null) {
        nextFarm = Farm(
          id: preFarmId,
          clientId: preClientId,
          name: clientState.preSelectedFarmName!,
          city: '',
          state: '',
        );
      }
    }

    final shouldUpdateClient =
        nextClient != null && nextClient != _selectedClient;
    final shouldUpdateFarm =
        preFarmId != null && nextFarm != null && nextFarm != _selectedFarm;

    if (shouldUpdateClient || shouldUpdateFarm) {
      setState(() {
        if (shouldUpdateClient) {
          _selectedClient = nextClient;
        }
        if (shouldUpdateFarm) {
          _selectedFarm = nextFarm;
        }
      });
    }
  }

  double _parseArea(String value) {
    return double.tryParse(value.replaceAll(',', '.').trim()) ?? 0;
  }

  Future<void> _requestClose(
    DrawingCloseIntent intent, {
    bool preferSavedCallback = false,
  }) async {
    final decision = await DrawingCloseCoordinator.handle(
      context,
      controller: widget.controller,
      intent: intent,
    );
    if (!mounted || !decision.shouldCloseSheet) return;
    _emitCloseCallback(preferSavedCallback: preferSavedCallback);
  }

  void _emitCloseCallback({bool preferSavedCallback = false}) {
    if (preferSavedCallback && widget.onSaved != null) {
      widget.onSaved!.call();
      return;
    }
    if (widget.onClose != null) {
      widget.onClose!.call();
      return;
    }
    widget.onSaved?.call();
  }

  Future<void> _handleClosePressed() async {
    await _requestClose(DrawingCloseIntent.dismissSheet);
  }

  void _onToolSelected(String key) {
    if (key == 'import') {
      widget.controller.pickImportFile();
      setState(() {
        _selectedToolKey = null; // No visual toggle for import, it changes mode
      });
      return;
    }

    // GPS Walk Mode — tratamento especial via GpsWalkController (não via selectTool)
    if (key == 'gps') {
      final bool isActive = _selectedToolKey == 'gps';
      if (isActive) {
        // Toggle OFF: cancela sessão GPS Walk ativa
        ref.read(gpsWalkProvider.notifier).cancel();
        setState(() => _selectedToolKey = null);
      } else {
        // Toggle ON: ativa GPS Walk em estado idle (NÃO inicia GPS stream ainda)
        setState(() => _selectedToolKey = 'gps');
        ref.read(gpsWalkProvider.notifier).activate();
        // Registra listener para sincronizar métricas quando gpsVertices muda
        _setupGpsVerticesListener();
      }
      return;
    }

    // Toggle: se já está selecionado, desativa
    final bool shouldActivate = _selectedToolKey != key;

    setState(() {
      _selectedToolKey = shouldActivate ? key : null;
    });

    // 🔧 FIX CRÍTICO: Notificar o controller para ativar/desativar a ferramenta
    if (shouldActivate) {
      widget.controller.selectTool(key);
      // 🔧 FIX-DRAW-FLOW-01: Ativar modo de desenho sem fechar bottom sheet
      // O MapBottomSheet permanece aberto para o usuário ver ferramentas ativas
    } else {
      widget.controller.selectTool('none'); // Desativa ferramenta
    }
  }

  /// Registra listener para sincronizar pontos GPS → GpsWalkController.
  ///
  /// Chamado uma vez ao ativar GPS Walk. O listener atualiza métricas
  /// no GpsWalkController sempre que novos vértices GPS são coletados.
  void _setupGpsVerticesListener() {
    // A sincronização ocorre no build() via ListenableBuilder.
    // Este método existe apenas para compatibilidade semântica.
  }

  /*
  Widget _buildSyncBadge(SyncStatus status) {
  ...
  */

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final safeBottom = MediaQuery.of(context).padding.bottom;

    // ADR-019: escuta mudancas de clientes para pre-selecao Map-First
    ref.listen<DrawingClientState>(drawingClientProvider, (_, next) {
      _syncPreSelectedContext(next);
    });

    // ── GPS Walk: resetar seleção quando sessão é cancelada/finalizada ───────
    ref.listen<GpsWalkSession?>(gpsWalkProvider, (prev, next) {
      if (prev != null && next == null && _selectedToolKey == 'gps') {
        setState(() => _selectedToolKey = null);
      }
      if (prev?.status == GpsWalkStatus.idle &&
          next?.status == GpsWalkStatus.measuring) {
        widget.onGpsMeasureStarted?.call();
      }
    });

    ref.listen<ExportState>(drawingExportProvider, (_, next) {
      if (!mounted) return;
      if (next is ExportSuccess) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Exportado: ${next.fileName}')));
        ref.read(drawingExportProvider.notifier).reset();
      } else if (next is ExportError) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(next.message)));
        ref.read(drawingExportProvider.notifier).reset();
      }
    });

    // NOTA ARQUITETURAL: O handle (pílula de drag) é renderizado pelo
    // componente pai (lib/ui/screens/private_map_sheets.dart / MapBottomSheet).
    // Este widget não inclui handle próprio.
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: SoloForteSheetTokens.sheetBackground,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 4. Cabeçalho Fixo (Fonte Única)
            _SheetHeader(
              onBack: _isEditingMetadata
                  ? () => setState(() => _isEditingMetadata = false)
                  : null,
              onClose: _handleClosePressed,
            ),

            // Conteúdo Dinâmico
            Flexible(
              child: SingleChildScrollView(
                controller: widget.scrollController,
                physics: const BouncingScrollPhysics(),
                child: ListenableBuilder(
                  listenable: widget.controller,
                  builder: (context, _) {
                    // ── GPS Walk: sincronizar métricas a cada novo vértice GPS ────
                    final gpsSession = ref.watch(gpsWalkProvider);
                    if (gpsSession != null) {
                      // Sincroniza pontos do DrawingController → GpsWalkNotifier
                      final pts = widget.controller.gpsVertices;
                      if (pts.length != gpsSession.points.length) {
                        // Schedule post-frame para não chamar durante build
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          ref
                              .read(gpsWalkProvider.notifier)
                              .syncFromController(pts);
                        });
                      }
                      return const GpsWalkControlsOverlay();
                    }

                    final content = Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Always calculate and show metrics if available
                        _buildMetricsPanel(context),

                        if (widget.controller.errorMessage != null)
                          _buildErrorState(context)
                        // 🆕 Modo de revisão: Formulário após desenhar
                        else if (widget.controller.currentState ==
                            DrawingState.reviewing)
                          _buildReviewingMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.importing)
                          _buildImportingMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.importPreview)
                          _buildImportPreviewMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.unionSelection)
                          _buildUnionMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.differenceSelection)
                          _buildDifferenceMode(context) // Replaces cut
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.intersectionSelection)
                          _buildIntersectionMode(context)
                        else if (widget.controller.interactionMode ==
                            DrawingInteraction.editing)
                          _buildEditingMode(context)
                        else if (widget.controller.selectedFeature != null)
                          _buildSelectedMode(context)
                        else
                          _buildToolsGrid(context),
                      ],
                    );
                    return Padding(
                      padding: EdgeInsets.only(
                        bottom: _showsSelectedStickyFooter
                            ? 24
                            : kFabSafeArea + safeBottom + 40,
                      ),
                      child: content,
                    );
                  },
                ),
              ),
            ),
            ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                if (!_showsSelectedStickyFooter) {
                  return const SizedBox.shrink();
                }
                return _SelectedModeFooter(
                  safeBottom: safeBottom,
                  onExit: () => _requestClose(DrawingCloseIntent.dismissSheet),
                  onEdit: () {
                    HapticFeedback.lightImpact();
                    widget.controller.startEditMode();
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool get _showsSelectedStickyFooter =>
      widget.controller.selectedFeature != null &&
      !_isEditingMetadata &&
      widget.controller.interactionMode != DrawingInteraction.editing &&
      widget.controller.currentState == DrawingState.selected;

  Future<void> _submitReview() async {
    if (_isSaving) return;
    HapticFeedback.mediumImpact();
    final geometry = widget.controller.liveGeometry;
    if (geometry == null) return;

    setState(() => _isSaving = true);
    final DrawingFeature? savedFeature;
    try {
      savedFeature = await widget.controller.addFeature(
        geometry: geometry,
        nome: _nomeController.text.trim(),
        tipo: DrawingType.talhao,
        origem:
            widget.controller.pendingImportOrigin ??
            DrawingOrigin.desenho_manual,
        autorId: 'current_user',
        autorTipo: _isConsultant ? AuthorType.consultor : AuthorType.cliente,
        subtipo: widget.controller.pendingDrawingSubtipo,
        raioMetros: widget.controller.pendingDrawingRaioMetros,
        clienteId: _selectedClient?.id ?? 'SELF',
        fazendaId: _selectedFarm?.id,
        grupo: _selectedFarm?.name,
        cor: _selectedColor.toARGB32(),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }

    if (!mounted) return;
    if (savedFeature == null) return;

    _resetReviewForm();
    await _requestClose(
      DrawingCloseIntent.completeSaveAndClose,
      preferSavedCallback: true,
    );
  }

}