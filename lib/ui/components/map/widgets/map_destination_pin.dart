// Pin de destino no mapa (foco por query / busca).
// Idioma visual SoloForte — evita Icons.place Material genérico.

import 'package:flutter/material.dart';
import 'package:soloforte_app/core/design/sf_icons.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

/// Marcador de foco espacial (Apple Maps–like: pin preenchido + halo).
class MapDestinationPin extends StatelessWidget {
  const MapDestinationPin({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final pinSize = size * 0.72;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.bottomCenter,
        clipBehavior: Clip.none,
        children: [
          // Halo suave sob o pin (aterrissagem)
          Positioned(
            bottom: 2,
            child: Container(
              width: size * 0.42,
              height: size * 0.14,
              decoration: BoxDecoration(
                color: PremiumTokens.brandGreen.withValues(alpha: 0.28),
                borderRadius: BorderRadius.circular(99),
                boxShadow: [
                  BoxShadow(
                    color: PremiumTokens.brandGreen.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            child: Icon(
              SFIcons.pinFill,
              size: pinSize,
              color: PremiumTokens.brandGreen,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
