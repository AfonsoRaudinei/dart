import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/drawing_controller.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/drawing_state.dart';
import '../../../consultoria/clients/domain/client.dart';
import '../../../consultoria/clients/domain/agronomic_models.dart';
import 'components/drawing_tool_selector.dart';
import 'components/drawing_metadata_panel.dart';
import 'components/drawing_actions_bar.dart';
import 'components/drawing_hint_overlay.dart';

class DrawingSheet extends ConsumerStatefulWidget {
  final DrawingController controller;

  const DrawingSheet({super.key, required this.controller});

  @override
  ConsumerState<DrawingSheet> createState() => _DrawingSheetState();
}

class _DrawingSheetState extends ConsumerState<DrawingSheet> {
  // Local state for visual selection only, as per ticket RT-DRAW-02
  String? _selectedToolKey;
  OverlayEntry? _tooltipOverlay;

  // 🆕 Estado para formulário de metadados
  final _nomeController = TextEditingController();
  final _descricaoController = TextEditingController();
  Client? _selectedClient;
  Farm? _selectedFarm;

  @override
  void initState() {
    super.initState();
    // Rebuild overlay when controller notifies (state changes)
    widget.controller.addListener(_updateTooltip);
    // Initial show? No, wait for layout or first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showTooltip();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateTooltip);
    _removeTooltip();
    _nomeController.dispose();
    _descricaoController.dispose();
    super.dispose();
  }

  void _onToolSelected(String key) {
    if (key == 'import') {
      widget.controller.startImportMode();
      setState(() {
        _selectedToolKey = null; // No visual toggle for import, it changes mode
      });
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
      // 🔧 FIX-DRAW-FLOW-01: Fechar bottom sheet e ativar modo de desenho imediatamente
      _removeTooltip();
      if (mounted) {
        Navigator.of(context).pop();
      }
    } else {
      widget.controller.selectTool('none'); // Desativa ferramenta
    }
  }

  void _showTooltip() {
    if (_tooltipOverlay != null) return;

    final overlay = Overlay.of(context);
    // 🆕 REFATORADO: Usar DrawingHintOverlay component
    _tooltipOverlay = OverlayEntry(
      builder: (context) => DrawingHintOverlay(controller: widget.controller),
    );

    overlay.insert(_tooltipOverlay!);
  }

  void _updateTooltip() {
    // Determine if tooltip should be visible logic?
    // Always visible if drawing mode active?
    // Actually the widget builder will re-read controller state if it listens?
    // _TooltipWidget needs to listen to controller too or be rebuilt.
    // Since it's in Overlay, it's outside this tree scope partially.
    // It should receive the controller.
    _tooltipOverlay?.markNeedsBuild();
  }

  void _removeTooltip() {
    try {
      _tooltipOverlay?.remove();
    } catch (e) {
      debugPrint('Erro ao remover tooltip: $e');
    } finally {
      _tooltipOverlay = null;
    }
  }

  /*
  Widget _buildSyncBadge(SyncStatus status) {
  ...
  */

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
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
              return content;
            },
          ),

          // Safe Area bottom padding
          SizedBox(height: MediaQuery.of(context).padding.bottom + 12),
        ],
      ),
    );
  }

  Widget _buildMetricsPanel(BuildContext context) {
    final area = widget.controller.liveAreaHa;
    final perimeter = widget.controller.livePerimeterKm;
    final segments = widget.controller.liveSegmentsKm;

    if (area <= 0 && perimeter <= 0) return const SizedBox.shrink();

    final f = NumberFormat("##0.##", "pt_BR");

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.square_foot, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 6),
              const Text(
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
          if (segments.isNotEmpty && segments.length >= 3) ...[
            const SizedBox(height: 8),
            const Divider(height: 12),
            const Text(
              'Segmentos:',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              constraints: const BoxConstraints(maxHeight: 80),
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(segments.length, (index) {
                    final pStart = index + 1;
                    final pEnd = (index + 1) >= segments.length ? 1 : index + 2;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'P$pStart → P$pEnd:',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${f.format(segments[index])} km',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ],
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
            style: const TextStyle(color: Colors.black87),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'Selecione o formato do arquivo para importar:',
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _FormatButton(
                  label: 'KML',
                  icon: Icons.code,
                  onTap: () => widget.controller.pickImportFile(false),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _FormatButton(
                  label: 'KMZ',
                  icon: Icons.folder_zip,
                  onTap: () => widget.controller.pickImportFile(true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: widget.controller.cancelOperation,
            child: const Text('Cancelar'),
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
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              instructions,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
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
                child: OutlinedButton(
                  onPressed: widget.controller.cancelOperation,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onConfirm,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white),
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
              style: TextStyle(color: Colors.black87),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.controller.cancelOperation,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.controller.confirmImport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Keep import green
                  ),
                  child: const Text(
                    'Confirmar',
                    style: TextStyle(color: Colors.white),
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
        // TODO: Implementar diálogo de edição de metadados
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editar metadados (em breve)')),
        );
      },
      onUnion: widget.controller.startUnionMode,
      onDifference: widget.controller.startDifferenceMode,
      onIntersection: widget.controller.startIntersectionMode,
      onDelete: () async {
        // Confirmar e deletar
        widget.controller.deleteFeature(feature.id);
        Navigator.of(context).pop();
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
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Arraste os pontos para modificar a área.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
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
                child: OutlinedButton(
                  onPressed: widget.controller.cancelEdit,
                  child: const Text('Cancelar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: widget.controller.saveEdit,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  child: const Text(
                    'Salvar Edição',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🆕 FORMULÁRIO DE METADADOS COMPLETO (Inspirado FAMS/Climate)
  Widget _buildReviewingMode(BuildContext context) {
    // 🆕 REFATORADO: Usar DrawingMetadataPanel component
    return DrawingMetadataPanel(
      nomeController: _nomeController,
      descricaoController: _descricaoController,
      selectedClient: _selectedClient,
      selectedFarm: _selectedFarm,
      onClientChanged: (client) {
        setState(() {
          _selectedClient = client;
          _selectedFarm = null; // Reset farm quando muda cliente
        });
      },
      onFarmChanged: (farm) {
        setState(() {
          _selectedFarm = farm;
        });
      },
      onTypeChanged: (type) {
        // TODO: Adicionar tipo ao estado
      },
      onConfirm: () {
        final geometry = widget.controller.liveGeometry;
        if (geometry == null) return;

        widget.controller.addFeature(
          geometry: geometry,
          nome: _nomeController.text.trim(),
          tipo: DrawingType.talhao,
          origem: DrawingOrigin.desenho_manual,
          autorId: 'current_user', // TODO: pegar do session
          autorTipo: AuthorType.consultor,
          clienteId: _selectedClient?.id,
          fazendaId: _selectedFarm?.id,
        );

        _clearForm();
      },
      onCancel: () {
        _clearForm();
        widget.controller.cancelOperation();
      },
    );
  }

  // Helper: Limpar formulário
  void _clearForm() {
    _nomeController.clear();
    _descricaoController.clear();
    setState(() {
      _selectedClient = null;
      _selectedFarm = null;
    });
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ferramentas de Desenho',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.5,
                  color: Colors.black87,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54),
                onPressed: () => Navigator.of(context).pop(),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                iconSize: 24,
                tooltip: 'Fechar',
              ),
            ],
          ),
        ),
        const Divider(height: 1),
        const SizedBox(height: 12),
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
  final IconData icon;
  final VoidCallback onTap;
  const _FormatButton({
    required this.label,
    required this.icon,
    required this.onTap,
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
          ],
        ),
      ),
    );
  }
}
