part of 'relatorios_page.dart';

class _GeneratedReportPayload {
  final String title;
  final String fileBaseName;
  final String html;
  final Map<String, dynamic> json;
  final String csv;

  const _GeneratedReportPayload({
    required this.title,
    required this.fileBaseName,
    required this.html,
    required this.json,
    required this.csv,
  });

  ReportExportPayload toExportPayload() {
    return ReportExportPayload(
      title: title,
      html: html,
      fileBaseName: fileBaseName,
      json: json,
      csv: csv,
    );
  }
}

class _GeneratedReportCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String date;
  final bool enabled;
  final Future<_GeneratedReportPayload> Function() buildPayload;
  final String menuTooltip;
  final String? statusLabel;
  final Color? statusColor;
  final VoidCallback? onEdit;
  final VoidCallback? onViewLocation;
  final Future<void> Function()? onPublish;
  final Future<void> Function()? onDelete;

  const _GeneratedReportCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.enabled,
    required this.buildPayload,
    this.menuTooltip = 'Ações do relatório consolidado',
    this.statusLabel,
    this.statusColor,
    this.onEdit,
    this.onViewLocation,
    this.onPublish,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return _DataCard(
      eyebrow: eyebrow,
      title: title,
      subtitle: enabled ? subtitle : '$subtitle • sem dados',
      date: date,
      statusLabel: statusLabel ?? (enabled ? 'Disponível' : 'Vazio'),
      statusColor:
          statusColor ?? (enabled ? PremiumTokens.brandGreen : Colors.grey),
      trailing: _AsyncActionMenu(
        tooltip: menuTooltip,
        itemBuilder: (context) => [
          PopupMenuItem(
            value: 'html',
            enabled: enabled,
            child: const Text('Pré-visualizar HTML'),
          ),
          PopupMenuItem(
            value: 'export',
            enabled: enabled,
            child: const Text('Exportar'),
          ),
          if (onPublish != null)
            PopupMenuItem(
              value: 'publish',
              enabled: enabled,
              child: const Text('Publicar'),
            ),
          if (onEdit != null)
            PopupMenuItem(
              value: 'edit',
              enabled: enabled,
              child: const Text('Editar'),
            ),
          if (onViewLocation != null)
            PopupMenuItem(
              value: 'location',
              enabled: enabled,
              child: const Text('Ver Localização'),
            ),
          if (onDelete != null)
            const PopupMenuItem(
              value: 'delete',
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
        ],
        onSelected: (value) => _handleAction(context, value),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    if (!enabled && value != 'delete') return;
    if (value == 'edit') {
      onEdit?.call();
      return;
    }
    if (value == 'publish') {
      final publish = onPublish;
      if (publish != null) await publish();
      return;
    }
    if (value == 'location') {
      onViewLocation?.call();
      return;
    }
    if (value == 'delete') {
      final delete = onDelete;
      if (delete != null) await delete();
      return;
    }
    final payload = await buildPayload();
    if (!context.mounted) return;

    switch (value) {
      case 'html':
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => HtmlReportViewer(
              title: payload.title,
              htmlContent: payload.html,
              fileBaseName: payload.fileBaseName,
              jsonData: payload.json,
              csvData: payload.csv,
            ),
          ),
        );
        return;
      case 'export':
        await _export(context, ReportExportFormat.html, payload);
        return;
    }
  }

  Future<void> _export(
    BuildContext context,
    ReportExportFormat format,
    _GeneratedReportPayload payload,
  ) async {
    final shareOrigin = resolveSharePositionOrigin(context);
    await const ReportExportService().export(
      format,
      payload.toExportPayload(),
      sharePositionOrigin: shareOrigin,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Exportação iniciada.')));
  }
}

