import 'dart:convert';

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
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
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
  _FakeFieldLookup(this.fields);

  final List<FieldSummary> fields;

  @override
  Future<FieldSummary?> findById(String fieldId) async =>
      fields.where((f) => f.id == fieldId).firstOrNull;

  @override
  Future<List<FieldSummary>> listAll() async => fields;

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async =>
      fields.where((f) => f.farmId == farmId).toList();
}

class _FakeFarmLookup implements IFarmLookup {
  @override
  Future<FarmSummary?> findById(String farmId) async => farmId == 'farm-1'
      ? const FarmSummary(id: 'farm-1', clientId: 'c-1', name: 'Boa Vista')
      : null;

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

final _talhao = FieldSummary(
  id: 'field-3',
  name: 'Talhão 3',
  farmId: 'farm-1',
  geometry: jsonEncode({
    'type': 'Polygon',
    'coordinates': [
      [
        [-48.40, -10.80],
        [-48.30, -10.80],
        [-48.30, -10.70],
        [-48.40, -10.70],
        [-48.40, -10.80],
      ],
    ],
  }),
);

final _plantio = Occurrence(
  id: 'occ-plantio',
  type: 'Baixa',
  description: '',
  category: 'plantio',
  lat: -10.72,
  long: -48.38,
  createdAt: DateTime(2026, 11, 9),
  cultivar: 'Neo 790',
  dataPlantio: '2026-10-27',
  dataEmergencia: '2026-11-05',
  dataFimPlantio: '2026-10-30',
  cicloDias: 115,
);

Future<void> _pumpEditSheet(
  WidgetTester tester, {
  List<FieldSummary> fields = const [],
  OccurrenceConfirmCallback? onConfirm,
  Occurrence? occurrence,
}) async {
  tester.view.physicalSize = const Size(430, 3200);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(UserRole.consultor),
        clientLookupProvider.overrideWithValue(_FakeClientLookup()),
        activeVisitContextLookupProvider.overrideWithValue(_EmptyVisitLookup()),
        iFieldLookupProvider.overrideWithValue(_FakeFieldLookup(fields)),
        iFarmLookupProvider.overrideWithValue(_FakeFarmLookup()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OccurrenceCreationSheet(
            latitude: -10.72,
            longitude: -48.38,
            initialOccurrence: occurrence ?? _plantio,
            onConfirm: onConfirm ?? (_) async {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('edição de Plantio mostra emergência com rótulo e sem bloco '
      'Cultivar & Plantio separado', (tester) async {
    await _pumpEditSheet(tester);

    expect(find.text('Cultivar & Plantio'), findsNothing);

    final emergencia = find.byKey(
      const Key('occurrence_plantio_emergencia_field'),
    );
    expect(emergencia, findsOneWidget);
    expect(
      find.descendant(
        of: emergencia,
        matching: find.text('Data de emergência'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(of: emergencia, matching: find.text('05/11/2026')),
      findsOneWidget,
    );

    final inicio = find.byKey(const Key('occurrence_plantio_inicio_field'));
    expect(
      find.descendant(of: inicio, matching: find.text('Início do plantio')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: inicio, matching: find.text('27/10/2026')),
      findsOneWidget,
    );
    expect(find.text('Avaliação do plantio'), findsOneWidget);
  });

  testWidgets('linha local resolve talhão pelo pin e salva fieldId', (
    tester,
  ) async {
    OccurrenceFormData? submitted;
    await _pumpEditSheet(
      tester,
      fields: [_talhao],
      onConfirm: (data) async => submitted = data,
    );

    expect(find.text('Fazenda Boa Vista · Talhão 3'), findsOneWidget);

    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.fieldId, 'field-3');
    expect(submitted!.dataEmergencia, '2026-11-05');
  });

  testWidgets('limpar emergência na edição envia null', (tester) async {
    OccurrenceFormData? submitted;
    await _pumpEditSheet(tester, onConfirm: (data) async => submitted = data);

    expect(find.byKey(const Key('occurrence_location_line')), findsNothing);

    await tester.tap(find.byTooltip('Limpar Data de emergência'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.dataEmergencia, isNull);
    expect(submitted!.dataPlantio, '2026-10-27');
    expect(submitted!.fieldId, isNull);
  });

  testWidgets('edição hidrata término do plantio e ciclo salvos', (
    tester,
  ) async {
    await _pumpEditSheet(tester);

    final termino = find.byKey(const Key('occurrence_plantio_termino_field'));
    expect(termino, findsOneWidget);
    expect(
      find.descendant(of: termino, matching: find.text('Término do plantio')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: termino, matching: find.text('30/10/2026')),
      findsOneWidget,
    );

    final ciclo = find.widgetWithText(TextField, 'Ciclo (dias)');
    expect(ciclo, findsOneWidget);
    expect(tester.widget<TextField>(ciclo).controller!.text, '115');
  });

  testWidgets('salvar envia término do plantio e ciclo', (tester) async {
    OccurrenceFormData? submitted;
    await _pumpEditSheet(tester, onConfirm: (data) async => submitted = data);

    await tester.enterText(
      find.widgetWithText(TextField, 'Ciclo (dias)'),
      '120',
    );
    await tester.pump();
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.dataPlantio, '2026-10-27');
    expect(submitted!.dataFimPlantio, '2026-10-30');
    expect(submitted!.cicloDias, 120);
  });

  testWidgets('limpar término e ciclo na edição envia null', (tester) async {
    OccurrenceFormData? submitted;
    await _pumpEditSheet(tester, onConfirm: (data) async => submitted = data);

    await tester.tap(find.byTooltip('Limpar Término do plantio'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Ciclo (dias)'), '');
    await tester.pump();
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.dataFimPlantio, isNull);
    expect(submitted!.cicloDias, isNull);
  });

  testWidgets('término antes do início bloqueia o salvamento', (tester) async {
    OccurrenceFormData? submitted;
    await _pumpEditSheet(
      tester,
      occurrence: _plantio.copyWith(dataFimPlantio: '2026-10-20'),
      onConfirm: (data) async => submitted = data,
    );

    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();

    expect(submitted, isNull);
    expect(
      find.text('O término do plantio não pode ser antes do início.'),
      findsOneWidget,
    );
  });

  testWidgets('início depois do término limpa o término', (tester) async {
    await _pumpEditSheet(tester);

    await tester.tap(
      find.descendant(
        of: find.byKey(const Key('occurrence_plantio_inicio_field')),
        matching: find.text('27/10/2026'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('31'));
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final termino = find.byKey(const Key('occurrence_plantio_termino_field'));
    expect(
      find.descendant(of: termino, matching: find.text('30/10/2026')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const Key('occurrence_plantio_inicio_field')),
        matching: find.text('31/10/2026'),
      ),
      findsOneWidget,
    );
  });
}
