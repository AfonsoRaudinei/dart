import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/carteira_segment_bar.dart';

void main() {
  testWidgets('CarteiraSegmentBar renders segments and dispatches selection', (
    tester,
  ) async {
    var selected = CarteiraSegment.clientes;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CarteiraSegmentBar(
            selected: selected,
            onSelected: (value) => selected = value,
          ),
        ),
      ),
    );

    expect(find.text('Clientes'), findsOneWidget);
    expect(find.text('Categorias'), findsOneWidget);
    expect(find.text('Metas'), findsOneWidget);
    expect(find.text('Oportunidades'), findsOneWidget);

    await tester.tap(find.text('Metas'));
    await tester.pumpAndSettle();

    expect(selected, CarteiraSegment.metas);
  });
}
