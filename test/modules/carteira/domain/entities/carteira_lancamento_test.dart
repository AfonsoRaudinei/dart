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
  });
}
