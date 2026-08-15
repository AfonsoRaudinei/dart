import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../../core/ui/sheets/soloforte_sheet.dart';

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
    final isIos = soloForteSheetIsIos(context);
    final tools = <Widget>[
      _ToolButton(
        icon: Icons.pentagon_outlined,
        label: 'Polígono',
        isSelected: selectedToolKey == 'polygon',
        onTap: () => onToolSelected('polygon'),
        isIos: isIos,
        backgroundColor: _sheetSurface,
        borderColor: _sheetBorder,
        accentColor: _accentGreen,
      ),
      _ToolButton(
        icon: Icons.gesture,
        label: 'Livre',
        isSelected: selectedToolKey == 'freehand',
        onTap: () => onToolSelected('freehand'),
        isIos: isIos,
        backgroundColor: _sheetSurface,
        borderColor: _sheetBorder,
        accentColor: _accentGreen,
      ),
      _ToolButton(
        icon: Icons.circle_outlined,
        label: 'Pivô',
        isSelected: selectedToolKey == 'pivot',
        onTap: () => onToolSelected('pivot'),
        isIos: isIos,
        backgroundColor: _sheetSurface,
        borderColor: _sheetBorder,
        accentColor: _accentGreen,
      ),
      _ToolButton(
        icon: Icons.upload_file,
        label: 'Importar (KML)',
        isSelected: false, // Import is an action, not a state
        onTap: () => onToolSelected('import'),
        isIos: isIos,
        backgroundColor: _sheetSurface,
        borderColor: _sheetBorder,
        accentColor: _accentGreen,
      ),
      _ToolButton(
        icon: Icons.directions_walk,
        label: 'GPS (caminhar)',
        isSelected: selectedToolKey == 'gps',
        onTap: () => onToolSelected('gps'),
        isIos: isIos,
        backgroundColor: _sheetSurface,
        borderColor: _sheetBorder,
        accentColor: _accentGreen,
      ),
    ];

    if (!isIos) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: tools,
      );
    }

    // iOS Azul: card agrupado (#EBF5FF) com dividers semânticos.
    return Container(
      decoration: BoxDecoration(
        color: SoloForteSheetSkinIos.cardBackground,
        borderRadius: BorderRadius.circular(SoloForteSheetSkinIos.cardRadius),
        border: Border.all(color: SoloForteSheetSkinIos.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tools.length; i++) ...[
            tools[i],
            if (i < tools.length - 1)
              const Divider(
                height: 1,
                thickness: 0.5,
                indent: 56,
                color: SoloForteSheetSkinIos.rowDivider,
              ),
          ],
        ],
      ),
    );
  }
}

/// Botão individual de ferramenta simplificado.
class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isIos;
  final Color backgroundColor;
  final Color borderColor;
  final Color accentColor;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.isIos,
    required this.backgroundColor,
    required this.borderColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isIos) {
      return Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: SoloForteSheetSkinIos.iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: SoloForteSheetSkinIos.iconStroke,
              size: 18,
            ),
          ),
          title: Text(
            label,
            style: TextStyle(
              color: SoloForteSheetSkinIos.titleColor,
              fontSize: 15,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: SoloForteSheetSkinIos.arrowColor,
            size: 18,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Material(
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? accentColor : borderColor,
            width: isSelected ? 1.0 : 0.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Icon(icon, color: accentColor, size: 22),
          title: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 15),
          ),
          trailing: const Icon(
            Icons.chevron_right,
            color: Colors.white24,
            size: 18,
          ),
        ),
      ),
    );
  }
}
