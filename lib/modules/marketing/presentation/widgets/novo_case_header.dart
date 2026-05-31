import 'package:flutter/material.dart';
import '../../../../ui/theme/premium/design_tokens.dart';

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
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tipoLabel,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Lat: ${lat.toStringAsFixed(5)}, Lng: ${lng.toStringAsFixed(5)}',
                style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 12),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: onClose,
          color: PremiumTokens.textSecondaryLight,
        ),
      ],
    );
  }
}
