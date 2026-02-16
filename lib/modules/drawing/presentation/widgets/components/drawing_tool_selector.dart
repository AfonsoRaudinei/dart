import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget responsável por exibir e gerenciar a seleção de ferramentas de desenho.
/// 
/// Ferramentas disponíveis:
/// - Polígono (desenho livre)
/// - Livre (freehand)
/// - Pivô (círculo de irrigação)
/// - Importar (KML/KMZ)
/// 
/// ⚠️ Este widget é STATELESS e não gerencia estado próprio.
/// O estado visual de seleção é gerenciado pelo parent.
class DrawingToolSelector extends StatelessWidget {
  final String? selectedToolKey;
  final ValueChanged<String> onToolSelected;

  const DrawingToolSelector({
    super.key,
    this.selectedToolKey,
    required this.onToolSelected,
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
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Desenhar Área',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 16),

          // Ferramentas
          _ToolButton(
            icon: Icons.crop_square,
            label: 'Polígono',
            description: 'Desenhe tocando nos vértices',
            isSelected: selectedToolKey == 'polygon',
            onTap: () => onToolSelected('polygon'),
          ),
          const SizedBox(height: 12),
          _ToolButton(
            icon: Icons.gesture,
            label: 'Livre',
            description: 'Desenhe arrastando o dedo',
            isSelected: selectedToolKey == 'freehand',
            onTap: () => onToolSelected('freehand'),
          ),
          const SizedBox(height: 12),
          _ToolButton(
            icon: Icons.circle_outlined,
            label: 'Pivô',
            description: 'Círculo de irrigação',
            isSelected: selectedToolKey == 'pivot',
            onTap: () => onToolSelected('pivot'),
          ),
          const SizedBox(height: 12),
          _ToolButton(
            icon: Icons.upload_file,
            label: 'Importar (KML)',
            description: 'Importar de arquivo',
            isSelected: false,
            onTap: () => onToolSelected('import'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Botão individual de ferramenta.
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.grey.withValues(alpha: 0.05),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.green
                      : Colors.grey.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : Colors.black87,
                  size: 24,
                ),
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
                        color: isSelected ? Colors.green : Colors.black87,
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
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
