import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence_soy_age.dart';

void main() {
  final today = DateTime(2026, 11, 5);

  test('DAP usa dias de calendário e o texto existente', () {
    expect(
      occurrenceDapLabel(DateTime(2026, 11, 1), today: today),
      '4 dias desde o plantio (DAP real)',
    );
    expect(
      occurrenceDapLabel(DateTime(2026, 11, 5, 23), today: today),
      '0 dias desde o plantio (DAP real)',
    );
  });

  test('emergência vira Soja com N dias', () {
    expect(
      occurrenceSoyAgeLabel(DateTime(2026, 10, 21), today: today),
      'Soja com 15 dias',
    );
  });

  test('emergência e ciclo ausentes não geram linha', () {
    expect(occurrenceSoyAgeLabel(null, today: today), isNull);
    expect(occurrenceDapLabel(null, today: today), isNull);
    expect(occurrenceCicloLabel(null), isNull);
  });

  test('ciclo 115 vira 115 dias', () {
    expect(occurrenceCicloLabel(115), '115 dias');
  });

  test('data no futuro não gera idade', () {
    expect(occurrenceDapLabel(DateTime(2026, 11, 6), today: today), isNull);
    expect(occurrenceSoyAgeLabel(DateTime(2026, 12, 1), today: today), isNull);
  });

  test('DAP/DAE compactos e linha com estádio', () {
    expect(
      occurrenceDapCampoLabel(DateTime(2026, 10, 4), today: today),
      '32 dias após o plantio',
    );
    expect(
      occurrenceIdadeCampoResumo(
        dataPlantioIso: '2026-10-04',
        dataEmergenciaIso: '2026-10-10',
        today: today,
      ),
      '32 dias após o plantio · 26 dias após a emergência',
    );
    expect(
      formatEstadioComIdadeCampo(
        estadioCode: 'V4',
        idadeResumo: '32 dias após o plantio',
      ),
      'V4 — 32 dias após o plantio',
    );
    expect(formatEstadioComIdadeCampo(estadioCode: 'V4'), 'V4');
    expect(
      formatEstadioComIdadeCampo(idadeResumo: '32 dias após o plantio'),
      '',
    );
  });

  test('sufixo some sem data de plantio ou emergência', () {
    final comData = Occurrence(
      id: 'o1',
      type: 'Média',
      description: 'ferrugem',
      createdAt: today,
      estadioFenologico: 'V4',
      dataPlantio: '2026-10-04',
      dataEmergencia: '2026-10-10',
    );
    final semData = Occurrence(
      id: 'o2',
      type: 'Média',
      description: 'ferrugem',
      createdAt: today,
      estadioFenologico: 'V4',
    );

    expect(
      occurrenceEstadioDisplay(comData, today: today),
      'V4 — 32 dias após o plantio · 26 dias após a emergência',
    );
    expect(occurrenceEstadioDisplay(semData, today: today), 'V4');
    expect(occurrenceIdadeCampoResumo(today: today), isNull);
  });
}
