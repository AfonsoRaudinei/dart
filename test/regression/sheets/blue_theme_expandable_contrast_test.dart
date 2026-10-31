import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_fenologia_data.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_form_widgets.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/comparativo_chart.dart';

Widget _blueThemeApp(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: const [SoloForteThemeExtension(themeId: 'blue')],
    ),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('perfil azul — painéis expansíveis', () {
    testWidgets(
      'OccurrenceEstadioDropdown expandido usa card iOS e texto legível',
      (tester) async {
        final estadio = kEstadios[1];

        await tester.pumpWidget(
          _blueThemeApp(
            OccurrenceEstadioDropdown(
              selected: estadio,
              expanded: true,
              onChanged: (_) {},
              onToggleCard: () {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color ==
                    SoloForteSheetSkinIos.cardBackground,
          ),
          findsWidgets,
        );

        final descriptionFinder = find.text(estadio.description);
        expect(descriptionFinder, findsOneWidget);
        final descriptionText = tester.widget<Text>(descriptionFinder);
        expect(descriptionText.style?.color, isNot(Colors.white70));
        expect(
          descriptionText.style?.color,
          SoloForteSheetSkinIos.titleColor,
        );

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color ==
                    PremiumTokens.brandGreen.withValues(alpha: 0.07),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'ComparativoChart usa cardBackground no container raiz',
      (tester) async {
        await tester.pumpWidget(
          _blueThemeApp(
            ComparativoChart(
              parametros: const [
                ParametroComparativo(
                  id: 'p1',
                  titulo: 'Grãos',
                  testemunha: 10,
                  teste: 12,
                ),
              ],
              selecionadoId: null,
              onSelect: (_) {},
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color ==
                    SoloForteSheetSkinIos.cardBackground,
          ),
          findsWidgets,
        );

        expect(
          find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration as BoxDecoration).color ==
                    SoloForteSheetTokens.inputBackground,
          ),
          findsNothing,
        );
      },
    );
  });
}
