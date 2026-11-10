import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/models/occurrence_talhao_prefill.dart';

void main() {
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
