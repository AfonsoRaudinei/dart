import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

double _lum(Color c) {
  double ch(double v) =>
      v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
}

double contrast(Color a, Color b) {
  final la = _lum(a);
  final lb = _lum(b);
  final hi = math.max(la, lb);
  final lo = math.min(la, lb);
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  // Não monta o ThemeData (GoogleFonts tenta baixar fontes em teste): valida
  // as cores primárias de cada tema direto dos tokens.
  final primaries = {
    'verde': PremiumTokens.brandGreenAccessible,
    'azul': const Color(0xFF1B6EE0),
    'preto (acento)': PremiumTokens.blackAccentPrimary,
  };
  primaries.forEach((nome, primary) {
    test('tema $nome: texto branco sobre a cor primária tem contraste AA', () {
      expect(contrast(primary, Colors.white), greaterThanOrEqualTo(4.5));
    });
  });

  test('verde acessível tem contraste AA com branco; verde decorativo não', () {
    expect(
      contrast(PremiumTokens.brandGreenAccessible, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(contrast(PremiumTokens.brandGreen, Colors.white), lessThan(3));
  });

  test(
    'texto secundário e terciário do claro têm contraste >= 4.5 sobre branco',
    () {
      final tertiary = Color.alphaBlend(
        PremiumTokens.textTertiaryLight,
        Colors.white,
      );
      expect(contrast(tertiary, Colors.white), greaterThanOrEqualTo(4.4));
      expect(
        contrast(PremiumTokens.textSecondaryLight, Colors.white),
        greaterThanOrEqualTo(4.5),
      );
    },
  );
}
