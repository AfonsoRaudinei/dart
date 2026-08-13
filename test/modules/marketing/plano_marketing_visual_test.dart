import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/theme/plano_marketing_visual.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_marker.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

void main() {
  test('cada tier tem uma cor unica vinda dos tokens', () {
    expect(PlanoMarketing.ouro.color, PremiumTokens.tierGold);
    expect(PlanoMarketing.prata.color, PremiumTokens.tierSilver);
    expect(PlanoMarketing.bronze.color, PremiumTokens.tierBronze);

    // Cores antigas do sheet e do seletor, que divergiam do pin.
    const antigas = [Color(0xFFFFB800), Color(0xFF9EA9B2), Color(0xFFA0522D)];
    for (final tier in PlanoMarketing.values) {
      expect(antigas, isNot(contains(tier.color)), reason: tier.name);
    }
  });

  testWidgets('a borda do pin usa a mesma cor de tier do sheet', (
    tester,
  ) async {
    for (final tier in PlanoMarketing.values) {
      final now = DateTime.utc(2026, 8, 7);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MarketingCaseMarker(
              marketingCase: MarketingCase(
                id: 'case-${tier.name}',
                tipo: CaseTipo.resultado,
                visibilidade: tier,
                lat: -10,
                lng: -48,
                localizacaoTexto: 'Sorriso/MT',
                produtorFazenda: 'Cliente',
                produtoUtilizado: 'Produto',
                criadoEm: now,
                atualizadoEm: now,
              ),
              onTap: () {},
            ),
          ),
        ),
      );

      final bordas = tester
          .widgetList<Container>(find.byType(Container))
          .map((container) => container.decoration)
          .whereType<BoxDecoration>()
          .map((decoration) => decoration.border)
          .whereType<Border>()
          .map((border) => border.top.color);

      expect(bordas, contains(tier.color), reason: tier.name);
    }
  });
}
