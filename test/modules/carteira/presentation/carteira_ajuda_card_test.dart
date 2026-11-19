import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_ajuda_card.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';

Widget _wrap(Widget child) => MaterialApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

void main() {
  group('CarteiraAjudaTextos', () {
    test('toda aba tem resumo e ao menos um detalhe', () {
      for (final segment in CarteiraSegment.values) {
        expect(CarteiraAjudaTextos.resumo(segment), isNotEmpty);
        expect(CarteiraAjudaTextos.detalhes(segment), isNotEmpty);
      }
    });

    test('Oportunidades explica que o total em R\$ só soma R\$/ha', () {
      final texto = CarteiraAjudaTextos.detalhes(
        CarteiraSegment.oportunidades,
      ).join(' ');
      expect(texto, contains(r'R$/ha'));
      expect(texto, contains('Sacas'));
    });
  });

  group('CarteiraAjudaCard', () {
    testWidgets('mostra o resumo e expande os detalhes ao tocar', (
      tester,
    ) async {
      const segment = CarteiraSegment.metas;
      await tester.pumpWidget(_wrap(const CarteiraAjudaCard(segment: segment)));

      expect(find.text(CarteiraAjudaTextos.resumo(segment)), findsOneWidget);
      expect(find.text('Como funciona'), findsOneWidget);
      final primeiro = CarteiraAjudaTextos.detalhes(segment).first;
      expect(find.text(primeiro), findsNothing);

      await tester.tap(find.byType(CarteiraAjudaCard));
      await tester.pumpAndSettle();

      expect(find.text(primeiro), findsOneWidget);
      expect(find.text('Como funciona'), findsNothing);

      await tester.tap(find.byType(CarteiraAjudaCard));
      await tester.pumpAndSettle();
      expect(find.text(primeiro), findsNothing);
    });
  });

  testWidgets('CarteiraEstadoVazio mostra título e próximo passo', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(const CarteiraEstadoVazio(titulo: 'Vazio', mensagem: 'Faça isto')),
    );
    expect(find.text('Vazio'), findsOneWidget);
    expect(find.text('Faça isto'), findsOneWidget);
  });
}
