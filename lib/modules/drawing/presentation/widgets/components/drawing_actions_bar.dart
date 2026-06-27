import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/drawing_models.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';

/// Widget responsável por exibir ações contextuais para features de desenho.
///
/// Ações disponíveis:
/// - Editar geometria
/// - Editar metadados
/// - União com outra área
/// - Diferença (subtrair área)
/// - Interseção
/// - Excluir
///
/// ⚠️ Este widget é STATELESS e delega ações ao controller.
class DrawingActionsBar extends StatelessWidget {
  final DrawingFeature selectedFeature;
  final VoidCallback? onEditGeometry;
  final VoidCallback? onEditMetadata;
  final VoidCallback? onUnion;
  final VoidCallback? onDifference;
  final VoidCallback? onIntersection;
  final VoidCallback? onDelete;

  /// Exporta este talhão no formato escolhido.
  final VoidCallback? onExport;

  /// Exporta todos os talhões no formato escolhido.
  final VoidCallback? onExportAll;
  final VoidCallback? onToggleMultiSelect;
  final VoidCallback? onDuplicateSelected;
  final VoidCallback? onMoveSelected;
  final VoidCallback? onSelectByGroup;
  final VoidCallback? onDeleteSelected;
  final VoidCallback? onExitSelection;
  final bool isMultiSelectEnabled;
  final int selectedCount;

  const DrawingActionsBar({
    super.key,
    required this.selectedFeature,
    this.onEditGeometry,
    this.onEditMetadata,
    this.onUnion,
    this.onDifference,
    this.onIntersection,
    this.onDelete,
    this.onExport,
    this.onExportAll,
    this.onToggleMultiSelect,
    this.onDuplicateSelected,
    this.onMoveSelected,
    this.onSelectByGroup,
    this.onDeleteSelected,
    this.onExitSelection,
    this.isMultiSelectEnabled = false,
    this.selectedCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: SoloForteSheetTokens.sheetBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header com info da feature
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.landscape,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      selectedFeature.properties.nome,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${selectedFeature.properties.areaHa.toStringAsFixed(2)} ha',
                      style: const TextStyle(
                        fontSize: 14,
                        color: SoloForteSheetTokens.inputHint,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Ações de edição
          _ActionButton(
            icon: Icons.edit_location,
            label: 'Editar Geometria',
            description: 'Mover e ajustar vértices',
            onTap: () {
              HapticFeedback.lightImpact();
              onEditGeometry?.call();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.edit_note,
            label: 'Vincular / editar dados',
            description: 'Cliente, fazenda, nome e safra',
            onTap: () {
              HapticFeedback.lightImpact();
              onEditMetadata?.call();
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          _ActionButton(
            icon: Icons.check_circle_outline,
            label: 'Sair da seleção',
            description: 'Fecha o painel e remove o destaque do talhão',
            onTap: () {
              HapticFeedback.lightImpact();
              onExitSelection?.call();
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Operações booleanas
          const Text(
            'Operações',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SoloForteSheetTokens.inputHint,
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'União',
            description: 'Combinar com outra área',
            onTap: () {
              HapticFeedback.lightImpact();
              onUnion?.call();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Diferença',
            description: 'Subtrair outra área',
            onTap: () {
              HapticFeedback.lightImpact();
              onDifference?.call();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.crop_square,
            label: 'Interseção',
            description: 'Manter apenas sobreposição',
            onTap: () {
              HapticFeedback.lightImpact();
              onIntersection?.call();
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Exportar (multi-formato)
          const Text(
            'Exportar',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SoloForteSheetTokens.inputHint,
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.file_download_outlined,
            label: 'Exportar este talhão',
            description: 'GeoJSON, GPX, DXF, CSV, TXT ou PDF',
            onTap: () {
              HapticFeedback.lightImpact();
              onExport?.call();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.folder_zip_outlined,
            label: 'Exportar todos os talhões',
            description: 'Coleção completa no formato escolhido',
            onTap: () {
              HapticFeedback.lightImpact();
              if (onExportAll != null) {
                onExportAll!();
              }
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          const Text(
            'Lote',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: SoloForteSheetTokens.inputHint,
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: isMultiSelectEnabled
                ? Icons.checklist_rtl
                : Icons.playlist_add_check,
            label: isMultiSelectEnabled
                ? 'Sair da multi-seleção'
                : 'Ativar multi-seleção',
            description: isMultiSelectEnabled
                ? '$selectedCount item(ns) selecionado(s)'
                : 'Toque nos talhões no mapa para selecionar vários',
            onTap: () {
              HapticFeedback.lightImpact();
              onToggleMultiSelect?.call();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.copy_all_outlined,
            label: 'Duplicar selecionados',
            description: 'Cria cópia de todas as áreas selecionadas',
            onTap: () {
              HapticFeedback.lightImpact();
              onDuplicateSelected?.call();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.open_with,
            label: 'Mover selecionados',
            description: 'Desloca polígonos inteiros em lote',
            onTap: () {
              HapticFeedback.lightImpact();
              onMoveSelected?.call();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.label_outline,
            label: 'Selecionar por grupo',
            description: 'Seleciona todos os talhões do mesmo grupo',
            onTap: () {
              HapticFeedback.lightImpact();
              onSelectByGroup?.call();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.delete_sweep_outlined,
            label: 'Excluir selecionados',
            description: 'Remove todos os selecionados de uma vez',
            isDestructive: true,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showBulkDeleteConfirmation(context);
            },
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Ação destrutiva
          _ActionButton(
            icon: Icons.delete,
            label: 'Excluir',
            description: 'Remover permanentemente',
            isDestructive: true,
            onTap: () {
              HapticFeedback.mediumImpact();
              _showDeleteConfirmation(context);
            },
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir área?'),
        content: Text(
          'Tem certeza que deseja excluir "${selectedFeature.properties.nome}"? Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Fechar dialog
              if (onDelete != null) {
                onDelete!();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _showBulkDeleteConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir áreas selecionadas?'),
        content: Text(
          'Tem certeza que deseja excluir $selectedCount área(s)? '
          'Esta ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              onDeleteSelected?.call();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }
}

/// Botão individual de ação.
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isDestructive;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.description,
    this.isDestructive = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive
        ? Colors.red
        : SoloForteSheetTokens.sectionLabel;

    return Material(
      color: SoloForteSheetTokens.inputBackground,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: SoloForteSheetTokens.inputHint,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: SoloForteSheetTokens.divider,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
