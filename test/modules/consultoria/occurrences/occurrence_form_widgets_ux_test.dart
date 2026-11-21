import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_form_widgets.dart';

void main() {
  group('OccurrenceUrgencySlider', () {
    Future<void> pump(WidgetTester tester, String urgency) => tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OccurrenceUrgencySlider(urgency: urgency, onChanged: (_) {}),
        ),
      ),
    );

    testWidgets('cor da barra: verde, laranja e vermelha', (tester) async {
      for (final level in ['Baixa', 'Média', 'Alta']) {
        await pump(tester, level);
        final slider = tester.widget<Slider>(
          find.byKey(const Key('occurrence_urgency_slider')),
        );
        expect(
          SliderTheme.of(tester.element(find.byType(Slider))).thumbColor,
          OccurrenceUrgencySlider.colorFor(level),
        );
        expect(slider.value, ['Baixa', 'Média', 'Alta'].indexOf(level));
      }
      expect(OccurrenceUrgencySlider.colorFor('Alta'), const Color(0xFFFF3B30));
    });

    testWidgets('arrastar até o fim escolhe Alta', (tester) async {
      String? escolhido;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: OccurrenceUrgencySlider(
              urgency: 'Baixa',
              onChanged: (u) => escolhido = u,
            ),
          ),
        ),
      );
      await tester.drag(
        find.byKey(const Key('occurrence_urgency_slider')),
        const Offset(600, 0),
      );
      expect(escolhido, 'Alta');
    });
  });

  testWidgets('OccurrenceAccordion abre e fecha ao tocar no cabeçalho', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: OccurrenceAccordion(
            title: 'Ordem de aplicação',
            summary: 'Opcional',
            child: Text('conteudo'),
          ),
        ),
      ),
    );
    expect(find.text('conteudo'), findsNothing);
    expect(find.textContaining('Opcional', findRichText: true), findsOneWidget);

    await tester.tap(find.byKey(const Key('occurrence_accordion_header')));
    await tester.pumpAndSettle();
    expect(find.text('conteudo'), findsOneWidget);

    await tester.tap(find.byKey(const Key('occurrence_accordion_header')));
    await tester.pumpAndSettle();
    expect(find.text('conteudo'), findsNothing);
  });
}
