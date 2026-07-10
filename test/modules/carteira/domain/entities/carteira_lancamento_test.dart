import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_lancamento.dart';

void main() {
  group('CarteiraLancamento', () {
    test('toMap mantém vendido sem dados de concorrente', () {
      final lancamento = CarteiraLancamento(
        id: 'l1',
        userId: 'u1',
        safraId: 's1',
        categoriaId: 'c1',
        clienteId: 'cl1',
        quantidade: 10,
        tipoFechamento: TipoFechamento.vendido,
        nomeConcorrente: null,
        motivoFechamento: null,
        dataLancamento: DateTime(2026, 3, 21),
        createdAt: DateTime(2026, 3, 21, 10),
      );

      final map = lancamento.toMap();

      expect(map['tipo_fechamento'], 'vendido');
      expect(map['nome_concorrente'], isNull);
      expect(map['motivo_fechamento'], isNull);
      expect(map.containsKey('percentual_fechado'), isFalse);
    });

    test('toMap mantém perdido com concorrente e motivo', () {
      final lancamento = CarteiraLancamento(
        id: 'l2',
        userId: 'u1',
        safraId: 's1',
        categoriaId: 'c1',
        clienteId: 'cl1',
        quantidade: 7.5,
        tipoFechamento: TipoFechamento.perdido,
        nomeConcorrente: 'Concorrente X',
        motivoFechamento: 'Preco menor',
        dataLancamento: DateTime(2026, 3, 21),
        createdAt: DateTime(2026, 3, 21, 10),
      );

      final map = lancamento.toMap();

      expect(map['tipo_fechamento'], 'perdido');
      expect(map['nome_concorrente'], 'Concorrente X');
      expect(map['motivo_fechamento'], 'Preco menor');
    });

    test('fromMap aceita lançamento legado sem novos campos', () {
      final lancamento = CarteiraLancamento.fromMap({
        'id': 'l3',
        'user_id': 'u1',
        'safra_id': 's1',
        'categoria_id': 'c1',
        'cliente_id': 'cl1',
        'quantidade': 4.0,
        'observacao': null,
        'data_lancamento': DateTime(2026, 3, 21).toIso8601String(),
        'created_at': DateTime(2026, 3, 21, 10).toIso8601String(),
      });

      expect(lancamento.tipoFechamento, isNull);
      expect(lancamento.nomeConcorrente, isNull);
      expect(lancamento.motivoFechamento, isNull);
    });

    test('toMap/fromMap serializa dataFechamento quando preenchida', () {
      final original = CarteiraLancamento(
        id: 'l4',
        userId: 'u1',
        safraId: 's1',
        categoriaId: 'c1',
        clienteId: 'cl1',
        quantidade: 12.0,
        tipoFechamento: TipoFechamento.vendido,
        dataFechamento: DateTime(2026, 3, 20),
        dataLancamento: DateTime(2026, 3, 21),
        createdAt: DateTime(2026, 3, 21, 10),
      );

      final map = original.toMap();
      final restored = CarteiraLancamento.fromMap(map);

      expect(map['data_fechamento'], isNotNull);
      expect(restored.dataFechamento, isNotNull);
      expect(restored.dataFechamento!.year, 2026);
      expect(restored.dataFechamento!.month, 3);
      expect(restored.dataFechamento!.day, 20);
    });

    test('fromMap retorna dataFechamento null quando coluna é null', () {
      final lancamento = CarteiraLancamento.fromMap({
        'id': 'l5',
        'user_id': 'u1',
        'safra_id': 's1',
        'categoria_id': 'c1',
        'cliente_id': 'cl1',
        'quantidade': 4.0,
        'observacao': null,
        'tipo_fechamento': 'vendido',
        'nome_concorrente': null,
        'motivo_fechamento': null,
        'data_fechamento': null,
        'data_lancamento': DateTime(2026, 3, 21).toIso8601String(),
        'created_at': DateTime(2026, 3, 21, 10).toIso8601String(),
      });

      expect(lancamento.dataFechamento, isNull);
    });

    test('fromMap retorna dataFechamento null quando chave está ausente', () {
      final lancamento = CarteiraLancamento.fromMap({
        'id': 'l6',
        'user_id': 'u1',
        'safra_id': 's1',
        'categoria_id': 'c1',
        'cliente_id': 'cl1',
        'quantidade': 4.0,
        'observacao': null,
        'tipo_fechamento': 'perdido',
        'nome_concorrente': 'Concorrente Y',
        'motivo_fechamento': 'Condicao comercial',
        'data_lancamento': DateTime(2026, 3, 21).toIso8601String(),
        'created_at': DateTime(2026, 3, 21, 10).toIso8601String(),
      });

      expect(lancamento.dataFechamento, isNull);
    });

    test('percentualFechado clamp limita entre 0 e 100', () {
      final negativo = CarteiraLancamento(
        id: 'l7',
        userId: 'u1',
        safraId: 's1',
        categoriaId: 'c1',
        clienteId: 'cl1',
        quantidade: 1,
        closedPercent: -12.4,
        dataLancamento: DateTime(2026, 3, 21),
        createdAt: DateTime(2026, 3, 21, 10),
      );
      final acima = CarteiraLancamento(
        id: 'l8',
        userId: 'u1',
        safraId: 's1',
        categoriaId: 'c1',
        clienteId: 'cl1',
        quantidade: 1,
        closedPercent: 140.6,
        dataLancamento: DateTime(2026, 3, 21),
        createdAt: DateTime(2026, 3, 21, 10),
      );

      expect(negativo.percentualFechado, 0);
      expect(acima.percentualFechado, 100);
    });

    test('derivarQuantidade segue meta × percentual (CARTEIRA_CALCULOS Cálculo 3)', () {
      expect(
        CarteiraLancamento.derivarQuantidade(
          metaQuantidade: 90,
          closedPercent: 100,
        ),
        90.0,
      );
      expect(
        CarteiraLancamento.derivarQuantidade(
          metaQuantidade: 90,
          closedPercent: 50,
        ),
        45.0,
      );
      expect(
        CarteiraLancamento.derivarQuantidade(
          metaQuantidade: 90,
          closedPercent: 0,
        ),
        0.0,
      );
      expect(
        CarteiraLancamento.derivarQuantidade(
          metaQuantidade: 2678,
          closedPercent: 50,
        ),
        closeTo(1339, 0.001),
      );
    });

    test('derivarOportunidadeVolume retorna meta - realizado', () {
      expect(
        CarteiraLancamento.derivarOportunidadeVolume(
          metaQuantidade: 90,
          closedPercent: 50,
        ),
        45.0,
      );
      expect(
        CarteiraLancamento.derivarOportunidadeVolume(
          metaQuantidade: 90,
          closedPercent: 100,
        ),
        0.0,
      );
    });
  });
}
