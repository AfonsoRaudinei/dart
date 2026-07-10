import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/domain/enums/unidade_categoria.dart';

void main() {
  group('UnidadeCategoria', () {
    test('labelForCodigo retorna fallback para codigo desconhecido', () {
      expect(
        UnidadeCategoria.labelForCodigo('litros_ha'),
        'litros_ha',
      );
      expect(UnidadeCategoria.labelForCodigo('bigBag'), 'Big Bag');
    });

    test('seeds cobrem os quatro tipos padrão', () {
      expect(UnidadeCategoria.seeds, hasLength(4));
      expect(
        UnidadeCategoria.seeds.map((s) => s.codigo),
        containsAll(['realPorHa', 'toneladaPorHa', 'bigBag', 'sacas60k']),
      );
    });

    test('seedEntities gera tipos sistema por usuário', () {
      final now = DateTime(2026, 3, 1);
      final tipos = UnidadeCategoria.seedEntities(userId: 'u1', now: now);

      expect(tipos, hasLength(4));
      expect(tipos.every((t) => t.sistema), isTrue);
      expect(tipos.first.userId, 'u1');
    });
  });
}
