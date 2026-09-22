import 'package:flutter/material.dart';

import '../state/map_state.dart';

/// Seletor compacto ha / m² / alqueire — mesma preferência global do mapa.
class AreaDisplayUnitChips extends StatelessWidget {
  const AreaDisplayUnitChips({
    super.key,
    required this.selected,
    required this.onSelected,
    this.dark = false,
  });

  final AreaDisplayUnit selected;
  final ValueChanged<AreaDisplayUnit> onSelected;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        children: [
          _Chip(
            label: 'ha',
            selected: selected == AreaDisplayUnit.hectare,
            onTap: () => onSelected(AreaDisplayUnit.hectare),
            dark: dark,
          ),
          const SizedBox(width: 6),
          _Chip(
            label: 'm²',
            selected: selected == AreaDisplayUnit.squareMeter,
            onTap: () => onSelected(AreaDisplayUnit.squareMeter),
            dark: dark,
          ),
          const SizedBox(width: 6),
          _Chip(
            label: 'alq GO/MG',
            selected: selected == AreaDisplayUnit.alqueire,
            onTap: () => onSelected(AreaDisplayUnit.alqueire),
            dark: dark,
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
    required this.dark,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    const brandGreen = Color(0xFF248A3D);
    final selectedColor = dark ? const Color(0xFF34C759) : brandGreen;
    final unselectedColor = dark ? Colors.white12 : Colors.grey.shade200;
    final textColor = dark ? Colors.white : Colors.black87;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? selectedColor : unselectedColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected && !dark ? Colors.white : textColor,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
