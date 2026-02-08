import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'drawing_controller.dart';
import 'drawing_models.dart';

class DrawingSheet extends StatefulWidget {
  final DrawingController controller;

  const DrawingSheet({super.key, required this.controller});

  @override
  State<DrawingSheet> createState() => _DrawingSheetState();
}

class _DrawingSheetState extends State<DrawingSheet> {
  // Local state for visual selection only, as per ticket RT-DRAW-02
  String? _selectedToolKey;
  OverlayEntry? _tooltipOverlay;

  @override
  void initState() {
    super.initState();
    // Rebuild overlay when controller notifies (state changes)
    widget.controller.addListener(_updateTooltip);
    // Initial show? No, wait for layout or first build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showTooltip();
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateTooltip);
    _removeTooltip();
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

    setState(() {
      _selectedToolKey = (_selectedToolKey == key) ? null : key;
    });
  }

  void _showTooltip() {
    if (_tooltipOverlay != null) return;

    final overlay = Overlay.of(context);
    _tooltipOverlay = OverlayEntry(
      builder: (context) => _TooltipWidget(controller: widget.controller),
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
    _tooltipOverlay?.remove();
    _tooltipOverlay = null;
  }

  Widget _buildSyncBadge(SyncStatus status) {
    IconData icon;
    Color color;
    String tooltip;

    switch (status) {
      case SyncStatus.synced:
        icon = Icons.cloud_done;
        color = Colors.green;
        tooltip = "Sincronizado";
        break;
      case SyncStatus.pending_sync:
        icon = Icons.cloud_upload;
        color = Colors.orange;
        tooltip = "Pendente de envio";
        break;
      case SyncStatus.conflict:
        icon = Icons.cloud_off;
        color = Colors.red;
        tooltip = "Conflito detectado";
        break;
      case SyncStatus.local_only:
        icon = Icons.save;
        color = Colors.grey;
        tooltip = "Salvo localmente";
        break;
    }

    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

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
          Flexible(
            child: ListenableBuilder(
              listenable: widget.controller,
              builder: (context, _) {
                final content = Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Always calculate and show metrics if available
                    _buildMetricsPanel(context),

                    if (widget.controller.errorMessage != null)
                      _buildErrorState(context)
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
    final tools = [
      _ToolData('polygon', Icons.hexagon_outlined, 'Polígono'),
      _ToolData('freehand', Icons.gesture, 'Livre'),
      _ToolData('pivot', Icons.radio_button_checked, 'Pivô'),
      _ToolData('import', Icons.upload_file, 'Importar (KML)'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final pendingCount = widget.controller.features
            .where((f) => f.properties.syncStatus != SyncStatus.synced)
            .length;

        final grid = isNarrow
            ? GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
                children: tools.map((tool) => _buildToolItem(tool)).toList(),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: tools.map((tool) => _buildToolItem(tool)).toList(),
              );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Column(
            children: [
              grid,
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
      },
    );
  }

  Widget _buildToolItem(_ToolData tool) {
    final isActive = _selectedToolKey == tool.key;

    return _DrawingToolItem(
      icon: tool.icon,
      label: tool.label,
      isActive: isActive,
      onTap: () => _onToolSelected(tool.key),
    );
  }

  // ... (Other build methods remain the same as previous step, just re-declaring for complete file if needed, but I will assume I can keep existing structure if I was patching. Since I am doing write_to_file, I must include all. )

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
    final isConsultant = feature.properties.autorTipo == AuthorType.consultor;
    final isEditable = feature.properties.status != DrawingStatus.arquivado;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.map, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Área: ${feature.properties.nome}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              _buildSyncBadge(feature.properties.syncStatus),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Status: ${feature.properties.status.name}',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          const Divider(height: 24),
          if (isEditable) ...[
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.edit, size: 20),
              title: const Text('Editar geometria'),
              onTap: widget.controller.startEditMode,
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.add_circle_outline,
                size: 20,
              ), // Or merge icon
              title: const Text('Unir com outra área'),
              onTap: widget.controller.startUnionMode,
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.remove_circle_outline, size: 20),
              title: const Text('Subtrair (Diferença)'),
              onTap: widget.controller.startDifferenceMode,
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.pie_chart_outline,
                size: 20,
              ), // intersect icon
              title: const Text('Interseção'),
              onTap: widget.controller.startIntersectionMode,
            ),
            if (isConsultant) ...[
              // Optional clean up or keep empty if no specific consultant actions
            ],
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.copy, size: 20),
              title: const Text('Duplicar área'),
              onTap: () {},
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.archive, color: Colors.red, size: 20),
              title: const Text(
                'Arquivar',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {},
            ),
          ],
        ],
      ),
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

class _DrawingToolItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawingToolItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final activeBg = primaryColor.withAlpha((255 * 0.1).round());
    final activeBorder = primaryColor;
    final activeIcon = primaryColor;
    final inactiveBg = Colors.grey[100];
    final inactiveBorder = Colors.transparent;
    final inactiveIcon = Colors.black87;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? activeBg : inactiveBg,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? activeBorder : inactiveBorder,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: isActive ? activeIcon : inactiveIcon,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              color: isActive ? activeIcon : Colors.black87,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

class _ToolData {
  final String key;
  final IconData icon;
  final String label;
  _ToolData(this.key, this.icon, this.label);
}

// =============================================================================
// TOOLTIP OVERLAY WIDGET (Dynamic)
// =============================================================================

class _TooltipWidget extends StatelessWidget {
  final DrawingController controller;

  const _TooltipWidget({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 16,
      left: 16,
      right: 16,
      child: Center(
        child: ListenableBuilder(
          listenable: controller,
          builder: (context, _) {
            final text = controller.instructionText;
            if (text.isEmpty) return const SizedBox.shrink();

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            );
          },
        ),
      ),
    );
  }
}
