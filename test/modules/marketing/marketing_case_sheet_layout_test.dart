import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_result_hero.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_sheet.dart';

void main() {
  testWidgets('sheet público não aninha DraggableScrollableSheet e sem Editar', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 7, 27);
    final marketingCase = MarketingCase(
      id: 'c1',
      tipo: CaseTipo.resultado,
      visibilidade: PlanoMarketing.prata,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'Brejinho',
      produtorFazenda: 'São João',
      produtoUtilizado: 'Coach',
      fotoPrincipalUrl: 'https://example.com/r.jpg',
      criadoEm: now,
      atualizadoEm: now,
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: MarketingCaseSheet(
              marketingCase: marketingCase,
              isPublicSurface: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(DraggableScrollableSheet), findsNothing);
    expect(find.byType(MarketingCaseResultHero), findsOneWidget);
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Excluir'), findsNothing);
    expect(find.text('Sugerir edição'), findsNothing);
  });
}
