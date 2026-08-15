// lib/core/ui/sheets/widgets/sheet_section_header.dart

import 'package:flutter/material.dart';
import '../sheet_tokens.dart';
import '../soloforte_sheet.dart';

class SheetSectionHeader extends StatelessWidget {
  const SheetSectionHeader({
    super.key,
    required this.icon,
    required this.label,
  });

  final Widget icon; // geralmente Text com emoji, ou Icon
  final String label;

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final labelColor =
        isIos ? SoloForteSheetSkinIos.titleColor : SoloForteSheetTokens.sectionLabel;
    final dividerColor =
        isIos ? SoloForteSheetSkinIos.rowDivider : SoloForteSheetTokens.divider;

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
                color: labelColor,
                fontSize: isIos ? 12 : SoloForteSheetTokens.sectionFontSize,
                fontWeight: isIos ? FontWeight.w700 : SoloForteSheetTokens.sectionWeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Divider(color: dividerColor, height: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}
