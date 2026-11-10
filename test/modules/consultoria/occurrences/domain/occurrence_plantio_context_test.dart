import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_plantio_context.dart';

Occurrence _plantio(
  String id, {
  String fieldId = 'field-1',
  required DateTime createdAt,
  DateTime? updatedAt,
  String? dataPlantio,
  String? safra,
  String? cultivar,
  String? cultura,
  String? category = 'plantio',
  String? deletedAt,
  String syncStatus = 'synced',
}) {
  return Occurrence(
    id: id,
    type: 'Baixa',
    description: '',
    category: category,
    createdAt: createdAt,
    updatedAt: updatedAt ?? createdAt,
    fieldId: fieldId,
    dataPlantio: dataPlantio,
    safra: safra,
    cultivar: cultivar,
    cultura: cultura,
    deletedAt: deletedAt,
    syncStatus: syncStatus,
    dataFimPlantio: dataPlantio == null ? null : '2026-10-30',
    dataEmergencia: dataPlantio == null ? null : '2026-11-05',
    cicloDias: dataPlantio == null ? null : 115,
  );
}

void main() {
  group('safraFromPlantio', () {
    test('junho fica na safra anterior', () {
      expect(safraFromPlantio(DateTime(2026, 6, 30)), '2025/2026');
    });

    test('julho abre a safra nova', () {
      expect(safraFromPlantio(DateTime(2026, 7, 1)), '2026/2027');
      expect(safraFromPlantio(DateTime(2026, 10, 27)), '2026/2027');
      expect(safraFromPlantio(DateTime(2027, 1, 15)), '2026/2027');
    });
  });

  group('occurrenceDateInSafra', () {
    test('janela jul..jun', () {
      expect(occurrenceDateInSafra(DateTime(2026, 7, 1), '2026/2027'), isTrue);
      expect(occurrenceDateInSafra(DateTime(2027, 6, 30), '2026/2027'), isTrue);
      expect(occurrenceDateInSafra(DateTime(2027, 7, 1), '2026/2027'), isFalse);
      expect(
        occurrenceDateInSafra(DateTime(2026, 6, 30), '2026/2027'),
        isFalse,
      );
    });

    test('aceita AAAA/AA e rejeita texto ilegível', () {
      expect(occurrenceDateInSafra(DateTime(2026, 12, 1), '2026/27'), isTrue);
      expect(occurrenceDateInSafra(DateTime(2026, 12, 1), 'safra boa'), isFalse);
      expect(occurrenceDateInSafra(DateTime(2026, 12, 1), '2026/2028'), isFalse);
    });
  });

  group('resolvePlantioContext', () {
    test('duas safras no mesmo talhão não se misturam', () {
      final antiga = _plantio(
        'p-2025',
        createdAt: DateTime(2025, 10, 20),
        dataPlantio: '2025-10-18',
        cultivar: 'Olimpo RR',
      );
      final atual = _plantio(
        'p-2026',
        createdAt: DateTime(2026, 10, 28),
        dataPlantio: '2026-10-27',
        cultivar: 'Neo 790',
        cultura: 'Soja',
      );

      final nova = resolvePlantioContext(
        fieldId: 'field-1',
        plantioOccurrences: [antiga, atual],
        talhao: null,
        referenceDate: DateTime(2026, 12, 10),
      );
      expect(nova!.sourceOccurrenceId, 'p-2026');
      expect(nova.cultivar, 'Neo 790');
      expect(nova.cultura, 'Soja');
      expect(nova.safra, '2026/2027');
      expect(nova.dataFimPlantio, '2026-10-30');
      expect(nova.cicloDias, 115);

      final velha = resolvePlantioContext(
        fieldId: 'field-1',
        plantioOccurrences: [antiga, atual],
        talhao: null,
        referenceDate: DateTime(2026, 2, 1),
      );
      expect(velha!.sourceOccurrenceId, 'p-2025');
      expect(velha.cultivar, 'Olimpo RR');
      expect(velha.safra, '2025/2026');
    });

    test('replantio na mesma safra: vence o mais recente', () {
      final primeiro = _plantio(
        'p-1',
        createdAt: DateTime(2026, 10, 1),
        updatedAt: DateTime(2026, 12, 1),
        dataPlantio: '2026-09-30',
        cultivar: 'Primeiro',
      );
      final replantio = _plantio(
        'p-2',
        createdAt: DateTime(2026, 10, 20),
        dataPlantio: '2026-10-19',
        cultivar: 'Replantio',
      );

      final context = resolvePlantioContext(
        fieldId: 'field-1',
        plantioOccurrences: [replantio, primeiro],
        talhao: null,
        referenceDate: DateTime(2026, 11, 1),
      );

      expect(context!.sourceOccurrenceId, 'p-2');
      expect(context.cultivar, 'Replantio');
    });

    test('safra salva vence a data; sem data usa a criação', () {
      final semData = _plantio('p-sem-data', createdAt: DateTime(2026, 8, 1));
      expect(plantioOccurrenceSafra(semData), '2026/2027');
      final comSafra = _plantio(
        'p-safra',
        createdAt: DateTime(2026, 8, 1),
        dataPlantio: '2026-08-01',
        safra: '2025/2026',
      );
      expect(plantioOccurrenceSafra(comSafra), '2025/2026');
    });

    test('sem Plantio na safra usa o talhão', () {
      final context = resolvePlantioContext(
        fieldId: 'field-1',
        plantioOccurrences: const [],
        talhao: const TalhaoPlantioSnapshot(
          cultura: 'Soja',
          material: 'Olimpo RR',
          safra: '2026/2027',
          dataPlantio: '2026-10-10',
          dataEmergencia: '2026-10-17',
          cicloDias: 120,
        ),
        referenceDate: DateTime(2026, 11, 1),
      );

      expect(context, isNotNull);
      expect(context!.sourceOccurrenceId, isNull);
      expect(context.cultura, 'Soja');
      expect(context.cultivar, 'Olimpo RR');
      expect(context.safra, '2026/2027');
      expect(context.dataPlantio, '2026-10-10');
      expect(context.dataEmergencia, '2026-10-17');
      expect(context.cicloDias, 120);
      expect(context.dataFimPlantio, isNull);
    });

    test('talhão sem safra deriva da data de plantio', () {
      final context = resolvePlantioContext(
        fieldId: 'field-1',
        plantioOccurrences: const [],
        talhao: const TalhaoPlantioSnapshot(
          material: 'Olimpo RR',
          dataPlantio: '2026-10-10',
        ),
        referenceDate: DateTime(2026, 11, 1),
      );
      expect(context!.safra, '2026/2027');
    });

    test('talhão de outra safra não vira contexto', () {
      final context = resolvePlantioContext(
        fieldId: 'field-1',
        plantioOccurrences: const [],
        talhao: const TalhaoPlantioSnapshot(
          cultura: 'Soja',
          material: 'Olimpo RR',
          safra: '2025/2026',
          dataPlantio: '2025-10-10',
        ),
        referenceDate: DateTime(2026, 11, 1),
      );
      expect(context, isNull);
    });

    test('talhão sem safra nem data não vira contexto', () {
      final context = resolvePlantioContext(
        fieldId: 'field-1',
        plantioOccurrences: const [],
        talhao: const TalhaoPlantioSnapshot(cultura: 'Soja'),
        referenceDate: DateTime(2026, 11, 1),
      );
      expect(context, isNull);
    });

    test('Plantio excluído, de outro talhão ou de outra categoria é ignorado',
        () {
      final reference = DateTime(2026, 11, 1);
      final excluido = _plantio(
        'p-excluido',
        createdAt: DateTime(2026, 10, 25),
        dataPlantio: '2026-10-24',
        cultivar: 'Excluído',
        deletedAt: '2026-10-26T00:00:00Z',
      );
      final tombstone = _plantio(
        'p-tombstone',
        createdAt: DateTime(2026, 10, 26),
        dataPlantio: '2026-10-25',
        cultivar: 'Tombstone',
        syncStatus: 'deleted_local',
      );
      final outroTalhao = _plantio(
        'p-outro',
        fieldId: 'field-2',
        createdAt: DateTime(2026, 10, 27),
        dataPlantio: '2026-10-26',
        cultivar: 'Outro talhão',
      );
      final daninha = _plantio(
        'd-1',
        category: 'ervas_daninhas',
        createdAt: DateTime(2026, 10, 28),
        dataPlantio: '2026-10-27',
        cultivar: 'Daninha',
      );
      final valido = _plantio(
        'p-valido',
        createdAt: DateTime(2026, 10, 1),
        dataPlantio: '2026-09-30',
        cultivar: 'Válido',
      );

      final context = resolvePlantioContext(
        fieldId: 'field-1',
        plantioOccurrences: [excluido, tombstone, outroTalhao, daninha, valido],
        talhao: null,
        referenceDate: reference,
      );
      expect(context!.sourceOccurrenceId, 'p-valido');

      expect(
        resolvePlantioContext(
          fieldId: 'field-1',
          plantioOccurrences: [excluido, tombstone],
          talhao: null,
          referenceDate: reference,
        ),
        isNull,
      );
    });

    test('fieldId vazio → null', () {
      expect(
        resolvePlantioContext(
          fieldId: '  ',
          plantioOccurrences: const [],
          talhao: const TalhaoPlantioSnapshot(safra: '2026/2027'),
        ),
        isNull,
      );
    });
  });

  group('isLatestPlantioInSafra', () {
    final antigo = _plantio(
      'p-1',
      createdAt: DateTime(2026, 10, 1),
      dataPlantio: '2026-09-30',
    );
    final atual = _plantio(
      'p-2',
      createdAt: DateTime(2026, 10, 20),
      dataPlantio: '2026-10-19',
    );
    final safraAnterior = _plantio(
      'p-0',
      createdAt: DateTime(2027, 1, 1),
      dataPlantio: '2026-02-01',
    );

    test('o mais recente da safra é o atual', () {
      expect(
        isLatestPlantioInSafra(
          fieldId: 'field-1',
          plantio: atual,
          plantioOccurrences: [antigo, atual],
        ),
        isTrue,
      );
    });

    test('Plantio antigo editado continua não sendo o atual', () {
      expect(
        isLatestPlantioInSafra(
          fieldId: 'field-1',
          plantio: antigo.copyWith(updatedAt: DateTime(2026, 12, 1)),
          plantioOccurrences: [antigo, atual],
        ),
        isFalse,
      );
    });

    test('Plantio mais novo de outra safra não conta', () {
      expect(
        isLatestPlantioInSafra(
          fieldId: 'field-1',
          plantio: atual,
          plantioOccurrences: [antigo, atual, safraAnterior],
        ),
        isTrue,
      );
    });
  });

  test('mescla: valores próprios primeiro, vazios do contexto', () {
    final own = Occurrence(
      id: 'd-1',
      type: 'Baixa',
      description: '',
      category: 'ervas_daninhas',
      createdAt: DateTime(2026, 11, 1),
      cultivar: 'Própria',
    );
    const context = OccurrencePlantioContext(
      fieldId: 'field-1',
      cultura: 'Soja',
      safra: '2026/2027',
      cultivar: 'Do Plantio',
      dataPlantio: '2026-10-27',
      cicloDias: 115,
    );

    final merged = mergeOccurrencePlantioContext(own, context);

    expect(merged.cultivar, 'Própria');
    expect(merged.cultura, 'Soja');
    expect(merged.safra, '2026/2027');
    expect(merged.dataPlantio, '2026-10-27');
    expect(merged.cicloDias, 115);
  });
}
