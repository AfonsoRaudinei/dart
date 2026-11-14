import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/avaliacao_item.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';

void main() {
  group('AvaliacaoItem', () {
    test('vazia calcula media zero', () {
      const item = AvaliacaoItem(id: 'av-1', titulo: 'Avaliação 1');

      expect(item.mediaGanhoPercent, 0);
    });

    test('com 3 parametros calcula media correta', () {
      const item = AvaliacaoItem(
        id: 'av-1',
        titulo: 'Avaliação 1',
        parametros: [
          ParametroComparativo(
            id: 'p1',
            titulo: 'Número de Grãos',
            testemunha: 10,
            teste: 12,
          ),
          ParametroComparativo(
            id: 'p2',
            titulo: 'Vagens por Planta',
            testemunha: 38,
            teste: 47,
          ),
          ParametroComparativo(
            id: 'p3',
            titulo: 'Nota Visual',
            testemunha: 6,
            teste: 9,
          ),
        ],
      );

      expect(item.mediaGanhoPercent, closeTo(31.22, 0.01));
    });

    test('round-trip JSON simples preserva campos', () {
      const original = AvaliacaoItem(
        id: 'av-1',
        titulo: 'Avaliação 1',
        nomeLadoA: 'Testemunha',
        nomeLadoB: 'Produto A',
        cultura: 'Soja',
      );

      final restored = AvaliacaoItem.fromJson(original.toJson());

      expect(restored.id, original.id);
      expect(restored.titulo, original.titulo);
      expect(restored.nomeLadoA, original.nomeLadoA);
      expect(restored.nomeLadoB, original.nomeLadoB);
      expect(restored.cultura, original.cultura);
      expect(restored.parametros, isEmpty);
    });

    test('round-trip JSON completo preserva parametros aninhados', () {
      const original = AvaliacaoItem(
        id: 'av-1',
        titulo: 'Avaliação 1',
        nomeLadoA: 'Testemunha',
        nomeLadoB: 'Produto A',
        fotoLadoAPath: 'a.jpg',
        fotoLadoBPath: 'b.jpg',
        observacoes: 'Boa diferença visual.',
        parametros: [
          ParametroComparativo(
            id: 'p1',
            titulo: 'Número de Grãos',
            testemunha: 10,
            teste: 12,
            unidade: 'grãos/vagem',
          ),
        ],
      );

      final restored = AvaliacaoItem.fromJson(original.toJson());

      expect(restored.fotoLadoAPath, 'a.jpg');
      expect(restored.fotoLadoBPath, 'b.jpg');
      expect(restored.nomeLadoC, isNull);
      expect(restored.fotoLadoCPath, isNull);
      expect(restored.observacoes, original.observacoes);
      expect(restored.parametros, hasLength(1));
      expect(restored.parametros.first.deltaPercent, 20);
    });

    test('chave ausente usa fallback e chave vazia permanece vazia', () {
      final ausente = AvaliacaoItem.fromJson(const {
        'id': 'av-1',
        'titulo': 'Avaliação 1',
      });

      expect(ausente.nomeLadoA, 'Lado A');
      expect(ausente.nomeLadoB, 'Lado B');
      expect(ausente.nomeLadoC, isNull);
      expect(ausente.fotoLadoCPath, isNull);

      final vazio = AvaliacaoItem.fromJson(const {
        'id': 'av-2',
        'titulo': 'Avaliação 2',
        'nome_lado_a': '',
        'nome_lado_b': '',
        'nome_lado_c': '',
        'foto_lado_c_path': 'c.jpg',
      });

      expect(vazio.nomeLadoA, isEmpty);
      expect(vazio.nomeLadoB, isEmpty);
      expect(vazio.nomeLadoC, isEmpty);
      expect(vazio.fotoLadoCPath, 'c.jpg');
    });
  });
}
