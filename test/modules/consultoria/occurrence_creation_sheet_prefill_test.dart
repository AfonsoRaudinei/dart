import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_client_selector.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

class FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async {
    return (await listAtivos()).where((client) => client.id == id).firstOrNull;
  }

  @override
  Future<List<ClientSummary>> listAtivos() async {
    return const [
      ClientSummary(id: 'client-1', name: 'José Augusto Miranda', active: true),
    ];
  }
}

class FakeActiveVisitContextLookup implements IActiveVisitContextLookup {
  @override
  Future<ActiveVisitContext?> getActiveContext() async {
    return const ActiveVisitContext(
      sessionId: 'visit-1',
      clientId: 'client-1',
      clientName: 'José Augusto Miranda',
    );
  }
}

void main() {
  testWidgets('pré-seleciona cliente e exibe ponto definido no mapa', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Evita SessionController/Supabase no bootstrap do role.
          currentUserRoleProvider.overrideWithValue(UserRole.consultor),
          clientLookupProvider.overrideWithValue(FakeClientLookup()),
          activeVisitContextLookupProvider.overrideWithValue(
            FakeActiveVisitContextLookup(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: OccurrenceCreationSheet(
              latitude: -10.12345,
              longitude: -48.54321,
              onConfirm: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selector = tester.widget<OccurrenceClientSelector>(
      find.byType(OccurrenceClientSelector),
    );
    expect(selector.selectedClient?.id, 'client-1');
    // UX pin-first: não exibe lat/long cru no header (regra designer).
    expect(find.text('Ponto definido no mapa'), findsOneWidget);
    expect(find.text('-10.12345, -48.54321'), findsNothing);
  });

  testWidgets('permite acionar salvar ocorrência após scroll', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.consultor),
          clientLookupProvider.overrideWithValue(FakeClientLookup()),
          activeVisitContextLookupProvider.overrideWithValue(
            FakeActiveVisitContextLookup(),
          ),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: OccurrenceCreationSheet(
              latitude: -10.12345,
              longitude: -48.54321,
              onConfirm: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Salvar Ocorrência'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Salvar Ocorrência'));
    await tester.pump();

    expect(
      find.byKey(const Key('occurrence_submit_error_banner')),
      findsOneWidget,
    );
    expect(
      find.text(
        'Selecione ao menos uma categoria ou adicione uma descrição.',
      ),
      findsOneWidget,
    );
  });
}
