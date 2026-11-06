import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/domain/occurrence_recomendacao_ordem.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';

void main() {
  group('OccurrenceRecomendacaoOrdem', () {
    test('formata o espelho legado só com os campos preenchidos', () {
      final ordem = OccurrenceRecomendacaoOrdem.resolve(
        acao: '  Aplicar inseticida  ',
        dose: '0,5 L/ha',
        quando: ' ',
      );

      expect(ordem.acao, 'Aplicar inseticida');
      expect(ordem.dose, '0,5 L/ha');
      expect(ordem.quando, isNull);
      expect(
        ordem.legacyText,
        'O que fazer: Aplicar inseticida\nDose: 0,5 L/ha',
      );
    });

    test('legado vazio nos três campos aparece só como ação', () {
      final ordem = OccurrenceRecomendacaoOrdem.resolve(
        legacy: '  Monitorar em 7 dias  ',
      );

      expect(ordem.acao, 'Monitorar em 7 dias');
      expect(ordem.dose, isNull);
      expect(ordem.quando, isNull);
      expect(ordem.rows, hasLength(1));
    });

    test('campos estruturados vencem o texto legado', () {
      final ordem = OccurrenceRecomendacaoOrdem.resolve(
        acao: 'Fungicida',
        legacy: 'texto antigo inteiro',
      );

      expect(ordem.acao, 'Fungicida');
      expect(ordem.legacyText, 'O que fazer: Fungicida');
    });

    test('mirrorLegacy preserva o legado quando os três estão vazios', () {
      expect(
        OccurrenceRecomendacaoOrdem.mirrorLegacy(legacy: 'só o texto antigo'),
        'só o texto antigo',
      );
      expect(OccurrenceRecomendacaoOrdem.mirrorLegacy(), isNull);
    });
  });

  group('Occurrence persistência da ordem', () {
    final createdAt = DateTime.utc(2026, 11, 5);

    test('toMap grava colunas e o espelho quando há ordem', () {
      final occurrence = Occurrence(
        id: 'occ-1',
        type: 'Média',
        description: 'Lagarta',
        createdAt: createdAt,
        recomendacaoAcao: 'Aplicar',
        recomendacaoDose: '1 L/ha',
        recomendacaoQuando: 'V4',
      );

      final map = occurrence.toMap();
      expect(map['recomendacao_acao'], 'Aplicar');
      expect(map['recomendacao_dose'], '1 L/ha');
      expect(map['recomendacao_quando'], 'V4');
      expect(
        map['recomendacoes'],
        'O que fazer: Aplicar\nDose: 1 L/ha\nQuando: V4',
      );
    });

    test('fromMap não promove o legado para a coluna de ação', () {
      final occurrence = Occurrence.fromMap({
        'id': 'occ-legado',
        'type': 'Média',
        'description': 'Antiga',
        'created_at': createdAt.toIso8601String(),
        'recomendacoes': 'Aplicar no baixeiro',
      });

      expect(occurrence.recomendacaoAcao, isNull);
      expect(occurrence.recomendacoes, 'Aplicar no baixeiro');
      expect(
        OccurrenceRecomendacaoOrdem.resolve(
          acao: occurrence.recomendacaoAcao,
          dose: occurrence.recomendacaoDose,
          quando: occurrence.recomendacaoQuando,
          legacy: occurrence.recomendacoes,
        ).acao,
        'Aplicar no baixeiro',
      );
    });

    test(
      'applyRecomendacaoOrdem limpa o legado quando os três ficam vazios',
      () {
        final occurrence = Occurrence(
          id: 'occ-1',
          type: 'Média',
          description: 'Lagarta',
          createdAt: createdAt,
          recomendacoes: 'texto antigo',
          recomendacaoAcao: 'Aplicar',
        );

        final cleared = occurrence.applyRecomendacaoOrdem();
        expect(cleared.recomendacaoAcao, isNull);
        expect(cleared.recomendacaoDose, isNull);
        expect(cleared.recomendacaoQuando, isNull);
        expect(cleared.recomendacoes, isNull);
      },
    );
  });
}
