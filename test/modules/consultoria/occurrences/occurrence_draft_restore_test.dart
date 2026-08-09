import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/models/occurrence_form_draft.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/providers/occurrence_draft_provider.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
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

void main() {
  const lat = -10.12345;
  const lng = -48.54321;

  group('OccurrenceCreationSheet draft restore', () {
    testWidgets('restaura descrição do rascunho keyed por pin', (tester) async {
      final pinKey = OccurrenceFormDraft.pinKeyFor(lat, lng);
      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.consultor),
          clientLookupProvider.overrideWithValue(_FakeClientLookup()),
          activeVisitContextLookupProvider.overrideWithValue(_EmptyVisitLookup()),
        ],
      );
      addTearDown(container.dispose);

      container.read(occurrenceDraftProvider(pinKey).notifier).state =
          const OccurrenceFormDraft(
        description: 'Ferrugem detectada no talhão norte',
        selectedCategoryValue: 'doenca',
        urgency: 'Alta',
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: OccurrenceCreationSheet(
                latitude: lat,
                longitude: lng,
                onConfirm: _noopConfirm,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Ferrugem detectada no talhão norte'), findsOneWidget);
      expect(find.text('Alta'), findsWidgets);
    });

    testWidgets('persiste rascunho no dispose e restaura no remount', (
      tester,
    ) async {
      final pinKey = OccurrenceFormDraft.pinKeyFor(lat, lng);
      final container = ProviderContainer(
        overrides: [
          currentUserRoleProvider.overrideWithValue(UserRole.consultor),
          clientLookupProvider.overrideWithValue(_FakeClientLookup()),
          activeVisitContextLookupProvider.overrideWithValue(_EmptyVisitLookup()),
        ],
      );
      addTearDown(container.dispose);

      Widget buildSheet() {
        return UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: OccurrenceCreationSheet(
                latitude: lat,
                longitude: lng,
                onConfirm: _noopConfirm,
              ),
            ),
          ),
        );
      }

      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextField, 'Descreva a ocorrência…'),
        'Dados antes da câmera',
      );
      await tester.pump();

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpAndSettle();

      final saved = container.read(occurrenceDraftProvider(pinKey));
      expect(saved, isNotNull);
      expect(saved!.description, 'Dados antes da câmera');

      await tester.pumpWidget(buildSheet());
      await tester.pumpAndSettle();

      expect(find.text('Dados antes da câmera'), findsOneWidget);
    });
  });
}

void _noopConfirm(_) {}
