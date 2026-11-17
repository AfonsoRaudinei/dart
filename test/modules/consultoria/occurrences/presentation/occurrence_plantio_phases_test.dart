import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
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

class _FakeFieldLookup implements IFieldLookup {
  @override
  Future<FieldSummary?> findById(String fieldId) async => null;

  @override
  Future<List<FieldSummary>> listAll() async => const [];

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async => const [];
}

class _FakeFarmLookup implements IFarmLookup {
  @override
  Future<FarmSummary?> findById(String farmId) async => null;

  @override
  Future<List<FarmSummary>> getFarmsByClient(String clientId) async => const [];

  @override
  Future<void> saveFarm({
    required String clientId,
    required String farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {}
}

Future<void> _pumpNewPlantio(
  WidgetTester tester, {
  required OccurrenceConfirmCallback onConfirm,
}) async {
  tester.view.physicalSize = const Size(430, 3600);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(UserRole.consultor),
        clientLookupProvider.overrideWithValue(_FakeClientLookup()),
        activeVisitContextLookupProvider.overrideWithValue(_EmptyVisitLookup()),
        iFieldLookupProvider.overrideWithValue(_FakeFieldLookup()),
        iFarmLookupProvider.overrideWithValue(_FakeFarmLookup()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OccurrenceCreationSheet(
            latitude: -10.72,
            longitude: -48.38,
            initialCategoryValue: 'plantio',
            onConfirm: onConfirm,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('atalho Acompanhar emergência abre sanfona Emergência', (
    tester,
  ) async {
    await _pumpNewPlantio(tester, onConfirm: (_) async {});

    expect(find.text('Acompanhar emergência'), findsOneWidget);
    expect(find.text('Execução'), findsOneWidget);
    expect(find.text('Emergência'), findsOneWidget);

    await tester.tap(find.byKey(const Key('occurrence_plantio_emergencia_shortcut')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('occurrence_plantio_validacao_field')),
      findsOneWidget,
    );
  });

  testWidgets('só emergência salva sem início de plantio', (tester) async {
    OccurrenceFormData? submitted;
    await _pumpNewPlantio(
      tester,
      onConfirm: (data) async => submitted = data,
    );

    await tester.tap(find.byKey(const Key('occurrence_plantio_emergencia_shortcut')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('occurrence_plantio_validacao_field')));
    await tester.tap(
      find.descendant(
        of: find.ancestor(
          of: find.byKey(const Key('occurrence_plantio_validacao_field')),
          matching: find.byType(Card),
        ),
        matching: find.text('Boa'),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('Salvar'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(submitted, isNotNull);
    expect(submitted!.category, 'plantio');
    expect(submitted!.dataPlantio, isNull);
    expect(submitted!.dataValidacao, isNotNull);
    expect(submitted!.avaliacaoEmergencia, 'boa');
  });
}