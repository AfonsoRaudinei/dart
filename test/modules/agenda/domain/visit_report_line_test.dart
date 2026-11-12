import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/visit_report_line.dart';
import 'package:soloforte_app/modules/map/domain/visit_report_place_name.dart';

void main() {
  test('relatório mostra talhão e fazenda da ocorrência', () {
    final line = resolveVisitReportLine(
      resolvedFieldName: 'Talhão X',
      resolvedFarmName: 'Fazenda X',
      eventFieldName: 'Outro',
      eventFarmName: 'Outra',
    );

    expect(line.label, 'Talhão X · Fazenda X');
  });

  test('sem talhão da ocorrência usa o do evento', () {
    final line = resolveVisitReportLine(
      eventFieldName: 'Talhão X',
      eventFarmName: 'Fazenda X',
    );

    expect(line.label, 'Talhão X · Fazenda X');
    expect(visitReportCountLabel(0), 'Nenhum relatório nesta visita.');
    expect(visitReportCountLabel(1), '1 relatório');
    expect(visitReportCountLabel(2), '2 relatórios');
  });

  test('nome ausente não vira UUID', () {
    expect(
      resolveVisitPlaceName(
        lookedUpName: null,
        unidentified: 'Fazenda não identificada',
      ),
      'Fazenda não identificada',
    );
    expect(
      resolveVisitPlaceName(
        lookedUpName: 'Fazenda X',
        unidentified: 'Fazenda não identificada',
      ),
      'Fazenda X',
    );
  });
}
