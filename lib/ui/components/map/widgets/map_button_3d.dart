import 'package:flutter/material.dart';

/// Visual "3D suave" dos botões flutuantes do mapa: leve degradê de luz no
/// topo, contorno claro e sombras em camadas (contato + projeção).
/// Discreto de propósito — dá relevo sem exagerar.
BoxDecoration map3dButtonDecoration({
  BorderRadius? borderRadius,
  bool circle = false,
  Color base = Colors.white,
}) {
  return BoxDecoration(
    shape: circle ? BoxShape.circle : BoxShape.rectangle,
    borderRadius: circle ? null : (borderRadius ?? BorderRadius.circular(12)),
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color.lerp(base, Colors.white, 0.6)!,
        Color.lerp(base, const Color(0xFFDDE1E7), 0.55)!,
      ],
    ),
    border: Border.all(color: Colors.white.withValues(alpha: 0.85), width: 0.8),
    boxShadow: [
      // contato: apoia o botão
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.18),
        blurRadius: 1.5,
        offset: const Offset(0, 1),
      ),
      // projeção próxima
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.16),
        blurRadius: 7,
        offset: const Offset(0, 3),
      ),
      // projeção ampla e suave
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.10),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
