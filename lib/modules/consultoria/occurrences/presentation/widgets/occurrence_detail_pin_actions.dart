import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../../../core/design/sf_icons.dart';
import '../../../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../../../ui/components/map/widgets/location_export_bottom_sheet.dart';
import '../../domain/occurrence.dart';

/// Ações de mapa no detalhe de ocorrência (ver pin + exportar).
class OccurrenceDetailPinActions extends StatelessWidget {
  final Occurrence occurrence;
  final Color categoryColor;
  final bool isIos;
  final VoidCallback onViewOnMap;

  const OccurrenceDetailPinActions({
    super.key,
    required this.occurrence,
    required this.categoryColor,
    required this.isIos,
    required this.onViewOnMap,
  });

  Future<void> _exportLocation(BuildContext context) async {
    final coords = occurrence.getCoordinates();
    if (coords == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esta ocorrência não tem ponto no mapa.')),
      );
      return;
    }
    HapticFeedback.selectionClick();
    await LocationExportBottomSheet.show(
      context: context,
      latitude: coords['lat']!,
      longitude: coords['long']!,
      label: occurrence.isAreaVisitada
          ? 'Área Visitada'
          : OccurrenceCategory.fromString(occurrence.category).label,
    );
  }

  ButtonStyle? _ghostStyle() {
    if (!isIos) return null;
    return OutlinedButton.styleFrom(
      foregroundColor: SoloForteSheetSkinIos.ghostText,
      side: const BorderSide(color: SoloForteSheetSkinIos.ghostBorder),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SoloForteSheetSkinIos.ghostRadius),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onViewOnMap,
              style: _ghostStyle(),
              icon: Icon(
                SFIcons.pinFill,
                size: 18,
                color: isIos ? SoloForteSheetSkinIos.iconStroke : categoryColor,
              ),
              label: const Text('Ver ponto no mapa'),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: () => _exportLocation(context),
              style: _ghostStyle(),
              icon: Icon(
                Icons.ios_share_outlined,
                size: 18,
                color: isIos ? SoloForteSheetSkinIos.iconStroke : categoryColor,
              ),
              label: const Text('Exportar localização'),
            ),
          ),
        ),
      ],
    );
  }
}
