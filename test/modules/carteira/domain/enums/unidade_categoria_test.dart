import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/domain/enums/unidade_categoria.dart';

void main() {
  group('UnidadeCategoria', () {
    test('fromDb usa realPorHa como fallback', () {
      expect(
        UnidadeCategoria.fromDb(null),
        UnidadeCategoria.realPorHa,
      );
      expect(
        UnidadeCategoria.fromDb('desconhecido'),
        UnidadeCategoria.realPorHa,
      );
    });

    test('dbValue e label cobrem todos os casos', () {
      for (final unidade in UnidadeCategoria.values) {
        expect(
          UnidadeCategoria.fromDb(unidade.dbValue),
          unidade,
        );
        expect(unidade.label, isNotEmpty);
      }
    });
  });
}
