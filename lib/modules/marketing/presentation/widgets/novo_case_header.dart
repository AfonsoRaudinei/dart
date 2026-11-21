import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_close_button.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

/// Header do NovoCaseSheet com título e coordenadas.
class NovoCaseHeader extends StatelessWidget {
  final double lat;
  final double lng;
  final String tipoLabel;
  final VoidCallback onClose;
  final bool showTitle;
  final bool showClose;

  const NovoCaseHeader({
    super.key,
    required this.lat,
    required this.lng,
    required this.tipoLabel,
    required this.onClose,
    this.showTitle = true,
    this.showClose = true,
  });

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final titleColor = v.titleColor;
    final subtitleColor = v.subtitleColor;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showTitle)
                Text(
                  tipoLabel,
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              Text(
                'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
                style: TextStyle(color: subtitleColor, fontSize: 12),
              ),
            ],
          ),
        ),
        if (showClose) SheetCloseButton(onPressed: onClose),
      ],
    );
  }
}
