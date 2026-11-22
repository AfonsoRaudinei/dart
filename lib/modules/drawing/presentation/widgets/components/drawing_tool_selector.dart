import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

/// Widget responsável por exibir e gerenciar a seleção de ferramentas de desenho.
///
/// Responsabilidade: seleção de ferramenta de desenho
/// (Polígono, Livre, Pivô, KML, GPS Caminhar, Área Visitada).
///
/// O campo de teste entra pelas abas Resultado e Avaliação (ADR-064),
/// não por esta grade.
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
    final v = SoloForteSheetVisuals.of(context);
    final tools = <Widget>[
      _ToolButton(
        icon: Icons.pentagon_outlined,
        label: 'Polígono',
        isSelected: selectedToolKey == 'polygon',
        onTap: () => onToolSelected('polygon'),
      ),
      _ToolButton(
        icon: Icons.gesture,
        label: 'Livre',
        isSelected: selectedToolKey == 'freehand',
        onTap: () => onToolSelected('freehand'),
      ),
      _ToolButton(
        icon: Icons.circle_outlined,
        label: 'Pivô',
        isSelected: selectedToolKey == 'pivot',
        onTap: () => onToolSelected('pivot'),
      ),
      _ToolButton(
        icon: Icons.upload_file,
        label: 'Importar (KML)',
        isSelected: false,
        onTap: () => onToolSelected('import'),
      ),
      _ToolButton(
        icon: Icons.directions_walk,
        label: 'GPS (caminhar)',
        isSelected: selectedToolKey == 'gps',
        onTap: () => onToolSelected('gps'),
      ),
      _ToolButton(
        icon: SFIcons.pinFill,
        label: 'Área Visitada',
        isSelected: false,
        onTap: () => onToolSelected('area_visitada'),
      ),
    ];

    // Verde, Azul e Black: card agrupado via [SoloForteSheetVisuals].
    return Container(
      decoration: BoxDecoration(
        color: v.cardBackground,
        borderRadius: BorderRadius.circular(v.cardRadius),
        border: Border.all(color: v.cardBorder),
        boxShadow: v.cardShadows,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < tools.length; i++) ...[
            tools[i],
            if (i < tools.length - 1)
              Divider(
                height: 1,
                thickness: 0.5,
                indent: 56,
                color: v.rowDivider,
              ),
          ],
        ],
      ),
    );
  }
}

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
    final v = SoloForteSheetVisuals.of(context);

    return Material(
      color: Colors.transparent,
      child: ListTile(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 2,
        ),
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: v.iconBackground,
            shape: BoxShape.circle,
            boxShadow: v.isDark
                ? null
                : [
                    BoxShadow(
                      color: v.iconStroke.withValues(alpha: 0.22),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          child: Icon(icon, color: v.iconStroke, size: 18),
        ),
        title: Text(
          label,
          style: TextStyle(
            color: v.titleColor,
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: v.arrowColor, size: 18),
      ),
    );
  }
}