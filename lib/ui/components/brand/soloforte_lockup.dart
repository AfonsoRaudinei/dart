import 'package:flutter/material.dart';

/// Marca SoloForte para telas de entrada: símbolo vetorial limpo (casa + folhas)
/// ao lado do nome em tipografia moderna.
///
/// Substitui o banner 3D com brilho e ruído (`E351DC81-…png`), que parecia
/// "de template". Só usa o símbolo plano `soloforte_logo.png`.
class SoloForteLockup extends StatelessWidget {
  /// Altura do símbolo; o texto escala junto.
  final double markHeight;

  /// Cor do nome (branco sobre foto/escuro; escuro sobre fundo claro).
  final Color textColor;

  /// Esconde o nome e mostra só o símbolo.
  final bool markOnly;

  /// Ladrilho branco atrás do símbolo — mantém o telhado (azul-petróleo)
  /// visível sobre foto/mapa escuros.
  final bool markBackdrop;

  const SoloForteLockup({
    super.key,
    this.markHeight = 40,
    this.textColor = Colors.white,
    this.markOnly = false,
    this.markBackdrop = false,
  });

  @override
  Widget build(BuildContext context) {
    final markImage = Image.asset(
      'assets/images/soloforte_logo.png',
      height: markHeight,
      fit: BoxFit.contain,
      semanticLabel: 'SoloForte',
      errorBuilder: (_, __, ___) =>
          Icon(Icons.eco_rounded, size: markHeight, color: textColor),
    );
    final mark = markBackdrop
        ? DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(markHeight * 0.3),
            ),
            child: Padding(
              padding: EdgeInsets.all(markHeight * 0.14),
              child: markImage,
            ),
          )
        : markImage;
    if (markOnly) return mark;

    final fontSize = markHeight * 0.72;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        mark,
        SizedBox(width: markHeight * 0.28),
        Text.rich(
          const TextSpan(
            children: [
              TextSpan(
                text: 'solo',
                style: TextStyle(fontWeight: FontWeight.w300),
              ),
              TextSpan(
                text: 'forte',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          style: TextStyle(
            fontSize: fontSize,
            height: 1.0,
            letterSpacing: -0.6,
            color: textColor,
          ),
        ),
      ],
    );
  }
}
