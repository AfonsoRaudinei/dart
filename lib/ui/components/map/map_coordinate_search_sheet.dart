import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/sheets/sheet_tokens.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../core/ui/sheets/widgets/sheet_input_field.dart';

/// Abre sheet para ir a coordenada (decimal, DMS/DDM ou UTM).
Future<String?> showMapCoordinateSearchSheet(BuildContext context) {
  return showSoloForteSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    maxHeightFraction: 0.55,
    builder: (ctx) => const MapCoordinateSearchSheet(),
  );
}

class MapCoordinateSearchSheet extends StatefulWidget {
  const MapCoordinateSearchSheet({super.key});

  @override
  State<MapCoordinateSearchSheet> createState() =>
      _MapCoordinateSearchSheetState();
}

class _MapCoordinateSearchSheetState extends State<MapCoordinateSearchSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final bottom = MediaQuery.paddingOf(context).bottom;
    final titleColor = isIos
        ? SoloForteSheetSkinIos.titleColor
        : SoloForteSheetTokens.titleColor;
    final bodyColor = isIos
        ? SoloForteSheetSkinIos.subtitleColor
        : SoloForteSheetTokens.inputHint;
    final ctaBg = isIos
        ? SoloForteSheetSkinIos.ctaBackground
        : SoloForteSheetTokens.chipBorderActive;
    final ctaFg = isIos ? SoloForteSheetSkinIos.ctaText : Colors.white;
    final ghostBorder = isIos
        ? SoloForteSheetSkinIos.ghostBorder
        : SoloForteSheetTokens.divider;
    final ghostText = isIos
        ? SoloForteSheetSkinIos.ghostText
        : SoloForteSheetTokens.chipTextInactive;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ir para coordenada',
              style: TextStyle(
                color: titleColor,
                fontSize: SoloForteSheetTokens.titleFontSize,
                fontWeight: SoloForteSheetTokens.titleWeight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Decimal, DMS/DDM (com hemisfério) ou UTM.',
              style: TextStyle(color: bodyColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SheetInputField(
              controller: _controller,
              hintText: 'Ex: -10.1823,-48.3331 | 22K 788000 8872000',
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: ghostText,
                      side: BorderSide(color: ghostBorder),
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isIos
                              ? SoloForteSheetSkinIos.ghostRadius
                              : SoloForteSheetTokens.chipRadius,
                        ),
                      ),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ctaBg,
                      foregroundColor: ctaFg,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(
                          isIos
                              ? SoloForteSheetSkinIos.ctaRadius
                              : SoloForteSheetTokens.chipRadius,
                        ),
                      ),
                    ),
                    onPressed: _submit,
                    child: const Text('Ir'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
