import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/models/occurrence_talhao_prefill.dart';

class _RecordingWriter implements IDrawingFieldWriter {
  _RecordingWriter({this.fail = false});

  final bool fail;
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
    if (fail) throw StateError('talhão inativo');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('writeBackTalhaoPlantio', () {
    test('Plantio substitui o plantio do talhão com os valores do formulário',
        () async {
      final writer = _RecordingWriter();

      await writeBackTalhaoPlantio(
        writer: writer,
        fieldId: ' field-1 ',
        category: 'plantio',
        cultura: 'Soja',
        cultivar: ' Neo 790 ',
        safra: '2026/2027',
        dataPlantio: '2026-10-27',
        dataEmergencia: '2026-11-05',
        cicloDias: 115,
      );

      expect(writer.calls, [
        {
          'fieldId': 'field-1',
          'cultura': 'Soja',
          'material': 'Neo 790',
          'safra': '2026/2027',
          'dataPlantio': '2026-10-27',
          'dataEmergencia': '2026-11-05',
          'cicloDias': '115',
        },
      ]);
    });

    test('campo vazio vai null (talhão mantém o atual)', () async {
      final writer = _RecordingWriter();

      await writeBackTalhaoPlantio(
        writer: writer,
        fieldId: 'field-1',
        category: 'plantio',
        cultivar: 'Neo 790',
        cultura: '  ',
      );

      expect(writer.calls.single['material'], 'Neo 790');
      expect(writer.calls.single['cultura'], isNull);
      expect(writer.calls.single['dataPlantio'], isNull);
      expect(writer.calls.single['cicloDias'], isNull);
    });

    test('outras categorias não gravam no talhão', () async {
      final writer = _RecordingWriter();

      for (final category in ['ervas_daninhas', 'doenca', null]) {
        await writeBackTalhaoPlantio(
          writer: writer,
          fieldId: 'field-1',
          category: category,
          cultivar: 'Neo 790',
          dataPlantio: '2026-10-27',
        );
      }

      expect(writer.calls, isEmpty);
    });

    test('Plantio sem nenhum valor não chama o writer', () async {
      final writer = _RecordingWriter();

      await writeBackTalhaoPlantio(
        writer: writer,
        fieldId: 'field-1',
        category: 'plantio',
      );

      expect(writer.calls, isEmpty);
    });

    test('falha do writer não propaga', () async {
      final writer = _RecordingWriter(fail: true);

      await expectLater(
        writeBackTalhaoPlantio(
          writer: writer,
          fieldId: 'field-1',
          category: 'plantio',
          cultivar: 'Neo 790',
        ),
        completes,
      );
      expect(writer.calls, hasLength(1));
    });
  });

  test('prefill do talhão leva a cultura para campo vazio', () {
    final built = occurrenceTalhaoPrefillIfEligible(
      ativo: true,
      fieldId: 'field-1',
      nome: 'Talhão Norte',
      clienteId: 'client-1',
      fazendaId: null,
      cultura: ' Soja ',
    );
    expect(built!.cultura, 'Soja');

    final vazio = applyTalhaoPrefill(
      prefill: built,
      isEditing: false,
      currentCultivar: '',
      currentDataPlantio: null,
      currentDataEmergencia: null,
      currentCicloDias: '',
      draftHasClient: false,
    );
    expect(vazio.cultura, 'Soja');

    final rascunho = applyTalhaoPrefill(
      prefill: built,
      isEditing: false,
      currentCultivar: '',
      currentDataPlantio: null,
      currentDataEmergencia: null,
      currentCicloDias: '',
      draftHasClient: false,
      currentCultura: 'Milho',
    );
    expect(rascunho.cultura, isNull);
  });

  const prefill = OccurrenceTalhaoPrefill(
    fieldId: 'field-1',
    talhaoNome: 'Talhão Norte',
    clientId: 'client-1',
    cultivar: 'Olimpo RR',
    dataPlantio: '2026-01-10',
    dataEmergencia: '2026-01-18',
    cicloDias: 115,
  );

  test('rascunho com cultivar mantém o do rascunho', () {
    final patch = applyTalhaoPrefill(
      prefill: prefill,
      isEditing: false,
      currentCultivar: 'Cultivar do rascunho',
      currentDataPlantio: null,
      currentDataEmergencia: null,
      currentCicloDias: '',
      draftHasClient: false,
    );

    expect(patch.cultivar, isNull);
    expect(patch.dataPlantio, '2026-01-10');
    expect(patch.dataEmergencia, '2026-01-18');
    expect(patch.cicloDias, '115');
  });

  test('campo vazio recebe o material do talhão', () {
    final patch = applyTalhaoPrefill(
      prefill: prefill,
      isEditing: false,
      currentCultivar: '  ',
      currentDataPlantio: '',
      currentDataEmergencia: null,
      currentCicloDias: '',
      draftHasClient: true,
    );

    expect(patch.cultivar, 'Olimpo RR');
    expect(patch.applyClient, isFalse);
  });

  test('edição não aplica o prefill', () {
    final patch = applyTalhaoPrefill(
      prefill: prefill,
      isEditing: true,
      currentCultivar: '',
      currentDataPlantio: null,
      currentDataEmergencia: null,
      currentCicloDias: '',
      draftHasClient: false,
    );

    expect(patch.cultivar, isNull);
    expect(patch.dataPlantio, isNull);
    expect(patch.dataEmergencia, isNull);
    expect(patch.cicloDias, isNull);
    expect(patch.applyClient, isFalse);
  });

  test('sem fazendaId o talhão ainda vira prefill, sem fazenda', () {
    final built = occurrenceTalhaoPrefillIfEligible(
      ativo: true,
      fieldId: 'field-1',
      nome: 'Talhão Norte',
      clienteId: 'client-1',
      fazendaId: '',
      material: 'Olimpo RR',
    );

    expect(built, isNotNull);
    expect(built!.fieldId, 'field-1');
    expect(built.clientId, 'client-1');
    expect(built.fazendaId, isNull);
    expect(built.cultivar, 'Olimpo RR');
  });

  test('sem cliente ou inativo o talhão não é elegível', () {
    expect(
      occurrenceTalhaoPrefillIfEligible(
        ativo: true,
        fieldId: 'field-1',
        nome: 'Talhão Norte',
        clienteId: '  ',
        fazendaId: 'farm-1',
      ),
      isNull,
    );
    expect(
      occurrenceTalhaoPrefillIfEligible(
        ativo: false,
        fieldId: 'field-1',
        nome: 'Talhão Norte',
        clienteId: 'client-1',
        fazendaId: 'farm-1',
      ),
      isNull,
    );
  });

  test('talhão ativo com cliente e fazenda vira prefill', () {
    final built = occurrenceTalhaoPrefillIfEligible(
      ativo: true,
      fieldId: 'field-1',
      nome: 'Talhão Norte',
      clienteId: ' client-1 ',
      fazendaId: 'farm-1',
      material: ' Olimpo RR ',
      dataPlantio: '2026-01-10',
      cicloDias: 115,
    );

    expect(built, isNotNull);
    expect(built!.clientId, 'client-1');
    expect(built.fazendaId, 'farm-1');
    expect(built.cultivar, 'Olimpo RR');
    expect(built.dataEmergencia, isNull);
    expect(built.cicloDias, 115);
  });
}
