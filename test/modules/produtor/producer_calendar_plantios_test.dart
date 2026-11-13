import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/contracts/i_producer_crop_calendar.dart';
import 'package:soloforte_app/core/contracts/i_producer_crop_calendar_provider.dart';
import 'package:soloforte_app/core/domain/soy_phenology.dart';
import 'package:soloforte_app/modules/produtor/presentation/screens/producer_calendar_plantios.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);
  final todayIso = _iso(day);
  final todayLabel = DateFormat('dd/MM/yyyy').format(day);

  testWidgets('mostra data, adicionar e uma frase de rodapé', (tester) async {
    final harvest = approximateSoyHarvestDate(
      dataEmergenciaIso: null,
      dataPlantioIso: todayIso,
      cicloDias: 100,
    );

    await _pump(
      tester,
      calendar: _FakeCalendar(),
      plantings: [
        ProducerCropPlanting(
          fieldId: 'soy',
          fieldName: 'Talhão A',
          farmName: 'Fazenda Norte',
          cultura: 'Soja',
          safra: '2026/2027',
          dataPlantio: todayIso,
          dataEmergencia: todayIso,
          cicloDias: 120,
          canEdit: true,
        ),
        const ProducerCropPlanting(
          fieldId: 'empty',
          fieldName: 'Talhão B',
          farmName: '',
          cultura: null,
          safra: null,
          dataPlantio: null,
          dataEmergencia: null,
          cicloDias: null,
          canEdit: true,
        ),
        ProducerCropPlanting(
          fieldId: 'milho',
          fieldName: 'Talhão C',
          farmName: 'Fazenda Norte',
          cultura: 'Milho',
          safra: null,
          dataPlantio: todayIso,
          dataEmergencia: null,
          cicloDias: 100,
          canEdit: true,
        ),
      ],
    );

    expect(find.text('Talhão A'), findsOneWidget);
    expect(find.text('Fazenda Norte · Soja · 2026/2027'), findsOneWidget);
    expect(find.text(todayLabel), findsWidgets);
    expect(find.text('120 dias'), findsOneWidget);
    expect(
      find.text('VE - Emergência · 0 dias após a emergência'),
      findsOneWidget,
    );
    expect(find.text('Talhão B'), findsOneWidget);
    expect(find.text('Adicionar'), findsNWidgets(4));
    expect(
      find.text('Informe a emergência para ver o estádio.'),
      findsOneWidget,
    );
    expect(find.text('Fazenda Norte · Milho'), findsOneWidget);
    expect(
      find.text(
        'Colheita aproximada: ${DateFormat('dd/MM/yyyy').format(harvest!)}',
      ),
      findsOneWidget,
    );
    expect(find.text('Não informado'), findsNothing);
    expect(find.text('Registrar plantio'), findsNothing);
    expect(find.textContaining('Ciclo não informado'), findsNothing);
    expect(find.byType(Card), findsNothing);
    expect(find.byType(TextField), findsNothing);
    expect(find.byType(FloatingActionButton), findsNothing);
  });

  testWidgets('toque grava só a data de plantio', (tester) async {
    final calendar = _FakeCalendar();
    await _pump(
      tester,
      calendar: calendar,
      plantings: const [
        ProducerCropPlanting(
          fieldId: 'empty',
          fieldName: 'Talhão B',
          farmName: '',
          cultura: null,
          safra: null,
          dataPlantio: null,
          dataEmergencia: null,
          cicloDias: null,
          canEdit: true,
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('producer-planting-plantio-empty')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('10').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final picked = DateTime(day.year, day.month, 10);
    expect(calendar.saves, 1);
    expect(calendar.fieldId, 'empty');
    expect(calendar.dataPlantio, _iso(picked));
    expect(calendar.dataEmergencia, isNull);
    expect(calendar.cicloDias, isNull);
  });

  testWidgets('toque grava só o ciclo', (tester) async {
    final calendar = _FakeCalendar();
    await _pump(
      tester,
      calendar: calendar,
      plantings: const [
        ProducerCropPlanting(
          fieldId: 'empty',
          fieldName: 'Talhão B',
          farmName: '',
          cultura: null,
          safra: null,
          dataPlantio: null,
          dataEmergencia: null,
          cicloDias: null,
          canEdit: true,
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('producer-planting-ciclo-empty')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('producer-planting-ciclo-input')),
      '118',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(calendar.saves, 1);
    expect(calendar.fieldId, 'empty');
    expect(calendar.cicloDias, '118');
    expect(calendar.dataPlantio, isNull);
    expect(calendar.dataEmergencia, isNull);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('sem edição o toque não abre o seletor', (tester) async {
    final calendar = _FakeCalendar();
    await _pump(
      tester,
      calendar: calendar,
      plantings: const [
        ProducerCropPlanting(
          fieldId: 'locked',
          fieldName: 'Talhão D',
          farmName: '',
          cultura: null,
          safra: null,
          dataPlantio: null,
          dataEmergencia: null,
          cicloDias: null,
          canEdit: false,
        ),
      ],
    );

    await tester.tap(find.byKey(const Key('producer-planting-plantio-locked')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsNothing);
    expect(calendar.saves, 0);
    expect(find.text('Adicionar'), findsNothing);
    expect(find.text('—'), findsNWidgets(3));
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required List<ProducerCropPlanting> plantings,
  required _FakeCalendar calendar,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        producerCropPlantingsProvider.overrideWith((ref) async => plantings),
        producerCropCalendarProvider.overrideWithValue(calendar),
      ],
      child: MaterialApp(
        locale: const Locale('pt', 'BR'),
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [Locale('pt', 'BR')],
        home: const Scaffold(body: ProducerCalendarPlantios()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

String _iso(DateTime date) {
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
}

class _FakeCalendar implements IProducerCropCalendar {
  String? fieldId;
  String? dataPlantio;
  String? dataEmergencia;
  String? cicloDias;
  int saves = 0;

  @override
  Future<List<ProducerCropPlanting>> listForProducer() async => const [];

  @override
  Future<void> saveOwnPlanting({
    required String fieldId,
    String? dataPlantio,
    String? dataEmergencia,
    String? cicloDias,
  }) async {
    saves += 1;
    this.fieldId = fieldId;
    this.dataPlantio = dataPlantio;
    this.dataEmergencia = dataEmergencia;
    this.cicloDias = cicloDias;
  }
}
