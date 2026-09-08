import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/screens/novo_case_sheet.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_client_selector.dart';

void main() {
  testWidgets('permite produtor preenchido sem selecionar cliente', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientLookupProvider.overrideWithValue(_FakeClientLookup()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NovoCaseSheet(
              lat: -10.0,
              lng: -48.0,
              tipo: CaseTipo.resultado,
              onClose: () {},
              onPublicar: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Produtor / Fazenda *'),
      'Produtor livre',
    );

    expect(
      tester
          .widget<TextFormField>(
            find.widgetWithText(TextFormField, 'Produtor / Fazenda *'),
          )
          .controller!
          .text,
      'Produtor livre',
    );
    expect(find.text('Selecionar cliente (opcional)'), findsOneWidget);
  });

  testWidgets('MarketingClientSelector exibe hint e lista clientes', (
    tester,
  ) async {
    ClientSummary? selected;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientLookupProvider.overrideWithValue(_FakeClientLookup()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: MarketingClientSelector(
              selectedClientId: null,
              onChanged: (client) => selected = client,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Selecionar cliente (opcional)'), findsOneWidget);

    await tester.tap(find.byType(DropdownButton<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fazenda Alfa').last);
    await tester.pumpAndSettle();

    expect(selected?.id, 'client-alfa');
    expect(selected?.name, 'Fazenda Alfa');
  });

  test('MarketingCase sem clientId permanece válido', () {
    final now = DateTime.utc(2026, 9, 8);
    final marketingCase = MarketingCase(
      id: 'case-no-client',
      tipo: CaseTipo.avaliacao,
      visibilidade: PlanoMarketing.prata,
      lat: -10,
      lng: -48,
      localizacaoTexto: 'Cidade - UF',
      produtorFazenda: 'Produtor manual',
      produtoUtilizado: 'Produto',
      criadoEm: now,
      atualizadoEm: now,
    );

    expect(marketingCase.clientId, isNull);
    expect(marketingCase.produtorFazenda, 'Produtor manual');
  });
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async {
    return (await listAtivos()).where((c) => c.id == id).firstOrNull;
  }

  @override
  Future<List<ClientSummary>> listAtivos() async => const [
    ClientSummary(id: 'client-alfa', name: 'Fazenda Alfa', active: true),
    ClientSummary(id: 'client-beta', name: 'Fazenda Beta', active: true),
  ];
}
