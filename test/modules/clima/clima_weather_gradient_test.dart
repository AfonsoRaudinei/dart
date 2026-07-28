import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

void main() {
  group('climaWeatherGradient', () {
    test('céu limpo diurno usa azul', () {
      final gradient = climaWeatherGradient('01d');
      expect(gradient.colors.first, const Color(0xFF5AC8FA));
    });

    test('noite usa roxo', () {
      final gradient = climaWeatherGradient('01n');
      expect(gradient.colors.first, const Color(0xFF5856D6));
    });

    test('tempestade usa gradiente escuro', () {
      final gradient = climaWeatherGradient('11d');
      expect(gradient.colors.last, const Color(0xFF2C2C54));
    });
  });
}
