import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/case_selectors_widget.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: ThemeData(
      extensions: const [SoloForteThemeExtension(themeId: 'blue')],
    ),
    home: Scaffold(body: child),
  );
}

void main() {
  group('PlanoMarketingSelector', () {
    testWidgets('sem seleção quando selectedPlano é null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          PlanoMarketingSelector(
            selectedPlano: null,
            enabledMetals: const {},
            onChanged: (_) {},
          ),
        ),
      );

      expect(find.text('OURO'), findsOneWidget);
      expect(find.text('PRATA'), findsOneWidget);
      expect(find.text('BRONZE'), findsOneWidget);
    });

    testWidgets('toque só em metais habilitados', (tester) async {
      PlanoMarketing? picked;
      await tester.pumpWidget(
        _wrap(
          PlanoMarketingSelector(
            selectedPlano: PlanoMarketing.bronze,
            enabledMetals: const {PlanoMarketing.bronze},
            onChanged: (p) => picked = p,
          ),
        ),
      );

      await tester.tap(find.text('PRATA'));
      await tester.pump();
      expect(picked, isNull);

      await tester.tap(find.text('BRONZE'));
      await tester.pump();
      expect(picked, PlanoMarketing.bronze);
    });

    testWidgets('com todos habilitados troca seleção', (tester) async {
      PlanoMarketing? picked;
      await tester.pumpWidget(
        _wrap(
          PlanoMarketingSelector(
            selectedPlano: PlanoMarketing.bronze,
            enabledMetals: PlanoMarketing.values.toSet(),
            onChanged: (p) => picked = p,
          ),
        ),
      );

      await tester.tap(find.text('OURO'));
      await tester.pump();
      expect(picked, PlanoMarketing.ouro);
    });
  });
}