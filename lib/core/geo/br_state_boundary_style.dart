import 'package:flutter/material.dart';

/// Largura do traço das divisas UF em função do zoom do mapa.
///
/// Fórmula: `(1.2 + zoom * 0.35)` limitada ao intervalo **[2.0, 6.0]**.
double strokeWidthForZoom(double zoom) {
  return (1.2 + zoom * 0.35).clamp(2.0, 6.0);
}

/// Halo escuro por trás da linha clara (melhor contraste no satélite).
Color stateBoundaryHaloBorderColor() => const Color(0xB3000000);

/// Linha principal das divisas (branco quente ~90% opacidade).
Color stateBoundaryLineBorderColor() => const Color(0xE6FFF4D6);

/// Fill muito sutil nas UFs (opcional no layer).
Color stateBoundarySubtleFillColor() => const Color(0x0AFFFFFF);
