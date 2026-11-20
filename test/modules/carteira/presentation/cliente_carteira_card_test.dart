import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/cliente_carteira_card.dart';

Widget _card({required double media, required int comLancamento}) {
  return MaterialApp(
    theme: ThemeData(
      colorScheme: const ColorScheme.light(secondary: Color(0xFF2E7D32)),
    ),
    home: Scaffold(
      body: ClienteCarteiraCard(
        clienteNome: 'Produtor',
        mediaPercentual: media,
        categoriasAtivas: 5,
        categoriasComLancamento: comLancamento,
        onTap: () {},
      ),
    ),
  );
}

void main() {
  group('ClienteCarteiraCard', () {
    testWidgets('sem lançamentos mostra 0% e a barra não herda a cor do tema', (
      tester,
    ) async {
      await tester.pumpWidget(_card(media: 0, comLancamento: 0));

      expect(find.textContaining('Fechado em média: 0%'), findsOneWidget);
      expect(find.textContaining('0 de 5 categorias'), findsOneWidget);

      final barra = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(barra.value, 0);
      expect(barra.backgroundColor, Colors.grey[200]);
    });

    testWidgets('mostra média em pt-BR e categorias com lançamento', (
      tester,
    ) async {
      await tester.pumpWidget(_card(media: 33.3, comLancamento: 2));

      expect(find.textContaining('33,3%'), findsOneWidget);
      expect(find.textContaining('2 de 5 categorias'), findsOneWidget);
    });
  });
}
