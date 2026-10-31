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

class _GeneratedReportCard extends ConsumerStatefulWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String date;
  final bool enabled;
  final Future<_GeneratedReportPayload> Function() buildPayload;
  final HtmlReportViewerActions? viewerActions;
  final String? statusLabel;
  final Color? statusColor;
  final Widget? leading;

  const _GeneratedReportCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.enabled,
    required this.buildPayload,
    this.viewerActions,
    this.statusLabel,
    this.statusColor,
    this.leading,
  });

  @override
  ConsumerState<_GeneratedReportCard> createState() =>
      _GeneratedReportCardState();
}

class _GeneratedReportCardState extends ConsumerState<_GeneratedReportCard> {
  Future<void> _openPreview(BuildContext context) async {
    final bodyBuilder = ref.read(htmlReportViewerBodyBuilderProvider);
    try {
      final payload = await widget.buildPayload();
      if (!context.mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => HtmlReportViewer(
            title: payload.title,
            htmlContent: payload.html,
            fileBaseName: payload.fileBaseName,
            jsonData: payload.json,
            csvData: payload.csv,
            bodyBuilder: bodyBuilder,
            actions: widget.viewerActions,
          ),
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              userFacingError(e, action: 'Erro ao abrir relatório'),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _AsyncDataCard(
      leading: widget.leading,
      eyebrow: widget.eyebrow,
      title: widget.title,
      subtitle: widget.enabled
          ? widget.subtitle
          : '${widget.subtitle} • sem dados',
      date: widget.date,
      statusLabel:
          widget.statusLabel ?? (widget.enabled ? 'Disponível' : 'Vazio'),
      statusColor: widget.statusColor ??
          (widget.enabled ? PremiumTokens.brandGreen : Colors.grey),
      onTapAsync: widget.enabled ? () => _openPreview(context) : null,
    );
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
        // TalhaoVisitado não tem código humano; talhaoId é UUID interno.
        'codigo': '',
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
      ['nome', 'area_ha', 'cultura', 'safra'],
      ...fields.map(
        (field) => [
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

  final branding = await _resolveReportBrandingContext(
    ref,
    fallbackConsultantName: 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  final currentUserId = await _resolveCurrentUserProfileId(ref);
  // Só o usuário atual tem nome resolvível; outros agrônomos ficam sem
  // entrada para nunca imprimir UUID no HTML.
  final agronomists = <String, String>{
    for (final report in sorted)
      if (report.agronomistId.trim().isNotEmpty &&
          report.agronomistId.trim() == currentUserId)
        report.agronomistId: branding.consultantName,
  };
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

Future<String> _resolveCurrentUserProfileId(WidgetRef ref) async {
  try {
    final profile = await ref.read(currentUserProfileProvider.future);
    return profile?.id.trim() ?? '';
  } catch (_) {
    return '';
  }
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

Future<String> _buildOccurrenceReportHtml(
  WidgetRef ref,
  Occurrence occurrence, {
  bool asFragment = false,
}) {
  return buildOccurrenceReportHtml(
    ref,
    occurrence,
    asFragment: asFragment,
  );
}

List<_CombinedReportEvent> _sortCombinedReportEvents(
  List<_CombinedReportEvent> events,
) {
  final sorted = [...events];
  sorted.sort((a, b) {
    final byDate = a.occurredAt.compareTo(b.occurredAt);
    if (byDate != 0) return byDate;
    return CombinadoHtmlRenderer.kindRank(
      a.kind,
    ).compareTo(CombinadoHtmlRenderer.kindRank(b.kind));
  });
  return sorted;
}

Future<_GeneratedReportPayload> _buildCombinedReportPayload(
  WidgetRef ref, {
  required String clientId,
  required List<_CombinedReportEvent> selected,
  String? combinadoId,
}) async {
  final branding = await _resolveReportBrandingContext(
    ref,
    fallbackConsultantName: 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  final clienteNome = await _resolveClienteNomeForId(ref, clientId);
  final sortedEvents = _sortCombinedReportEvents(selected);
  final chapters = <CombinadoHtmlChapter>[];
  for (final event in sortedEvents) {
    chapters.add(
      CombinadoHtmlChapter(
        kind: event.kind,
        occurredAt: event.occurredAt,
        title: event.title,
        fragmentHtml: await event.buildFragment(ref),
      ),
    );
  }
  final html = await CombinadoHtmlRenderer.render(
    clienteNome: clienteNome.isNotEmpty ? clienteNome : 'Produtor',
    chapters: chapters,
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantName: branding.consultantName,
    consultantRole: branding.consultantRole,
  );
  final emitidoEm = DateTime.now().toUtc();
  final periodoDatas = sortedEvents.map((event) => event.occurredAt).toList();
  final periodoInicio = periodoDatas.isEmpty ? null : periodoDatas.first;
  final periodoFim = periodoDatas.isEmpty ? null : periodoDatas.last;
  return _GeneratedReportPayload(
    title: 'Relatório combinado — $clienteNome',
    fileBaseName: 'relatorio_combinado_$clientId',
    html: html,
    json: {
      'tipo': 'relatorio_combinado',
      'packVersion': 1,
      if (combinadoId != null) 'combinadoId': combinadoId,
      'clientId': clientId,
      'clienteNome': clienteNome,
      'emitidoEm': emitidoEm.toIso8601String(),
      'periodo': {
        if (periodoInicio != null) 'inicio': periodoInicio.toIso8601String(),
        if (periodoFim != null) 'fim': periodoFim.toIso8601String(),
      },
      'capitulos': [
        for (var i = 0; i < sortedEvents.length; i++)
          {
            'key': sortedEvents[i].key,
            'anchorId': CombinadoHtmlRenderer.chapterAnchorId(i + 1),
            'kind': sortedEvents[i].kind,
            'kindLabel': CombinadoHtmlRenderer.kindLabel(sortedEvents[i].kind),
            'title': sortedEvents[i].title,
            'subtitle': sortedEvents[i].subtitle,
            'occurredAt': sortedEvents[i].occurredAt.toIso8601String(),
          },
      ],
    },
    csv: ConsultoriaReportExportData.toCsv([
      [
        'anchor_id',
        'key',
        'kind',
        'kind_label',
        'titulo',
        'subtitulo',
        'occurred_at',
      ],
      for (var i = 0; i < sortedEvents.length; i++)
        [
          CombinadoHtmlRenderer.chapterAnchorId(i + 1),
          sortedEvents[i].key,
          sortedEvents[i].kind,
          CombinadoHtmlRenderer.kindLabel(sortedEvents[i].kind),
          sortedEvents[i].title,
          sortedEvents[i].subtitle,
          sortedEvents[i].occurredAt.toIso8601String(),
        ],
    ]),
  );
}
