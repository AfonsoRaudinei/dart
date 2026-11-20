import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/domain/enums/unidade_categoria.dart';

void main() {
  group('UnidadeCategoria', () {
    test('labelForCodigo retorna fallback para codigo desconhecido', () {
      expect(UnidadeCategoria.labelForCodigo('litros_ha'), 'litros_ha');
      expect(UnidadeCategoria.labelForCodigo('bigBag'), 'Big Bag');
    });

    test(
      'seeds cobrem os tipos padrão, incluindo sacas de 500 mil sementes',
      () {
        expect(UnidadeCategoria.seeds, hasLength(6));
        expect(
          UnidadeCategoria.seeds.map((s) => s.codigo),
          containsAll([
            'realPorHa',
            'toneladaPorHa',
            'bigBag',
            'sacas60k',
            'sacas500milSementes',
            'reaisTotal',
          ]),
        );
        expect(
          UnidadeCategoria.labelForCodigo('sacas500milSementes'),
          'Sacas 500 mil sementes',
        );
        expect(
          UnidadeCategoria.converteSacasHaForCodigo('sacas500milSementes'),
          isFalse,
        );
        expect(UnidadeCategoria.labelForCodigo('reaisTotal'), r'R$ total');
        expect(
          UnidadeCategoria.converteSacasHaForCodigo('reaisTotal'),
          isFalse,
        );
      },
    );

    test('seedEntities gera tipos sistema por usuário', () {
      final now = DateTime(2026, 3, 1);
      final tipos = UnidadeCategoria.seedEntities(userId: 'u1', now: now);

      expect(tipos, hasLength(6));
      expect(tipos.every((t) => t.sistema), isTrue);
      expect(tipos.first.userId, 'u1');
    });

    test('seedsFaltantes completa só o que a conta ainda não tem', () {
      final tipos = UnidadeCategoria.seedsFaltantes(
        userId: 'u1',
        now: DateTime(2026, 3, 1),
        codigosExistentes: {'realPorHa', 'toneladaPorHa', 'bigBag', 'sacas60k'},
      );

      expect(tipos.map((t) => t.codigo), ['sacas500milSementes', 'reaisTotal']);
      expect(tipos.first.id, 'seed-sacas500milSementes-u1');
      expect(tipos.every((t) => t.sistema), isTrue);
      expect(
        UnidadeCategoria.seedsFaltantes(
          userId: 'u1',
          now: DateTime(2026, 3, 1),
          codigosExistentes: UnidadeCategoria.seeds
              .map((s) => s.codigo)
              .toSet(),
        ),
        isEmpty,
      );
    });
  });
}
