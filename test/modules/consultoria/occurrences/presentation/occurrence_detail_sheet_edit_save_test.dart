import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async => null;

  @override
  Future<List<ClientSummary>> listAtivos() async => const [];
}

class _EmptyVisitLookup implements IActiveVisitContextLookup {
  @override
  Future<ActiveVisitContext?> getActiveContext() async => null;
}

class _FakeOccurrenceRepository extends OccurrenceRepository {
  Occurrence? lastUpdated;

  @override
  Future<void> updateOccurrence(Occurrence occurrence) async {
    lastUpdated = occurrence;
  }

  @override
  Future<List<Occurrence>> getAllOccurrences() async => const [];

  @override
  Future<List<Occurrence>> getAllAuthorizedOccurrences({
    Set<String> authorizedClientIds = const {},
  }) async =>
      const [];
}

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets(
    'salvar edição após fechar o detalhe não usa WidgetRef disposto',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );
      final repository = _FakeOccurrenceRepository();
      final occurrence = Occurrence(
        id: 'occ-edit-save-ref',
        type: 'Média',
        description: 'Notas (Amostra de Solo)',
        category: 'amostra_solo',
        amostraSolo: true,
        lat: -10.69,
        long: -48.38,
        createdAt: DateTime.utc(2026, 9, 24, 13, 14),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
            occurrenceRepositoryProvider.overrideWithValue(repository),
            currentUserRoleProvider.overrideWithValue(UserRole.consultor),
            clientLookupProvider.overrideWithValue(_FakeClientLookup()),
            activeVisitContextLookupProvider.overrideWithValue(
              _EmptyVisitLookup(),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => OccurrenceDetailSheet.show(
                  context,
                  occurrence,
                ),
                child: const Text('abrir-detalhe'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir-detalhe'));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.text('Editar'),
        120,
        scrollable: find.byType(Scrollable),
      );
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();

      expect(find.text('Editar Ocorrência'), findsOneWidget);
      expect(find.text('Salvar Alterações'), findsOneWidget);

      await tester.tap(find.text('Salvar Alterações'));
      await tester.pumpAndSettle();

      expect(repository.lastUpdated, isNotNull);
      expect(repository.lastUpdated!.id, occurrence.id);
      expect(repository.lastUpdated!.category, 'amostra_solo');
      expect(
        find.byKey(const Key('occurrence_submit_error_banner')),
        findsNothing,
      );
      expect(
        find.textContaining('Cannot use "ref" after the widget was disposed'),
        findsNothing,
      );
      expect(find.byType(OccurrenceCreationSheet), findsNothing);
    },
  );
}
