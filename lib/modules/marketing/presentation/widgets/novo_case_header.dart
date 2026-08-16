import 'package:flutter/material.dart';
import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../core/ui/sheets/soloforte_sheet.dart';

/// Header do NovoCaseSheet com título e coordenadas.
class NovoCaseHeader extends StatelessWidget {
  final double lat;
  final double lng;
  final String tipoLabel;
  final VoidCallback onClose;

  const NovoCaseHeader({
    super.key,
    required this.lat,
    required this.lng,
    required this.tipoLabel,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isIos = soloForteSheetIsIos(context);
    final titleColor =
        isIos ? SoloForteSheetSkinIos.titleColor : Colors.white;
    final subtitleColor =
        isIos ? SoloForteSheetSkinIos.subtitleColor : const Color(0xFF8E8E93);
    final iconColor =
        isIos ? SoloForteSheetSkinIos.iconStroke : Colors.white;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
          color: iconColor,
        ),
      ],
    );
  }
}
