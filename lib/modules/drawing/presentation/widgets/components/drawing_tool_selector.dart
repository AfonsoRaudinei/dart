import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Widget responsável por exibir e gerenciar a seleção de ferramentas de desenho.
///
/// Responsabilidade: seleção de ferramenta de desenho
/// (Polígono, Livre, Pivô, KML, GPS Caminhar).
///
/// Ferramentas disponíveis:
/// - Polígono (desenho livre)
/// - Livre (freehand)
/// - Pivô (círculo de irrigação)
/// - Importar (KML/KMZ)
/// - GPS (caminhar)
///
/// ⚠️ Este widget é STATELESS e não gerencia estado próprio.
/// O estado visual de seleção é gerenciado pelo parent.
class DrawingToolSelector extends StatelessWidget {
  static const _sheetSurface = Color(0xFF2C2C2E);
  static const _sheetBorder = Color(0xFF3A3A3C);
  static const _accentGreen = Color(0xFF4CAF50);

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
          icon: Icons.pentagon_outlined,
          label: 'Polígono',
          isSelected: selectedToolKey == 'polygon',
          onTap: () => onToolSelected('polygon'),
          backgroundColor: _sheetSurface,
          borderColor: _sheetBorder,
          accentColor: _accentGreen,
        ),
        _ToolButton(
          icon: Icons.gesture,
          label: 'Livre',
          isSelected: selectedToolKey == 'freehand',
          onTap: () => onToolSelected('freehand'),
          backgroundColor: _sheetSurface,
          borderColor: _sheetBorder,
          accentColor: _accentGreen,
        ),
        _ToolButton(
          icon: Icons.circle_outlined,
          label: 'Pivô',
          isSelected: selectedToolKey == 'pivot',
          onTap: () => onToolSelected('pivot'),
          backgroundColor: _sheetSurface,
          borderColor: _sheetBorder,
          accentColor: _accentGreen,
        ),
        _ToolButton(
          icon: Icons.upload_file,
          label: 'Importar (KML)',
          isSelected: false, // Import is an action, not a state
          onTap: () => onToolSelected('import'),
          backgroundColor: _sheetSurface,
          borderColor: _sheetBorder,
          accentColor: _accentGreen,
        ),
        _ToolButton(
          icon: Icons.directions_walk,
          label: 'GPS (caminhar)',
          isSelected: selectedToolKey == 'gps',
          onTap: () => onToolSelected('gps'),
          backgroundColor: _sheetSurface,
          borderColor: _sheetBorder,
          accentColor: _accentGreen,
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
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? accentColor : borderColor,
          width: isSelected ? 1.0 : 0.5,
        ),
      ),
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Icon(icon, color: accentColor, size: 22),
        title: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 18),
      ),
    );
  }
}
