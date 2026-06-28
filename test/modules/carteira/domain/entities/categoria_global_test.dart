import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/enums/unidade_categoria.dart';

void main() {
  group('CategoriaGlobal', () {
    final baseDate = DateTime(2026, 3, 1, 12);

    CategoriaGlobal build({
      UnidadeCategoria unidade = UnidadeCategoria.realPorHa,
      double? valorReferencia = 1200,
    }) {
      return CategoriaGlobal(
        id: 'cat-1',
        userId: 'u1',
        nome: 'Herbicida',
        cor: '#00AA00',
        ativo: true,
        ordem: 1,
        createdAt: baseDate,
        updatedAt: baseDate,
        unidade: unidade,
        valorReferencia: valorReferencia,
      );
    }

    test('fromMap interpreta ativo como int e unidade via fromDb', () {
      final categoria = CategoriaGlobal.fromMap({
        'id': 'cat-1',
        'user_id': 'u1',
        'nome': 'Fungicida',
        'cor': '#FF0000',
        'ativo': 0,
        'ordem': 2,
        'created_at': baseDate.toIso8601String(),
        'updated_at': baseDate.toIso8601String(),
        'unidade': 'bigBag',
        'valor_referencia': 50.0,
        'valor_real': 900.0,
        'valor_dolar': 180.0,
        'sacas_por_ha': 3.5,
      });

      expect(categoria.ativo, isFalse);
      expect(categoria.unidade, UnidadeCategoria.bigBag);
      expect(categoria.valorReal, 900.0);
      expect(categoria.sacasPorHa, 3.5);
    });

    test('toMap persiste ativo como 0/1 e unidade dbValue', () {
      final map = build(unidade: UnidadeCategoria.sacas60k).toMap();

      expect(map['ativo'], 1);
      expect(map['unidade'], 'sacas60k');
      expect(map['valor_referencia'], 1200);
    });

    test('custoSacasHa só aplica em realPorHa com valores válidos', () {
      final categoria = build(
        unidade: UnidadeCategoria.realPorHa,
        valorReferencia: 1000,
      );

      expect(categoria.custoSacasHa(100), closeTo(10, 0.001));
      expect(categoria.custoSacasHa(0), isNull);
      expect(
        build(unidade: UnidadeCategoria.toneladaPorHa).custoSacasHa(100),
        isNull,
      );
      expect(build(valorReferencia: null).custoSacasHa(100), isNull);
    });
  });
}
