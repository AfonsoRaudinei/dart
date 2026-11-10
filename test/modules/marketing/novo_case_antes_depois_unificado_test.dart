import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/presentation/screens/novo_case_sheet.dart';

void main() {
  testWidgets('Antes/Depois unificado: adicionar e remover comparação extra', (
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
    await tester.pumpAndSettle();

    expect(find.text('Comparação 1'), findsOneWidget);
    expect(find.text('Adicionar comparação'), findsOneWidget);
    expect(find.text('Adicionar Avaliação'), findsNothing);

    await tester.ensureVisible(find.text('Adicionar comparação'));
    await tester.tap(find.text('Adicionar comparação'));
    await tester.pumpAndSettle();
    expect(find.text('Comparação 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Comparação 2'), findsNothing);
    expect(find.text('Comparação 1'), findsOneWidget);
  });

  testWidgets('CaseTipo.avaliacao abre fluxo Antes/Depois unificado', (
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
              onClose: () {},
              onPublicar: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Nome do Talhão (opcional)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Nome do Talhão (opcional)'), findsOneWidget);
    expect(find.text('Adicionar comparação'), findsOneWidget);
  });
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async => null;

  @override
  Future<List<ClientSummary>> listAtivos() async => const [];
}
