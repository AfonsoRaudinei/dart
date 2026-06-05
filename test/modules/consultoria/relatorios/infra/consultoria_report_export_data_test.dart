import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/infra/consultoria_report_export_data.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_status.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_tecnico.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/visit_session_snapshot.dart';

void main() {
  test('exporta RelatorioTecnico.toJson e CSV estruturado', () {
    final relatorio = _makeFullReport();

    final json = ConsultoriaReportExportData.reportJson(relatorio);
    final csv = ConsultoriaReportExportData.reportCsv(relatorio);

    expect(json['id'], 'rel-1');
    expect(json['ocorrencias'], isA<List>());
    expect(csv, contains('tipo_registro,relatorio_id,item_id'));
    expect(csv, contains('talhao,rel-1,talhao-1,Talhao Norte'));
    expect(csv, contains('ocorrencia,rel-1,occ-1'));
    expect(csv, contains('monitoramento,rel-1,mon-1'));
    expect(csv, contains('publicacao,rel-1,pub-1'));
  });

  test('CSV escapa virgula, aspas e quebra de linha', () {
    final csv = ConsultoriaReportExportData.toCsv([
      ['nome', 'descricao'],
      ['Talhao A', 'texto, com "aspas"\ne linha'],
    ]);

    expect(csv, contains('"texto, com ""aspas""\ne linha"'));
  });
}

RelatorioTecnico _makeFullReport() {
  final now = DateTime.utc(2026, 6, 3, 12);
  return RelatorioTecnico(
    id: 'rel-1',
    visitSessionId: 'sess-1',
    clientId: 'client-1',
    agronomistId: 'agro-1',
    farmName: 'Fazenda Modelo',
    periodStart: now.subtract(const Duration(hours: 2)),
    periodEnd: now,
    status: RelatorioStatus.pendente_revisao,
    syncStatus: RelatorioSyncStatus.local_only,
    createdAt: now,
    updatedAt: now,
    title: 'Visita tecnica',
    customNotes: 'Notas finais',
    publicacoesRefs: const ['pub-1'],
    talhoes: const [
      TalhaoVisitado(
        talhaoId: 'talhao-1',
        nomeTalhao: 'Talhao Norte',
        areaHectares: 12.5,
        cultura: 'Soja',
        safra: '2025/26',
      ),
    ],
    ocorrencias: [
      OcorrenciaSnapshot(
        id: 'occ-1',
        tipo: 'Insetos',
        descricao: 'Lagarta em reboleira',
        lat: -10.1,
        lng: -48.2,
        registradaEm: now,
      ),
    ],
    monitoramentos: [
      MonitoramentoSnapshot(
        id: 'mon-1',
        tipo: 'Fenologia',
        dados: const {'estadio': 'V4'},
        coletadoEm: now,
      ),
    ],
  );
}
