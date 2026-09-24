import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/ui/components/map/occurrence_pins.dart';

class _FakeClientLookup implements IClientLookup {
  _FakeClientLookup(this._clients);

  final List<ClientSummary> _clients;

  @override
  Future<ClientSummary?> findById(String id) async =>
      _clients.where((c) => c.id == id).firstOrNull;

  @override
  Future<List<ClientSummary>> listAtivos() async => _clients;
}

class _EmptyVisitLookup implements IActiveVisitContextLookup {
  @override
  Future<ActiveVisitContext?> getActiveContext() async => null;
}

Future<void> _tapAreaVisitadaCategory(WidgetTester tester) async {
  final target = find.text('Área\nVisitada');
  if (target.evaluate().isEmpty) {
    await tester.dragUntilVisible(
      target,
      find.byType(ListView).first,
      const Offset(0, -150),
    );
  } else {
    await tester.ensureVisible(target);
  }
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _tapSave(WidgetTester tester) async {
  final save = find.text('Salvar localização');
  if (save.evaluate().isEmpty) {
    await tester.dragUntilVisible(
      save,
      find.byType(ListView).first,
      const Offset(0, -150),
    );
  } else {
    await tester.ensureVisible(save);
  }
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  group('OccurrenceCategory.areaVisitada', () {
    test('fromString reconhece area_visitada e areaVisitada (enum name)', () {
      expect(
        OccurrenceCategory.fromString('area_visitada'),
        OccurrenceCategory.areaVisitada,
      );
      expect(
        OccurrenceCategory.fromString('areaVisitada'),
        OccurrenceCategory.areaVisitada,
      );
    });

    test('pendingClientLink quando sem clientId', () {
      final occurrence = Occurrence(
        id: 'occ-area-1',
        type: 'Média',
        description: '',
        category: kOccurrenceAreaVisitadaCategory,
        lat: -15.0,
        long: -47.0,
        createdAt: DateTime.utc(2026, 9, 16),
      );

      expect(occurrence.isAreaVisitada, isTrue);
      expect(occurrence.pendingClientLink, isTrue);
    });

    test('pendingClientLink false após vínculo de cliente', () {
      final occurrence = Occurrence(
        id: 'occ-area-2',
        type: 'Média',
        description: '',
        category: kOccurrenceAreaVisitadaCategory,
        clientId: 'client-1',
        lat: -15.0,
        long: -47.0,
        createdAt: DateTime.utc(2026, 9, 16),
      );

      expect(occurrence.pendingClientLink, isFalse);
    });
  });

  group('OccurrenceCreationSheet — Área Visitada', () {
    testWidgets('initialCategoryValue pré-seleciona Área Visitada', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.consultor),
            clientLookupProvider.overrideWithValue(_FakeClientLookup(const [])),
            activeVisitContextLookupProvider.overrideWithValue(
              _EmptyVisitLookup(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OccurrenceCreationSheet(
                latitude: -10.5,
                longitude: -48.2,
                initialCategoryValue: kOccurrenceAreaVisitadaCategory,
                onConfirm: (_) async {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Área Visitada'), findsWidgets);
      expect(find.text('Salvar localização'), findsOneWidget);
      expect(find.text('Categorias da Ocorrência'), findsNothing);
      expect(find.text('Cultivar & Plantio'), findsNothing);
    });

    testWidgets('salva sem cliente e sem descrição quando categoria selecionada', (
      tester,
    ) async {
      OccurrenceFormData? captured;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserRoleProvider.overrideWithValue(UserRole.consultor),
            clientLookupProvider.overrideWithValue(_FakeClientLookup(const [])),
            activeVisitContextLookupProvider.overrideWithValue(
              _EmptyVisitLookup(),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OccurrenceCreationSheet(
                latitude: -10.5,
                longitude: -48.2,
                onConfirm: (data) async {
                  captured = data;
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await _tapAreaVisitadaCategory(tester);
      await _tapSave(tester);

      expect(captured, isNotNull);
      expect(captured!.category, kOccurrenceAreaVisitadaCategory);
      expect(captured!.clientId, isNull);
      expect(captured!.description, isEmpty);
      expect(captured!.hasValidMapPin, isTrue);
    });

    test('vínculo posterior remove pendingClientLink', () {
      final created = Occurrence(
        id: 'occ-edit',
        type: 'Média',
        description: '',
        category: kOccurrenceAreaVisitadaCategory,
        lat: -10.5,
        long: -48.2,
        createdAt: DateTime.utc(2026, 9, 16),
      );

      expect(created.pendingClientLink, isTrue);

      final linked = created.copyWith(clientId: 'c-99');

      expect(linked.pendingClientLink, isFalse);
      expect(linked.clientId, 'c-99');
    });
  });

  group('OccurrencePinGenerator', () {
    test('projeta área visitada pendente de vínculo', () {
      final result = OccurrencePinGenerator.projectOccurrences([
        Occurrence(
          id: 'pin-1',
          type: 'Média',
          description: '',
          category: kOccurrenceAreaVisitadaCategory,
          lat: -15.2,
          long: -47.3,
          createdAt: DateTime.utc(2026, 9, 16),
        ),
      ]);

      expect(result.markers, hasLength(1));
      expect(result.markers.first.occurrence.pendingClientLink, isTrue);
    });
  });
}
