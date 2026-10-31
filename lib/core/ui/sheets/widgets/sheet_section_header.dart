// lib/core/ui/sheets/widgets/sheet_section_header.dart

import 'package:flutter/material.dart';
import '../sheet_tokens.dart';
import '../solo_forte_sheet_visuals.dart';

class SheetSectionHeader extends StatelessWidget {
  const SheetSectionHeader({
    super.key,
    required this.icon,
    required this.label,
  });

  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: v.sectionLabelColor,
                fontSize: v.isDark
                    ? SoloForteSheetTokens.sectionFontSize
                    : (v.isIos ? 12 : SoloForteSheetSkinLight.sectionFontSize),
                fontWeight: v.isIos
                    ? FontWeight.w700
                    : SoloForteSheetSkinLight.sectionWeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: v.dividerColor, height: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}
