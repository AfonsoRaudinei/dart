import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';

void main() {
  group('ParametroComparativo', () {
    test('calcula delta positivo', () {
      const parametro = ParametroComparativo(
        id: 'p1',
        titulo: 'Número de Grãos',
        testemunha: 10,
        teste: 12,
      );

      expect(parametro.deltaPercent, 20);
      expect(parametro.isPositivo, isTrue);
    });

    test('calcula delta negativo', () {
      const parametro = ParametroComparativo(
        id: 'p1',
        titulo: 'Número de Grãos',
        testemunha: 10,
        teste: 8,
      );

      expect(parametro.deltaPercent, -20);
      expect(parametro.isNegativo, isTrue);
    });

    test('testemunha zero aplica guard sem crash', () {
      const parametro = ParametroComparativo(
        id: 'p1',
        titulo: 'Número de Grãos',
        testemunha: 0,
        teste: 12,
      );

      expect(parametro.deltaPercent, 0);
    });

    test('round-trip JSON preserva valores', () {
      const original = ParametroComparativo(
        id: 'p1',
        titulo: 'Vagens por Planta',
        testemunha: 38,
        teste: 47,
        unidade: 'vagens/planta',
      );

      final restored = ParametroComparativo.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.titulo, original.titulo);
      expect(restored.testemunha, original.testemunha);
      expect(restored.teste, original.teste);
      expect(restored.unidade, original.unidade);
    });

    test('MarketingCase calcula media de parametros', () {
      final parametrosJson = jsonEncode([
        const ParametroComparativo(
          id: 'p1',
          titulo: 'Número de Grãos',
          testemunha: 10,
          teste: 12,
        ).toJson(),
        const ParametroComparativo(
          id: 'p2',
          titulo: 'Vagens por Planta',
          testemunha: 38,
          teste: 47,
        ).toJson(),
        const ParametroComparativo(
          id: 'p3',
          titulo: 'Nota Visual',
          testemunha: 6,
          teste: 9,
        ).toJson(),
      ]);

      final marketingCase = MarketingCase.fromJson({
        'id': 'case-1',
        'tipo': 'antes_depois',
        'visibilidade': 'ouro',
        'lat': -15.5,
        'lng': -47.2,
        'localizacao_texto': 'Fazenda Norte',
        'produtor_fazenda': 'Produtor A',
        'produto_utilizado': 'Produto X',
        'parametros_json': parametrosJson,
        'criado_em': DateTime.utc(2026, 7, 11).toIso8601String(),
        'atualizado_em': DateTime.utc(2026, 7, 11).toIso8601String(),
      });

      expect(marketingCase.parametros, hasLength(3));
      expect(marketingCase.mediaGanhoPercent, closeTo(31.22, 0.01));
    });
  });
}
