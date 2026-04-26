import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/drawing_controller.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/models/gps_walk_session.dart';
import '../../domain/drawing_state.dart';
import '../../domain/repositories/i_clients_repository.dart';
import '../providers/drawing_client_provider.dart';
import '../providers/gps_walk_providers.dart';
import '../../../../core/constants/layout_constants.dart';
import 'components/drawing_tool_selector.dart';
import 'components/drawing_actions_bar.dart';
import 'drawing_info_edit_sheet.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import 'gps_walk_controls_overlay.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';

// Responsabilidade: container/shell do sheet de desenho
// (layout, estado e ciclo de vida; não concentra os itens de ferramenta).
// Os itens de ferramenta ficam em:
// lib/modules/drawing/presentation/widgets/components/drawing_tool_selector.dart
class DrawingSheet extends ConsumerStatefulWidget {
  final DrawingController controller;

  const DrawingSheet({super.key, required this.controller});

  @override
  ConsumerState<DrawingSheet> createState() => _DrawingSheetState();
}

class _DrawingSheetState extends ConsumerState<DrawingSheet> {
  String? _selectedToolKey;

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
      _syncPreSelectedClient(ref.read(drawingClientProvider));
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

  /// Aplica pré-seleção de cliente proveniente de query param Map-First.
  /// Chamado via ref.listen e no postFrameCallback inicial.
  void _syncPreSelectedClient(DrawingClientState clientState) {
    final preId = clientState.preSelectedClientId;
    if (preId == null) return;
    if (_selectedClient?.id == preId) return; // já selecionado
    if (clientState.clients.isEmpty) return; // ainda carregando

    final match = clientState.clients.where((c) => c.id == preId).toList();
    if (match.isNotEmpty && mounted) {
      setState(() => _selectedClient = match.first);
    }
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
      _syncPreSelectedClient(next);
    });

    // ── GPS Walk: resetar seleção quando sessão é cancelada/finalizada ───────
    ref.listen<GpsWalkSession?>(gpsWalkProvider, (prev, next) {
      if (prev != null && next == null && _selectedToolKey == 'gps') {
        setState(() => _selectedToolKey = null);
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
            const _SheetHeader(),

            // Conteúdo Dinâmico
            ListenableBuilder(
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
                    bottom: kFabSafeArea + safeBottom + 40,
                  ),
                  child: content,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsPanel(BuildContext context) {
    // BUG 3: Ocultar durante revisão — as métricas já aparecem em _buildReviewingMode
    if (widget.controller.currentState == DrawingState.reviewing) {
      return const SizedBox.shrink();
    }

    final area = widget.controller.reviewAreaHa;
    final perimeter = widget.controller.reviewPerimeterKm;

    if (area <= 0 && perimeter <= 0) return const SizedBox.shrink();

    final f = NumberFormat("##0.##", "pt_BR");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens
            .sheetBackground, // ✅ iOS Premium: Superfícies elevadas (Cards) são brancas
        borderRadius: BorderRadius.circular(
          PremiumTokens.borderRadiusSm,
        ), // ✅ iOS Premium: Inset com 12px
        border: Border.all(
          color: SoloForteSheetTokens.inputBackground,
          width: PremiumTokens.hairlineThickness,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.square_foot, size: 16, color: Colors.blueGrey),
              SizedBox(width: 6),
              Text(
                'MÉTRICAS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(label: 'Área', value: '${f.format(area)} ha'),
              _MetricItem(
                label: 'Perímetro',
                value: '${f.format(perimeter)} km',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Colors.orange, size: 40),
          const SizedBox(height: 8),
          Text(
            widget.controller.errorMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(color: SoloForteSheetTokens.sectionLabel),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: widget.controller.clearError,
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsGrid(BuildContext context) {
    // 🆕 REFATORADO: Usar DrawingToolSelector component
    final pendingCount = widget.controller.pendingSyncCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        children: [
          DrawingToolSelector(
            selectedToolKey: _selectedToolKey,
            onToolSelected: _onToolSelected,
          ),
          if (pendingCount > 0) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => widget.controller.syncFeatures(),
              icon: const Icon(Icons.cloud_upload, color: Colors.white),
              label: Text('Enviar alterações ($pendingCount)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // 🆕 REFATORADO: Métodos de construção de modo

  Widget _buildImportingMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Importar Arquivo',
            style: TextStyle(color: SoloForteSheetTokens.sectionLabel, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione o arquivo KML ou KMZ para importar:',
            style: TextStyle(color: SoloForteSheetTokens.inputHint),
          ),
          const SizedBox(height: 24),
          _FormatButton(
            label: 'Importar Arquivo',
            sublabel: 'KML ou KMZ',
            icon: Icons.upload_file_rounded,
            onTap: () => widget.controller.pickImportFile(),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: widget.controller.cancelOperation,
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: PremiumTokens.brandGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnionMode(BuildContext context) {
    return _buildBooleanOpMode(
      context,
      "Unir Áreas",
      "Selecione a segunda área para unir.",
      widget.controller.confirmBooleanOp,
    );
  }

  Widget _buildDifferenceMode(BuildContext context) {
    return _buildBooleanOpMode(
      context,
      "Subtrair Área",
      "Selecione a área a ser subtraída da original.",
      widget.controller.confirmBooleanOp,
    );
  }

  Widget _buildIntersectionMode(BuildContext context) {
    return _buildBooleanOpMode(
      context,
      "Interseção",
      "O resultado será apenas a área comum.",
      widget.controller.confirmBooleanOp,
    );
  }

  Widget _buildBooleanOpMode(
    BuildContext context,
    String title,
    String instructions,
    VoidCallback onConfirm,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: const TextStyle(color: SoloForteSheetTokens.sectionLabel, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              instructions,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SoloForteSheetTokens.inputHint),
            ),
          ),
          if (widget.controller.errorMessage != null)
            Text(
              widget.controller.errorMessage!,
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.controller.cancelOperation,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: PremiumTokens.brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    onConfirm();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTokens.brandGreen,
                  ), // ✅ iOS Premium
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImportPreviewMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Visualizar Importação',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'A geometria foi carregada no mapa como visualização.\nConfirme para adicionar ao desenho.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SoloForteSheetTokens.sectionLabel),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.controller.cancelOperation,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: PremiumTokens.brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.mediumImpact();
                    final validation = widget.controller.validationResult;
                    if (!validation.isValid &&
                        (validation.message?.contains('sobreposição') ==
                            true)) {
                      final confirmar = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: const Text('Sobreposição detectada'),
                          content: const Text(
                            'A geometria importada sobrepõe uma área existente. '
                            'Deseja importar assim mesmo?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(
                                dialogContext,
                                rootNavigator: false,
                              ).pop(false),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.of(
                                dialogContext,
                                rootNavigator: false,
                              ).pop(true),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: PremiumTokens.brandGreen,
                              ),
                              child: const Text(
                                'Importar assim mesmo',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      );
                      if (confirmar == true && context.mounted) {
                        widget.controller.confirmImportForced();
                      }
                    } else {
                      widget.controller.confirmImport();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        PremiumTokens.brandGreen, // Keep import green
                  ),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedMode(BuildContext context) {
    final feature = widget.controller.selectedFeature!;

    // 🆕 REFATORADO: Usar DrawingActionsBar component
    return DrawingActionsBar(
      selectedFeature: feature,
      onEditGeometry: widget.controller.startEditMode,
      onEditMetadata: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => DrawingInfoEditSheet(
            feature: feature,
            controller: widget.controller,
          ),
        );
      },
      onUnion: widget.controller.startUnionMode,
      onDifference: widget.controller.startDifferenceMode,
      onIntersection: widget.controller.startIntersectionMode,
      onDelete: () async {
        // 1. Guardar referência para undo
        final deletedFeature = feature;

        // 2. Deletar imediatamente
        widget.controller.deleteFeature(feature.id);

        // 3. Fechar o sheet
        Navigator.of(context, rootNavigator: false).pop();

        // 4. Mostrar feedback com Undo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${deletedFeature.properties.nome}" removido'),
            action: SnackBarAction(
              label: 'DESFAZER',
              onPressed: () {
                widget.controller.restoreFeature(deletedFeature);
              },
            ),
            duration: const Duration(seconds: 5),
          ),
        );
      },
    );
  }

  Widget _buildEditingMode(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            '✏️ Editando geometria',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(),
          if (widget.controller.hasSelfIntersection ||
              widget.controller.intersectionWarningMessage != null) ...[
            _buildSelfIntersectionWarning(),
            const SizedBox(height: 12),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Arraste os pontos para modificar a área.',
              textAlign: TextAlign.center,
              style: TextStyle(color: SoloForteSheetTokens.inputHint),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.undo),
                onPressed: widget
                    .controller
                    .undoEdit, // Check if controller exposes this
                tooltip: 'Desfazer',
              ),
              // Redo? Not implemented yet
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextButton(
                  onPressed: widget.controller.cancelEdit,
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      color: PremiumTokens.brandGreen,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    widget.controller.saveEdit();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumTokens.brandGreen,
                  ),
                  child: const Text(
                    'Salvar Edição',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🆕 ESTADO LOCAL JÁ DEFINIDO NO INÍCIO DA CLASSE
  // init state logic merged above

  // ... (dispose and other methods remain)

  // 🆕 FORMULÁRIO DE METADADOS (Climate FieldView Style - Hierárquico)
  Widget _buildReviewingMode(BuildContext context) {
    final area = widget.controller.liveAreaHa;
    final perimeter = widget.controller.livePerimeterKm;
    final f = NumberFormat("##0.##", "pt_BR");

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Salvar Polígono',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (widget.controller.hasSelfIntersection ||
                widget.controller.intersectionWarningMessage != null) ...[
              _buildSelfIntersectionWarning(),
              const SizedBox(height: 12),
            ],

            // 📊 Métricas
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BigMetric(
                    icon: Icons.aspect_ratio,
                    value: '${f.format(area)} ha',
                    label: 'Área',
                  ),
                  Container(width: 1, height: 40, color: Colors.grey[300]),
                  _BigMetric(
                    icon: Icons.straighten,
                    value: '${f.format(perimeter)} km',
                    label: 'Perímetro',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 1. Selecionar Cliente
            const Text(
              '👤 Cliente',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<Client>(
              initialValue: _selectedClient,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              hint: const Text('Selecione o cliente...'),
              items: ref.watch(drawingClientProvider).clients.map((c) {
                return DropdownMenuItem(value: c, child: Text(c.name));
              }).toList(),
              onChanged: (client) {
                setState(() {
                  _selectedClient = client;
                  _selectedFarm = null; // Reset farm
                });
                if (client != null) {
                  ref.read(drawingClientProvider.notifier).loadFarms(client.id);
                }
              },
              validator: (v) => v == null ? 'Selecione um cliente' : null,
            ),
            const SizedBox(height: 16),

            // 2. Selecionar Fazenda
            const Text(
              '🚜 Fazenda / Grupo',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<dynamic>(
              // Dynamic to allow 'NEW_FARM' string or Farm object
              initialValue: _selectedFarm,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              hint: const Text('Selecione a fazenda...'),
              items: [
                ...ref
                    .watch(drawingClientProvider)
                    .farms
                    .map(
                      (f) => DropdownMenuItem(value: f, child: Text(f.name)),
                    ),
                const DropdownMenuItem(
                  value: 'NEW_FARM',
                  child: Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Nova Fazenda',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ],
                  ),
                ),
              ],
              onChanged: (getValue) {
                if (getValue == 'NEW_FARM') {
                  if (_selectedClient == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Selecione o Cliente primeiro'),
                      ),
                    );
                    return;
                  }
                  _showCreateFarmDialog();
                } else {
                  setState(() => _selectedFarm = getValue as Farm?);
                }
              },
              validator: (v) => v == null && _selectedFarm == null
                  ? 'Selecione uma fazenda'
                  : null,
            ),
            const SizedBox(height: 16),

            // 3. Nome do Talhão
            const Text(
              '🏷️ Nome do Talhão',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nomeController,
              decoration: InputDecoration(
                hintText: 'Ex: Talhão Norte',
                suffixText: '${f.format(area)} ha',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Informe o nome' : null,
            ),
            const SizedBox(height: 16),

            // 4. Cor e Ações
            Row(
              children: [
                // Seletor de cor simplificado
                _ColorOption(
                  color: _selectedColor,
                  selected: _selectedColor,
                  onTap: (_) {},
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _ColorOption(
                          color: PremiumTokens.brandGreen,
                          selected: _selectedColor,
                          onTap: (c) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = c);
                          },
                        ),
                        _ColorOption(
                          color: Colors.blue,
                          selected: _selectedColor,
                          onTap: (c) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = c);
                          },
                        ),
                        _ColorOption(
                          color: Colors.amber,
                          selected: _selectedColor,
                          onTap: (c) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = c);
                          },
                        ),
                        _ColorOption(
                          color: Colors.redAccent,
                          selected: _selectedColor,
                          onTap: (c) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedColor = c);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Actions Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      _resetReviewForm();
                      widget.controller.cancelOperation();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'CANCELAR',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      HapticFeedback.mediumImpact(); // ✅ iOS Premium: feedback tátil ao salvar
                      final geometry = widget.controller.liveGeometry;
                      if (geometry == null) return;

                      // 🚀 SALVAR com IDs
                      widget.controller.addFeature(
                        geometry: geometry,
                        nome: _nomeController.text.trim(),
                        tipo: DrawingType.talhao,
                        origem:
                            widget.controller.pendingImportOrigin ??
                            DrawingOrigin.desenho_manual,
                        autorId: 'current_user',
                        autorTipo: _isConsultant
                            ? AuthorType.consultor
                            : AuthorType.cliente, // FIXED
                        clienteId:
                            _selectedClient?.id ??
                            'SELF', // If producer, assumes self
                        fazendaId: _selectedFarm?.id,
                        // Opcional: passar grupo como Nome da Fazenda para compatibilidade visual
                        grupo: _selectedFarm?.name,
                        cor: _selectedColor.value,
                      );

                      _resetReviewForm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumTokens.brandGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text(
                      'SALVAR',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }

  Widget _buildSelfIntersectionWarning() {
    final message =
        widget.controller.intersectionWarningMessage ??
        'Linhas se cruzam. Salve e edite os vértices depois.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.orange, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateFarmDialog() {
    final nameController = TextEditingController();
    final cityController = TextEditingController(
      text: _selectedClient?.city ?? '',
    );
    final stateController = TextEditingController(
      text: _selectedClient?.state ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nova Fazenda'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nome da Fazenda'),
              autofocus: true,
            ),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: 'Município'),
            ),
            TextField(
              controller: stateController,
              decoration: const InputDecoration(labelText: 'UF'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context, rootNavigator: false).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;

              final clientId =
                  _selectedClient?.id ??
                  'SELF'; // TODO: Handle Producer ID properly
              await ref
                  .read(drawingClientProvider.notifier)
                  .createFarm(
                    nameController.text,
                    clientId,
                    cityController.text,
                    stateController.text,
                  );
              if (context.mounted) {
                Navigator.of(context, rootNavigator: false).pop();
              }

              // Auto-select the newly created farm (Assume it's the last one or find by name)
              // Simple approach: reload farms handled by controller, then user selects.
              // Or better: controller could return the ID.
            },
            child: const Text('Criar'),
          ),
        ],
      ),
    );
  }

  // Antigo helper de limpar form
  void _resetReviewForm() {
    _nomeController.text = "Talhão Novo";
    // _descricaoController.clear(); // Removed as per instruction
    setState(() {
      _selectedClient = null;
      _selectedFarm = null;
      _selectedColor = PremiumTokens.brandGreen;
    });
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.only(top: 12),
            child: SizedBox(
              width: 40,
              height: 4,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color(0xFF8E8E93),
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ferramentas de Desenho',
              style: TextStyle(color: SoloForteSheetTokens.titleColor, fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
      ],
    );
  }
}

class _MetricItem extends StatelessWidget {
  final String label;
  final String value;
  const _MetricItem({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _FormatButton extends StatelessWidget {
  final String label;
  final String? sublabel;
  final IconData icon;
  final VoidCallback onTap;
  const _FormatButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.sublabel,
  });
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            if (sublabel != null) ...[
              const SizedBox(height: 4),
              Text(
                sublabel!,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BigMetric extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _BigMetric({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: PremiumTokens.textSecondaryLight, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

class _ColorOption extends StatelessWidget {
  final Color color;
  final Color selected;
  final ValueChanged<Color> onTap;

  const _ColorOption({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = color.value == selected.value;
    return GestureDetector(
      onTap: () => onTap(color),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: isSelected
              ? Border.all(color: Colors.white, width: 3)
              : Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: isSelected
            ? Container(
                margin: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black12, width: 1),
                ),
              )
            : null,
      ),
    );
  }
}
