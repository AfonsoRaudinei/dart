import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/drawing_models.dart';

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

  const DrawingActionsBar({
    super.key,
    required this.selectedFeature,
    this.onEditGeometry,
    this.onEditMetadata,
    this.onUnion,
    this.onDifference,
    this.onIntersection,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.6),
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
              if (onEditGeometry != null) {
                onEditGeometry!();
              }
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.edit_note,
            label: 'Editar Informações',
            description: 'Nome, tipo, cliente, etc',
            onTap: () {
              HapticFeedback.lightImpact();
              if (onEditMetadata != null) {
                onEditMetadata!();
              }
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
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.add_circle_outline,
            label: 'União',
            description: 'Combinar com outra área',
            onTap: () {
              HapticFeedback.lightImpact();
              if (onUnion != null) {
                onUnion!();
              }
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.remove_circle_outline,
            label: 'Diferença',
            description: 'Subtrair outra área',
            onTap: () {
              HapticFeedback.lightImpact();
              if (onDifference != null) {
                onDifference!();
              }
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.crop_square,
            label: 'Interseção',
            description: 'Manter apenas sobreposição',
            onTap: () {
              HapticFeedback.lightImpact();
              if (onIntersection != null) {
                onIntersection!();
              }
              Navigator.of(context).pop();
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
              Navigator.of(context).pop(); // Fechar bottom sheet
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
    final color = isDestructive ? Colors.red : Colors.black87;

    return Material(
      color: Colors.grey.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 24,
              ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
