import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:flutter/services.dart';

import '../../../core/ui/sheets/sheet_keyboard_inset.dart';
import '../../../core/ui/sheets/soloforte_sheet.dart';
import '../../../core/ui/sheets/widgets/sheet_input_field.dart';

/// Abre sheet para ir a coordenada (decimal, DMS/DDM, UTM ou link Google Maps).
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
        final v = SoloForteSheetVisuals.of(context);
    final isIos = v.isIos;
    final bottom = sheetFormKeyboardBottomPadding(
      safeBottom: MediaQuery.paddingOf(context).bottom,
      keyboard: MediaQuery.viewInsetsOf(context).bottom,
    );
    final titleColor = v.titleColor;
    final bodyColor = v.subtitleColor;
    final ctaBg = v.ctaBackground;
    final ctaFg = v.ctaText;
    final ghostBorder = v.ghostBorder;
    final ghostText = v.ghostText;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottom),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Ir para coordenada',
              style: TextStyle(
                color: titleColor,
                fontSize: v.titleFontSize,
                fontWeight: v.titleWeight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Decimal, DMS/DDM (com hemisfério), UTM ou link do Google Maps.',
              style: TextStyle(color: bodyColor, fontSize: 13),
            ),
            const SizedBox(height: 16),
            SheetInputField(
              controller: _controller,
              hintText:
                  'Ex: -10.1823,-48.3331 | https://maps.app.goo.gl/…',
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
                          v.ghostRadius,
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
                              ? v.ctaRadius
                              : v.chipRadius,
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
