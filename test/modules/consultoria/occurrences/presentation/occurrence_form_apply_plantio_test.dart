import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/occurrence_form_apply.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_creation_sheet.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';

void main() {
  final plantio = Occurrence(
    id: 'occ-plantio',
    type: 'Baixa',
    description: '',
    category: 'plantio',
    createdAt: DateTime(2026, 11, 9),
    cultivar: 'Neo 790',
    dataPlantio: '2026-10-27',
    dataEmergencia: '2026-11-05',
    sementesPorMetro: 14,
    estandePlantas: 12,
    avaliacaoPlantio: 'boa',
    objetivoPlantio: 'Produção',
  );

  const fullForm = OccurrenceFormData(
    type: 'Baixa',
    description: '',
    latitude: -10.72,
    longitude: -48.38,
    category: 'plantio',
    cultivar: 'Neo 790',
    dataPlantio: '2026-10-27',
    dataEmergencia: '2026-11-05',
    sementesPorMetro: 14,
    estandePlantas: 12,
    avaliacaoPlantio: 'boa',
    objetivoPlantio: 'Produção',
  );

  test('campos de plantio fazem ida e volta na edição', () {
    final edited = occurrenceWithFormData(plantio, fullForm);

    expect(edited.cultivar, 'Neo 790');
    expect(edited.dataPlantio, '2026-10-27');
    expect(edited.dataEmergencia, '2026-11-05');
    expect(edited.sementesPorMetro, 14);
    expect(edited.estandePlantas, 12);
    expect(edited.avaliacaoPlantio, 'boa');
    expect(edited.objetivoPlantio, 'Produção');
  });

  test('limpar a data de emergência na edição persiste null', () {
    const form = OccurrenceFormData(
      type: 'Baixa',
      description: '',
      latitude: -10.72,
      longitude: -48.38,
      category: 'plantio',
      cultivar: 'Neo 790',
      dataPlantio: '2026-10-27',
    );

    final edited = applyOccurrenceFormEdit(plantio, form);

    expect(edited.dataEmergencia, isNull);
    expect(edited.dataPlantio, '2026-10-27');
    expect(edited.cultivar, 'Neo 790');
  });

  test('limpar os demais campos de plantio persiste null', () {
    const form = OccurrenceFormData(
      type: 'Baixa',
      description: '',
      latitude: -10.72,
      longitude: -48.38,
      category: 'plantio',
    );

    final edited = occurrenceWithFormData(plantio, form);

    expect(edited.cultivar, isNull);
    expect(edited.dataPlantio, isNull);
    expect(edited.dataEmergencia, isNull);
    expect(edited.sementesPorMetro, isNull);
    expect(edited.estandePlantas, isNull);
    expect(edited.avaliacaoPlantio, isNull);
    expect(edited.objetivoPlantio, isNull);
  });

  test('fieldId ausente recebe o talhão resolvido', () {
    const form = OccurrenceFormData(
      type: 'Baixa',
      description: '',
      latitude: -10.72,
      longitude: -48.38,
      fieldId: 'field-resolvido',
    );

    final edited = applyOccurrenceFormEdit(plantio, form);

    expect(edited.fieldId, 'field-resolvido');
  });

  test('fieldId existente nunca é sobrescrito', () {
    const form = OccurrenceFormData(
      type: 'Baixa',
      description: '',
      latitude: -10.72,
      longitude: -48.38,
      fieldId: 'field-outro',
    );

    final edited = applyOccurrenceFormEdit(
      plantio.copyWith(fieldId: 'field-original'),
      form,
    );

    expect(edited.fieldId, 'field-original');
  });
}
