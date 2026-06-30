import '../models/relatorio_tecnico.dart';
import '../../occurrences/domain/occurrence.dart';

class ConsultoriaReportExportData {
  const ConsultoriaReportExportData._();

  static String reportFileBaseName(RelatorioTecnico relatorio) {
    final title = relatorio.title?.trim();
    if (title != null && title.isNotEmpty) return title;
    return 'relatorio_visita_${relatorio.id}';
  }

  static Map<String, dynamic> reportJson(RelatorioTecnico relatorio) {
    return relatorio.toJson();
  }

  static String reportCsv(RelatorioTecnico relatorio) {
    final rows = <List<Object?>>[
      [
        'tipo_registro',
        'relatorio_id',
        'item_id',
        'nome',
        'tipo',
        'descricao',
        'data',
        'lat',
        'lng',
        'area_ha',
        'cultura',
        'safra',
        'chave',
        'valor',
      ],
      [
        'relatorio',
        relatorio.id,
        relatorio.id,
        relatorio.title ?? relatorio.farmName,
        'visita',
        relatorio.customNotes,
        relatorio.createdAt.toIso8601String(),
        null,
        null,
        null,
        null,
        null,
        'status',
        relatorio.status.name,
      ],
    ];

    for (final talhao in relatorio.talhoes) {
      rows.add([
        'talhao',
        relatorio.id,
        talhao.talhaoId,
        talhao.nomeTalhao,
        null,
        null,
        null,
        null,
        null,
        talhao.areaHectares,
        talhao.cultura,
        talhao.safra,
        null,
        null,
      ]);
    }

    for (final ocorrencia in relatorio.ocorrencias) {
      rows.add([
        'ocorrencia',
        relatorio.id,
        ocorrencia.id,
        null,
        ocorrencia.tipo,
        ocorrencia.descricao,
        ocorrencia.registradaEm.toIso8601String(),
        ocorrencia.lat,
        ocorrencia.lng,
        null,
        null,
        null,
        'foto_path',
        ocorrencia.fotoPath,
      ]);
    }

    for (final monitoramento in relatorio.monitoramentos) {
      if (monitoramento.dados.isEmpty) {
        rows.add([
          'monitoramento',
          relatorio.id,
          monitoramento.id,
          null,
          monitoramento.tipo,
          null,
          monitoramento.coletadoEm.toIso8601String(),
          null,
          null,
          null,
          null,
          null,
          null,
          null,
        ]);
        continue;
      }
      for (final entry in monitoramento.dados.entries) {
        rows.add([
          'monitoramento',
          relatorio.id,
          monitoramento.id,
          null,
          monitoramento.tipo,
          null,
          monitoramento.coletadoEm.toIso8601String(),
          null,
          null,
          null,
          null,
          null,
          entry.key,
          entry.value,
        ]);
      }
    }

    for (final publicacaoId in relatorio.publicacoesRefs) {
      rows.add([
        'publicacao',
        relatorio.id,
        publicacaoId,
        publicacaoId,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        'publicacao_ref',
        publicacaoId,
      ]);
    }

    return toCsv(rows);
  }

  static String occurrenceFileBaseName(Occurrence occurrence) {
    return 'ocorrencia_${occurrence.id}';
  }

  static Map<String, dynamic> occurrenceJson(Occurrence occurrence) {
    return occurrence.toMap();
  }

  static String occurrenceCsv(Occurrence occurrence) {
    return toCsv([
      [
        'id',
        'visit_session_id',
        'client_id',
        'type',
        'category',
        'status',
        'description',
        'created_at',
        'lat',
        'long',
        'photo_path',
        'cultivar',
        'data_plantio',
        'estadio_fenologico',
        'tipo_ocorrencia',
        'amostra_solo',
        'recomendacoes',
      ],
      [
        occurrence.id,
        occurrence.visitSessionId,
        occurrence.clientId,
        occurrence.type,
        occurrence.category,
        occurrence.status,
        occurrence.description,
        occurrence.createdAt.toIso8601String(),
        occurrence.lat,
        occurrence.long,
        occurrence.photoPath,
        occurrence.cultivar,
        occurrence.dataPlantio,
        occurrence.estadioFenologico,
        occurrence.tipoOcorrencia,
        occurrence.amostraSolo,
        occurrence.recomendacoes,
      ],
    ]);
  }

  static String toCsv(List<List<Object?>> rows) {
    return rows.map((row) => row.map(_escapeCsv).join(',')).join('\n');
  }

  static String _escapeCsv(Object? value) {
    if (value == null) return '';
    final raw = value is DateTime ? value.toIso8601String() : value.toString();
    if (raw.contains(',') ||
        raw.contains('"') ||
        raw.contains('\n') ||
        raw.contains('\r')) {
      return '"${raw.replaceAll('"', '""')}"';
    }
    return raw;
  }
}
