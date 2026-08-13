import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_lancamento.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/tipo_fechamento_toggle.dart';

void main() {
  group('CarteiraLancamento.validarRegrasFechamento', () {
    test('permite negociação em aberto com qualquer percentual', () {
      expect(
        CarteiraLancamento.validarRegrasFechamento(
          closedPercent: 50,
          tipoFechamento: null,
        ),
        isNull,
      );
      expect(
        CarteiraLancamento.validarRegrasFechamento(
          closedPercent: 0,
          tipoFechamento: null,
        ),
        isNull,
      );
    });

    test('permite vendido com venda parcial ou zero', () {
      expect(
        CarteiraLancamento.validarRegrasFechamento(
          closedPercent: 25,
          tipoFechamento: TipoFechamento.vendido,
        ),
        isNull,
      );
      expect(
        CarteiraLancamento.validarRegrasFechamento(
          closedPercent: 0,
          tipoFechamento: TipoFechamento.vendido,
        ),
        isNull,
      );
    });

    test('exige 0% quando perdido para concorrência', () {
      expect(
        CarteiraLancamento.validarRegrasFechamento(
          closedPercent: 0,
          tipoFechamento: TipoFechamento.perdido,
        ),
        isNull,
      );
      expect(
        CarteiraLancamento.validarRegrasFechamento(
          closedPercent: 10,
          tipoFechamento: TipoFechamento.perdido,
        ),
        isNotNull,
      );
    });
  });

  group('CarteiraLancamento.sanitizarCamposConcorrente', () {
    test('remove dados de concorrente quando tipo não é perdido', () {
      final original = CarteiraLancamento(
        id: 'l1',
        userId: 'u1',
        safraId: 's1',
        categoriaId: 'c1',
        clienteId: 'cl1',
        quantidade: 0,
        tipoFechamento: TipoFechamento.vendido,
        nomeConcorrente: 'Concorrente X',
        motivoFechamento: 'Legado',
        dataFechamento: DateTime(2026, 3, 20),
        dataLancamento: DateTime(2026, 3, 21),
        createdAt: DateTime(2026, 3, 21),
      );

      final sanitizado = CarteiraLancamento.sanitizarCamposConcorrente(
        original,
      );

      expect(sanitizado.nomeConcorrente, isNull);
      expect(sanitizado.motivoFechamento, isNull);
      expect(sanitizado.dataFechamento, isNull);
    });

    test('mantém dados de concorrente quando perdido', () {
      final original = CarteiraLancamento(
        id: 'l2',
        userId: 'u1',
        safraId: 's1',
        categoriaId: 'c1',
        clienteId: 'cl1',
        quantidade: 0,
        closedPercent: 0,
        tipoFechamento: TipoFechamento.perdido,
        nomeConcorrente: 'Concorrente Y',
        motivoFechamento: 'Preço',
        dataLancamento: DateTime(2026, 3, 21),
        createdAt: DateTime(2026, 3, 21),
      );

      final sanitizado = CarteiraLancamento.sanitizarCamposConcorrente(
        original,
      );

      expect(sanitizado.nomeConcorrente, 'Concorrente Y');
      expect(sanitizado.motivoFechamento, 'Preço');
    });
  });

  testWidgets('TipoFechamentoToggle alterna seleção e permite limpar', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: _ToggleHarness()));

    expect(find.text('Negociação em aberto'), findsOneWidget);

    await tester.tap(find.text('Vendido'));
    await tester.pumpAndSettle();
    expect(find.text('Negociação em aberto'), findsNothing);

    await tester.tap(find.text('Perdido p/ conc.'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Perdido p/ conc.'));
    await tester.pumpAndSettle();
    expect(find.text('Negociação em aberto'), findsOneWidget);
  });
}

class _ToggleHarness extends StatefulWidget {
  const _ToggleHarness();

  @override
  State<_ToggleHarness> createState() => _ToggleHarnessState();
}

class _ToggleHarnessState extends State<_ToggleHarness> {
  TipoFechamento? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: TipoFechamentoToggle(
        value: _selected,
        onChanged: (value) => setState(() => _selected = value),
      ),
    );
  }
}
