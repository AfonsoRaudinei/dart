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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Ferramentas
        _ToolButton(
          icon: Icons.crop_square,
          label: 'Polígono',
          isSelected: selectedToolKey == 'polygon',
          onTap: () => onToolSelected('polygon'),
        ),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.gesture,
          label: 'Livre',
          isSelected: selectedToolKey == 'freehand',
          onTap: () => onToolSelected('freehand'),
        ),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.circle_outlined,
          label: 'Pivô',
          isSelected: selectedToolKey == 'pivot',
          onTap: () => onToolSelected('pivot'),
        ),
        const SizedBox(height: 8),
        _ToolButton(
          icon: Icons.upload_file,
          label: 'Importar (KML)',
          isSelected: false, // Import is an action, not a state
          onTap: () => onToolSelected('import'),
        ),
      ],
    );
  }
}

/// Botão individual de ferramenta simplificado.
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // 🎨 Design Minimalista (Solicitação do Usuário)
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.green.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(color: Colors.green.withOpacity(0.5))
                : Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.green[700] : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? Colors.green[800] : Colors.black87,
                ),
              ),
              const Spacer(),
              if (isSelected)
                const Icon(Icons.check, color: Colors.green, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
