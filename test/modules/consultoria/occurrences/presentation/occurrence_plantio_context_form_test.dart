import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer_provider.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_plantio_context.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/models/occurrence_talhao_prefill.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/providers/occurrence_location_provider.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/providers/occurrence_plantio_context_provider.dart';
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
  Future<FieldSummary?> findById(String fieldId) async =>
      fieldId == _talhao.id ? _talhao : null;

  @override
  Future<List<FieldSummary>> listAll() async => [_talhao];

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async => [_talhao];
}

class _FakeFarmLookup implements IFarmLookup {
  @override
  Future<FarmSummary?> findById(String farmId) async =>
      const FarmSummary(id: 'farm-1', clientId: 'c-1', name: 'Boa Vista');

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

class _RecordingWriter implements IDrawingFieldWriter {
  final calls = <Map<String, String?>>[];

  @override
  Future<void> updateFieldMetadata({
    required String fieldId,
    String? cultura,
    String? material,
    String? safra,
    String? dataPlantio,
    String? dataEmergencia,
    String? cicloDias,
  }) async {
    calls.add({
      'fieldId': fieldId,
      'cultura': cultura,
      'material': material,
      'safra': safra,
      'dataPlantio': dataPlantio,
      'dataEmergencia': dataEmergencia,
      'cicloDias': cicloDias,
    });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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

const _prefill = OccurrenceTalhaoPrefill(
  fieldId: 'field-3',
  talhaoNome: 'Talhão 3',
  clientId: 'c-1',
  fazendaId: 'farm-1',
);

/// Safra corrente — a criação resolve o contexto pela data de hoje.
final _safraAtual = safraFromPlantio(DateTime.now())!;

Occurrence _plantio(
  String id, {
  required DateTime createdAt,
  String? safra,
  String cultivar = 'Neo 790',
  String? cultura = 'Soja',
  String dataPlantio = '2026-10-27',
  String? dataEmergencia = '2026-11-05',
}) {
  return Occurrence(
    id: id,
    type: 'Baixa',
    description: '',
    category: 'plantio',
    lat: -10.72,
    long: -48.38,
    createdAt: createdAt,
    fieldId: 'field-3',
    cultura: cultura,
    safra: safra,
    cultivar: cultivar,
    dataPlantio: dataPlantio,
    dataFimPlantio: '2026-10-30',
    dataEmergencia: dataEmergencia,
    cicloDias: 115,
    sementesPorMetro: 14.5,
    estandePlantas: 12,
    avaliacaoPlantio: 'boa',
    objetivoPlantio: 'Produção',
  );
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required List<Occurrence> plantios,
  required OccurrenceConfirmCallback onConfirm,
  Occurrence? initialOccurrence,
  String? initialCategory,
  OccurrenceTalhaoPrefill? prefill,
  IDrawingFieldWriter? writer,
  TalhaoPlantioSnapshot? talhao,
  bool locationUnresolved = false,
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
        iDrawingFieldWriterProvider.overrideWithValue(
          writer ?? _RecordingWriter(),
        ),
        occurrencePlantioOccurrencesProvider.overrideWith(
          (ref, fieldId) async => plantios,
        ),
        occurrenceTalhaoPlantioSnapshotProvider.overrideWith(
          (ref, fieldId) async => talhao,
        ),
        if (locationUnresolved)
          occurrenceLocationProvider.overrideWith((ref, query) async => null),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: OccurrenceCreationSheet(
            latitude: -10.72,
            longitude: -48.38,
            initialOccurrence: initialOccurrence,
            initialCategoryValue: initialCategory,
            talhaoPrefill: prefill,
            onConfirm: onConfirm,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _inSummary(String text) => find.descendant(
  of: find.byKey(const Key('occurrence_plantio_summary_card')),
  matching: find.text(text),
);

void main() {
  group('suggestedEstadioForDae', () {
    test('maior dap ≤ DAE; empate fica com o primeiro da lista', () {
      expect(suggestedEstadioForDae(dae: 0)?.code, 'VE');
      expect(suggestedEstadioForDae(dae: 9)?.code, 'V1');
      expect(suggestedEstadioForDae(dae: 25)?.code, 'V5');
      expect(suggestedEstadioForDae(dae: 100)?.code, 'R5.1');
      expect(suggestedEstadioForDae(dae: 200)?.code, 'R8');
    });

    test('soja ou cultura vazia sugere; outra cultura não', () {
      expect(suggestedEstadioForDae(dae: 20, cultura: 'Soja')?.code, 'V4');
      expect(
        suggestedEstadioForDae(dae: 20, cultura: 'soja safrinha'),
        isNotNull,
      );
      expect(suggestedEstadioForDae(dae: 20, cultura: 'Milho'), isNull);
      expect(suggestedEstadioForDae(dae: null), isNull);
      expect(suggestedEstadioForDae(dae: -1), isNull);
    });
  });

  testWidgets(
    'Ervas Daninhas nova num talhão com Plantio mostra Dados do plantio e '
    'salva copiando',
    (tester) async {
      OccurrenceFormData? submitted;
      final writer = _RecordingWriter();
      await _pumpSheet(
        tester,
        plantios: [
          _plantio(
            'p-1',
            createdAt: DateTime(2026, 10, 28),
            safra: _safraAtual,
          ),
        ],
        initialCategory: 'ervas_daninhas',
        prefill: _prefill,
        writer: writer,
        onConfirm: (data) async => submitted = data,
      );

      expect(find.text('Dados do plantio'), findsOneWidget);
      expect(find.text('Cultivar & Plantio'), findsNothing);
      expect(_inSummary('Soja · $_safraAtual'), findsOneWidget);
      expect(_inSummary('Neo 790'), findsOneWidget);
      expect(_inSummary('27/10/2026'), findsOneWidget);
      expect(_inSummary('30/10/2026'), findsOneWidget);
      expect(_inSummary('05/11/2026'), findsOneWidget);
      expect(_inSummary('115 dias'), findsOneWidget);
      expect(
        find.text('Para corrigir, edite a ocorrência de Plantio.'),
        findsOneWidget,
      );
      expect(find.text('14.5'), findsNothing);

      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(submitted, isNotNull);
      expect(submitted!.category, 'ervas_daninhas');
      expect(submitted!.fieldId, 'field-3');
      expect(submitted!.cultivar, 'Neo 790');
      expect(submitted!.cultura, 'Soja');
      expect(submitted!.safra, _safraAtual);
      expect(submitted!.dataPlantio, '2026-10-27');
      expect(submitted!.dataFimPlantio, '2026-10-30');
      expect(submitted!.dataEmergencia, '2026-11-05');
      expect(submitted!.cicloDias, 115);
      expect(submitted!.sementesPorMetro, isNull);
      expect(submitted!.estandePlantas, isNull);
      expect(submitted!.avaliacaoPlantio, isNull);
      expect(submitted!.objetivoPlantio, isNull);
      expect(writer.calls, isEmpty);
    },
  );

  testWidgets('sem Plantio nem talhão na safra mantém o bloco editável', (
    tester,
  ) async {
    await _pumpSheet(
      tester,
      plantios: const [],
      initialCategory: 'ervas_daninhas',
      prefill: _prefill,
      onConfirm: (_) async {},
    );

    expect(find.text('Dados do plantio'), findsNothing);
    expect(find.text('Cultivar & Plantio'), findsOneWidget);
    expect(find.text('🌱'), findsNothing);
  });

  testWidgets(
    'edição de Ervas Daninhas antiga preenche só os vazios, da safra dela, e '
    'sugere estádio',
    (tester) async {
      OccurrenceFormData? submitted;
      final antiga = Occurrence(
        id: 'd-antiga',
        type: 'Baixa',
        description: 'capim',
        category: 'ervas_daninhas',
        lat: -10.72,
        long: -48.38,
        createdAt: DateTime(2025, 12, 1),
        fieldId: 'field-3',
        cultivar: 'Própria',
      );
      await _pumpSheet(
        tester,
        plantios: [
          _plantio(
            'p-2025',
            createdAt: DateTime(2025, 10, 16),
            cultivar: 'Olimpo RR',
            cultura: null,
            dataPlantio: '2025-10-15',
            dataEmergencia: '2025-10-22',
          ),
          _plantio('p-2026', createdAt: DateTime(2026, 10, 28)),
        ],
        initialOccurrence: antiga,
        onConfirm: (data) async => submitted = data,
      );

      expect(find.text('Dados do plantio'), findsOneWidget);
      expect(_inSummary('Própria'), findsOneWidget);
      expect(_inSummary('Olimpo RR'), findsNothing);
      expect(_inSummary('15/10/2025'), findsOneWidget);
      expect(_inSummary('2025/2026'), findsOneWidget);
      expect(_inSummary('27/10/2026'), findsNothing);
      expect(find.text('47 dias após o plantio (DAP)'), findsOneWidget);
      expect(find.text('Sugerido pelos dias de lavoura'), findsOneWidget);

      await tester.tap(find.text('Salvar Alterações'));
      await tester.pump();

      expect(submitted, isNotNull);
      expect(submitted!.cultivar, 'Própria');
      expect(submitted!.dataPlantio, '2025-10-15');
      expect(submitted!.dataEmergencia, '2025-10-22');
      expect(submitted!.safra, '2025/2026');
      expect(submitted!.cultura, isNull);
      expect(submitted!.estadioFenologico, 'V5');
    },
  );

  testWidgets('estádio já salvo não é trocado pela sugestão', (tester) async {
    OccurrenceFormData? submitted;
    await _pumpSheet(
      tester,
      plantios: [
        _plantio('p-1', createdAt: DateTime(2026, 10, 28), safra: _safraAtual),
      ],
      initialOccurrence: Occurrence(
        id: 'd-1',
        type: 'Baixa',
        description: '',
        category: 'ervas_daninhas',
        lat: -10.72,
        long: -48.38,
        createdAt: DateTime.now(),
        fieldId: 'field-3',
        estadioFenologico: 'R1',
      ),
      onConfirm: (data) async => submitted = data,
    );

    expect(find.text('Sugerido pelos dias de lavoura'), findsNothing);
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();
    expect(submitted!.estadioFenologico, 'R1');
  });

  testWidgets(
    'Plantio novo vem preenchido do contexto e salva substituindo o talhão',
    (tester) async {
      final writer = _RecordingWriter();
      OccurrenceFormData? submitted;
      await _pumpSheet(
        tester,
        plantios: [
          _plantio('p-1', createdAt: DateTime(2026, 10, 1), safra: _safraAtual),
        ],
        initialCategory: 'plantio',
        prefill: _prefill,
        writer: writer,
        onConfirm: (data) async => submitted = data,
      );

      final cultivar = find.widgetWithText(TextField, 'Cultivar');
      final cultura = find.widgetWithText(TextField, 'Cultura');
      final safra = find.widgetWithText(TextField, 'Safra');
      expect(tester.widget<TextField>(cultivar).controller!.text, 'Neo 790');
      expect(tester.widget<TextField>(cultura).controller!.text, 'Soja');
      expect(tester.widget<TextField>(safra).controller!.text, _safraAtual);
      expect(find.text('Dados do plantio'), findsNothing);

      await tester.enterText(cultivar, 'Replantio 1');
      await tester.pump();
      await tester.tap(find.text('Salvar'));
      await tester.pump();

      expect(submitted!.cultivar, 'Replantio 1');
      expect(submitted!.cultura, 'Soja');
      expect(submitted!.safra, _safraAtual);
      expect(writer.calls, hasLength(1));
      expect(writer.calls.single['fieldId'], 'field-3');
      expect(writer.calls.single['material'], 'Replantio 1');
      expect(writer.calls.single['cultura'], 'Soja');
      expect(writer.calls.single['safra'], _safraAtual);
      expect(writer.calls.single['dataPlantio'], '2026-10-27');
      expect(writer.calls.single['cicloDias'], '115');
    },
  );

  testWidgets('Plantio novo sem safra digitada deriva a safra do início', (
    tester,
  ) async {
    final writer = _RecordingWriter();
    OccurrenceFormData? submitted;
    await _pumpSheet(
      tester,
      plantios: const [],
      initialCategory: 'plantio',
      prefill: const OccurrenceTalhaoPrefill(
        fieldId: 'field-3',
        talhaoNome: 'Talhão 3',
        clientId: 'c-1',
        dataPlantio: '2026-06-20',
      ),
      writer: writer,
      onConfirm: (data) async => submitted = data,
    );

    await tester.enterText(find.widgetWithText(TextField, 'Cultivar'), 'X1');
    await tester.pump();
    await tester.tap(find.text('Salvar'));
    await tester.pump();

    expect(submitted!.safra, '2025/2026');
    expect(writer.calls.single['material'], 'X1');
    expect(writer.calls.single['safra'], '2025/2026');
    expect(writer.calls.single['dataPlantio'], '2026-06-20');
  });

  testWidgets('edição de Plantio antigo não grava no talhão', (tester) async {
    final writer = _RecordingWriter();
    OccurrenceFormData? submitted;
    final antigo = _plantio(
      'p-antigo',
      createdAt: DateTime(2026, 10, 1),
      safra: '2026/2027',
      cultivar: 'Antigo',
    );
    await _pumpSheet(
      tester,
      plantios: [
        antigo,
        _plantio(
          'p-atual',
          createdAt: DateTime(2026, 10, 20),
          safra: '2026/2027',
        ),
      ],
      initialOccurrence: antigo,
      writer: writer,
      onConfirm: (data) async => submitted = data,
    );

    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();

    expect(submitted, isNotNull);
    expect(submitted!.cultivar, 'Antigo');
    expect(writer.calls, isEmpty);
  });

  testWidgets('edição do Plantio mais recente grava no talhão', (tester) async {
    final writer = _RecordingWriter();
    final atual = _plantio(
      'p-atual',
      createdAt: DateTime(2026, 10, 20),
      safra: '2026/2027',
      cultivar: 'Atual',
    );
    await _pumpSheet(
      tester,
      plantios: [
        _plantio(
          'p-antigo',
          createdAt: DateTime(2026, 10, 1),
          safra: '2026/2027',
        ),
        atual,
      ],
      initialOccurrence: atual,
      writer: writer,
      onConfirm: (_) async {},
    );

    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Safra'))
          .controller!
          .text,
      '2026/2027',
    );
    await tester.tap(find.text('Salvar Alterações'));
    await tester.pump();

    expect(writer.calls, hasLength(1));
    expect(writer.calls.single['material'], 'Atual');
    expect(writer.calls.single['safra'], '2026/2027');
  });

  testWidgets(
    'edição do Plantio mais recente usa o talhão salvo sem lookup do pin',
    (tester) async {
      final writer = _RecordingWriter();
      OccurrenceFormData? submitted;
      final atual = _plantio(
        'p-atual',
        createdAt: DateTime(2026, 10, 20),
        safra: '2026/2027',
        cultivar: 'Atual',
      );
      await _pumpSheet(
        tester,
        plantios: [atual],
        initialOccurrence: atual,
        writer: writer,
        locationUnresolved: true,
        onConfirm: (data) async => submitted = data,
      );

      expect(find.byKey(const Key('occurrence_location_line')), findsNothing);

      await tester.tap(find.text('Salvar Alterações'));
      await tester.pump();

      expect(submitted!.fieldId, 'field-3');
      expect(writer.calls, hasLength(1));
      expect(writer.calls.single['fieldId'], 'field-3');
      expect(writer.calls.single['material'], 'Atual');
    },
  );
}
