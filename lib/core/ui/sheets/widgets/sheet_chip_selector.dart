// lib/core/ui/sheets/widgets/sheet_chip_selector.dart

import 'package:flutter/material.dart';
import '../sheet_tokens.dart';
import '../soloforte_sheet.dart';

class SheetChipSelector<T> extends StatelessWidget {
  const SheetChipSelector({
    super.key,
    required this.options,
    required this.selected,
    required this.labelBuilder,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelBuilder;
  final void Function(T) onSelected;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final activeBorder = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : SoloForteSheetTokens.chipBorderActive;
    final inactiveBorder = isIos
        ? SoloForteSheetSkinIos.cardBorder
        : SoloForteSheetTokens.chipBorderInactive;
    final activeText = isIos
        ? SoloForteSheetSkinIos.iconStroke
        : SoloForteSheetTokens.chipTextActive;
    final inactiveText = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.chipTextInactive;
    final radius = isIos
        ? SoloForteSheetSkinIos.ctaRadius
        : SoloForteSheetTokens.chipRadius;

    return Row(
      children: options.map((option) {
        final isActive = option == selected;
        return Expanded(
          child: GestureDetector(
            onTap: () => onSelected(option),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isIos && isActive
                    ? SoloForteSheetSkinIos.badgeBackground
                    : null,
                borderRadius: BorderRadius.circular(radius),
                border: Border.all(
                  color: isActive ? activeBorder : inactiveBorder,
                  width: isActive ? SoloForteSheetTokens.chipBorderWidth : 1.0,
                ),
              ),
              child: Text(
                labelBuilder(option),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isActive ? activeText : inactiveText,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
