// lib/core/ui/sheets/widgets/sheet_section_header.dart

import 'package:flutter/material.dart';
import '../sheet_tokens.dart';

class SheetSectionHeader extends StatelessWidget {
  const SheetSectionHeader({
    super.key,
    required this.icon,
    required this.label,
  });

  final Widget icon;    // geralmente Text com emoji, ou Icon
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: SoloForteSheetTokens.sectionLabel,
                fontSize: SoloForteSheetTokens.sectionFontSize,
                fontWeight: SoloForteSheetTokens.sectionWeight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(color: SoloForteSheetTokens.divider, height: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}
