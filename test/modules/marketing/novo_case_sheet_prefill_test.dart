import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/presentation/screens/novo_case_sheet.dart';

void main() {
  testWidgets('pré-preenche contexto da visita e mantém campo editável', (
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
              tipo: CaseTipo.avaliacao,
              initialVisitContext: const ActiveVisitContext(
                sessionId: 'visit-1',
                clientId: 'client-1',
                clientName: 'José Augusto Miranda',
                farmId: 'farm-1',
                farmName: 'Fazenda Boa Vista',
                fieldId: 'field-1',
                fieldName: 'Talhão Norte',
                fieldAreaHa: 42.5,
                city: 'Porto Nacional',
                state: 'TO',
              ),
              onClose: () {},
              onPublicar: (_) {},
            ),
          ),
        ),
      ),
    );

    final fields = tester.widgetList<TextFormField>(find.byType(TextFormField));
    final values = fields.map((field) => field.controller!.text).toList();

    expect(values, contains('José Augusto Miranda / Fazenda Boa Vista'));
    expect(values, contains('Porto Nacional - TO'));
    expect(values, contains('Talhão Norte'));
    expect(values, contains('42.5'));

    await tester.enterText(find.byType(TextFormField).first, 'Nome ajustado');
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Nome ajustado',
    );
  });

  testWidgets('Antes/Depois mantém valor digitado em Teste produto', (
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
              tipo: CaseTipo.antesDepois,
              onClose: () {},
              onPublicar: (_) {},
            ),
          ),
        ),
      ),
    );

    final addParametroButton = find.widgetWithText(
      OutlinedButton,
      'Adicionar Parâmetro',
    );
    await tester.ensureVisible(addParametroButton);
    await tester.tap(addParametroButton);
    await tester.pump();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(4), 'Número de Grãos');
    await tester.enterText(fields.at(5), '10');
    await tester.enterText(fields.at(6), '12');
    await tester.pump();

    expect(tester.widget<TextFormField>(fields.at(6)).controller!.text, '12');
  });
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async {
    return const ClientSummary(id: 'client-1', name: 'Cliente', active: true);
  }

  @override
  Future<List<ClientSummary>> listAtivos() async => const [
    ClientSummary(id: 'client-1', name: 'Cliente', active: true),
  ];
}