Future<_GeneratedReportPayload> _buildOccurrenceListPayload(
  WidgetRef ref,
  List<Occurrence> occurrences,
  String clientId,
) async {
  final sorted = _sortOccurrencesByCreatedAt(occurrences);
  final rows = <Map<String, dynamic>>[];
  for (final occurrence in sorted) {
    final data = occurrence.toMap();
    data['foto_base64'] =
        await RelatorioHtmlRenderer.photoPathToBase64(occurrence.photoPath) ??
        '';
    rows.add(data);
  }

  final branding = await _resolveReportBrandingContext(
    ref,
    fallbackConsultantName: 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  final clienteNome = await _resolveClienteNomeForId(ref, clientId);
  final html = await OcorrenciaHtmlRenderer.renderLista(
    ocorrencias: rows,
    clienteNome: clienteNome,
    agronomistNome: branding.consultantName,
    dataVisita: DateTime.now(),
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantRole: branding.consultantRole,
  );

  return _GeneratedReportPayload(
    title: 'Lista de Ocorrências — $clienteNome',
    fileBaseName: 'lista_ocorrencias_$clientId',
    html: html,
    json: {
      'tipo': 'lista_ocorrencias',
      'clientId': clientId,
      'clienteNome': clienteNome,
      'ocorrencias': rows,
    },
    csv: ConsultoriaReportExportData.toCsv([
      [
        'id',
        'tipo',
        'categoria',
        'status',
        'descricao',
        'cliente_id',
        'created_at',
        'lat',
        'long',
      ],
      ...sorted.map(
        (item) => [
          item.id,
          item.type,
          item.category,
          item.status,
          item.description,
          item.clientId,
          item.createdAt.toIso8601String(),
          item.lat,
          item.long,
        ],
      ),
    ]),
  );
}

Future<_GeneratedReportPayload> _buildPropertySummaryPayload(
  WidgetRef ref,
  List<RelatorioTecnico> relatorios,
  String clientId,
) async {
  final now = DateTime.now();
  final sorted = _sortRelatoriosByPeriodStart(relatorios);
  final first = sorted.isNotEmpty ? sorted.first : null;
  final fieldsById = <String, Map<String, dynamic>>{};
  for (final report in sorted) {
    for (final talhao in report.talhoes) {
      fieldsById[talhao.talhaoId] = {
        'nome': talhao.nomeTalhao,
        'codigo': talhao.talhaoId,
        'area_produtiva': talhao.areaHectares,
        'centro_geo': '',
        'bordadura_geo': '',
        'cultura': talhao.cultura,
        'safra': talhao.safra,
      };
    }
  }
  final fields = fieldsById.values.toList();
  final areaTotal = fields
      .map((field) => (field['area_produtiva'] as num?)?.toDouble() ?? 0.0)
      .fold<double>(0, (total, area) => total + area);

  final branding = await _resolveReportBrandingContext(
    ref,
    fallbackConsultantName: 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  final clienteNome = await _resolveClienteNomeForId(ref, clientId);
  final html = await PropriedadeHtmlRenderer.renderPropriedade(
    farmId: first?.farmName ?? 'propriedade',
    farmNome: first?.farmName ?? 'Propriedade',
    clienteNome: clienteNome,
    areaTotal: areaTotal,
    createdAt: first?.createdAt ?? now,
    updatedAt: sorted.isNotEmpty ? sorted.first.updatedAt : now,
    fields: fields,
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantName: branding.consultantName,
    consultantRole: branding.consultantRole,
  );

  return _GeneratedReportPayload(
    title: 'Resumo da Propriedade — $clienteNome',
    fileBaseName: 'resumo_propriedade_$clientId',
    html: html,
    json: {
      'tipo': 'resumo_propriedade',
      'clientId': clientId,
      'clienteNome': clienteNome,
      'farmName': first?.farmName,
      'areaTotal': areaTotal,
      'fields': fields,
    },
    csv: ConsultoriaReportExportData.toCsv([
      ['talhao_id', 'nome', 'area_ha', 'cultura', 'safra'],
      ...fields.map(
        (field) => [
          field['codigo'],
          field['nome'],
          field['area_produtiva'],
          field['cultura'],
          field['safra'],
        ],
      ),
    ]),
  );
}

Future<_GeneratedReportPayload> _buildVisitHistoryPayload(
  WidgetRef ref,
  List<RelatorioTecnico> relatorios,
  String clientId,
) async {
  final sorted = _sortRelatoriosByPeriodStart(relatorios);
  final rows = sorted.map(_historyRow).toList();
  final agronomists = {
    for (final report in sorted) report.agronomistId: report.agronomistId,
  };

  final branding = await _resolveReportBrandingContext(
    ref,
    fallbackConsultantName: 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  final clienteNome = await _resolveClienteNomeForId(ref, clientId);
  final html = await PropriedadeHtmlRenderer.renderHistorico(
    clienteNome: clienteNome,
    farmName: sorted.length == 1
        ? sorted.first.farmName
        : 'Todas as propriedades',
    relatorios: rows,
    agronomistNomes: agronomists,
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantName: branding.consultantName,
    consultantRole: branding.consultantRole,
  );

  return _GeneratedReportPayload(
    title: 'Histórico de Visitas — $clienteNome',
    fileBaseName: 'historico_visitas_$clientId',
    html: html,
    json: {
      'tipo': 'historico_visitas',
      'clientId': clientId,
      'clienteNome': clienteNome,
      'relatorios': rows,
    },
    csv: ConsultoriaReportExportData.toCsv([
      [
        'id',
        'client_id',
        'titulo',
        'fazenda',
        'status',
        'inicio',
        'fim',
        'ocorrencias',
        'talhoes',
        'fotos',
        'publicacoes',
      ],
      ...sorted.map(
        (report) => [
          report.id,
          report.clientId,
          report.title ?? report.farmName,
          report.farmName,
          report.status.name,
          report.periodStart.toIso8601String(),
          report.periodEnd.toIso8601String(),
          report.ocorrencias.length,
          report.talhoes.length,
          report.fotos.length,
          report.publicacoesRefs.length,
        ],
      ),
    ]),
  );
}

Map<String, dynamic> _historyRow(RelatorioTecnico report) {
  return {
    'id': report.id,
    'client_id': report.clientId,
    'status': report.status.name,
    'title': report.title,
    'farm_name': report.farmName,
    'agronomist_id': report.agronomistId,
    'period_start': report.periodStart.toIso8601String(),
    'period_end': report.periodEnd.toIso8601String(),
    'ocorrencias': report.ocorrencias.map((item) => item.toJson()).toList(),
    'talhoes': report.talhoes.map((item) => item.toJson()).toList(),
    'fotos': report.fotos,
    'publicacoes_refs': report.publicacoesRefs,
    'custom_notes': report.customNotes,
  };
}

Future<_GeneratedReportPayload> _buildMarketingPayload(
  WidgetRef ref,
  MarketingCaseReportSnapshot item,
) async {
  final branding = await _resolveReportBrandingContext(
    ref,
    fallbackConsultantName: item.nomeVendedor ?? 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  final bundle = await ref.read(marketingCaseReportsLookupProvider).buildExportBundle(
    item.id,
    fallbackConsultantName: item.nomeVendedor ?? 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantName: branding.consultantName,
    consultantRole: branding.consultantRole,
  );
  return _GeneratedReportPayload(
    title: bundle.title,
    fileBaseName: bundle.fileBaseName,
    html: bundle.html,
    json: bundle.json,
    csv: bundle.csv,
  );
}
