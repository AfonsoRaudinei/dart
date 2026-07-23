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

class _ConsolidatedReportsSection extends ConsumerWidget {
  final DateFormat dateFormat;

  const _ConsolidatedReportsSection({required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relatoriosAsync = ref.watch(_relatoriosTecnicosListProvider);
    final occurrencesAsync = ref.watch(occurrencesListProvider);

    if (relatoriosAsync.isLoading || occurrencesAsync.isLoading) {
      return const _SectionLoading(title: 'Relatórios Consolidados');
    }
    if (relatoriosAsync.hasError) {
      return _SectionError(
        title: 'Relatórios Consolidados',
        onRetry: () => ref.invalidate(_relatoriosTecnicosListProvider),
      );
    }
    if (occurrencesAsync.hasError) {
      return _SectionError(
        title: 'Relatórios Consolidados',
        onRetry: () => ref.invalidate(occurrencesListProvider),
      );
    }

    final relatorios =
        relatoriosAsync.valueOrNull ?? const <RelatorioTecnico>[];
    final occurrences = occurrencesAsync.valueOrNull ?? const <Occurrence>[];
    final nowLabel = dateFormat.format(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _InsetGroupHeader(title: 'Relatórios Consolidados', count: 3),
        _GeneratedReportCard(
          eyebrow: 'Gerado sob demanda',
          title: 'Lista de Ocorrências',
          subtitle: '${occurrences.length} ocorrência(s)',
          date: nowLabel,
          enabled: occurrences.isNotEmpty,
          buildPayload: () => _buildOccurrenceListPayload(ref, occurrences),
        ),
        _GeneratedReportCard(
          eyebrow: 'Gerado sob demanda',
          title: 'Resumo da Propriedade',
          subtitle: _propertySubtitle(relatorios),
          date: nowLabel,
          enabled: relatorios.any((report) => report.talhoes.isNotEmpty),
          buildPayload: () => _buildPropertySummaryPayload(ref, relatorios),
        ),
        _GeneratedReportCard(
          eyebrow: 'Gerado sob demanda',
          title: 'Histórico de Visitas',
          subtitle: '${relatorios.length} visita(s)',
          date: nowLabel,
          enabled: relatorios.isNotEmpty,
          buildPayload: () => _buildVisitHistoryPayload(ref, relatorios),
        ),
      ],
    );
  }

  String _propertySubtitle(List<RelatorioTecnico> relatorios) {
    final farms = relatorios.map((report) => report.farmName).toSet();
    final talhoes = relatorios
        .expand((report) => report.talhoes)
        .map((talhao) => talhao.talhaoId)
        .toSet();
    return '${farms.length} propriedade(s), ${talhoes.length} talhão(ões)';
  }
}

class _MarketingCasesReportsSection extends ConsumerWidget {
  final DateFormat dateFormat;

  const _MarketingCasesReportsSection({required this.dateFormat});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    late final AsyncValue<List<MarketingCase>> casesAsync;
    try {
      casesAsync = ref.watch(marketingCasesProvider);
    } catch (e, st) {
      AppLogger.error(
        'marketingCasesProvider falhou na criação',
        tag: 'RelatoriosScreen',
        error: e,
        stackTrace: st,
      );
      return _SectionError(
        title: 'Marketing Cases',
        onRetry: () => ref.invalidate(marketingCasesProvider),
      );
    }

    final role = ref.watch(currentUserRoleProvider);
    final authorizedAsync = role.isProdutor
        ? ref.watch(authorizedClientIdsProvider)
        : const AsyncValue.data(<String>{});
    final currentUserId = LocalSessionIdentity.resolveUserId();

    return casesAsync.when(
      data: (cases) {
        final authorized =
            authorizedAsync.valueOrNull ?? const <String>{};
        final visible = cases.where((item) {
          if (item.deletadoEm != null) return false;
          if (!role.isProdutor) return true;
          return MarketingCaseVisibility.isVisibleInReports(
            marketingCase: item,
            currentUserId: currentUserId,
            authorizedClientIds: authorized,
          );
        }).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InsetGroupHeader(title: 'Marketing Cases', count: visible.length),
            if (visible.isEmpty)
              _PremiumEmptyState(
                message: 'Nenhum case publicado.',
                ctaLabel: 'Abrir mapa',
                onCta: () => context.go(AppRoutes.map),
              )
            else
              ...visible.map(
                (item) => _GeneratedReportCard(
                  eyebrow: 'Marketing',
                  title: item.produtorFazenda,
                  subtitle: _marketingSubtitle(item),
                  date: dateFormat.format(item.criadoEm.toLocal()),
                  enabled: true,
                  buildPayload: () => _buildMarketingPayload(ref, item),
                ),
              ),
          ],
        );
      },
      loading: () => const _SectionLoading(title: 'Marketing Cases'),
      error: (e, st) {
        AppLogger.error('marketingCasesProvider ERROR', tag: 'RelatoriosScreen', error: e, stackTrace: st);
        return _SectionError(
          title: 'Marketing Cases',
          onRetry: () => ref.invalidate(marketingCasesProvider),
        );
      },
    );
  }

  String _marketingSubtitle(MarketingCase item) {
    return '${_marketingTypeLabel(item)} • ${item.status.toValue()}';
  }

  String _marketingTypeLabel(MarketingCase item) {
    switch (item.tipo.toValue()) {
      case 'antes_depois':
        return 'Antes/Depois';
      case 'avaliacao':
        return 'Avaliação';
      case 'resultado':
      default:
        return 'Resultado';
    }
  }
}

class _GeneratedReportCard extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final String date;
  final bool enabled;
  final Future<_GeneratedReportPayload> Function() buildPayload;

  const _GeneratedReportCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.enabled,
    required this.buildPayload,
  });

  @override
  Widget build(BuildContext context) {
    return _DataCard(
      eyebrow: eyebrow,
      title: title,
      subtitle: enabled ? subtitle : '$subtitle • sem dados',
      date: date,
      statusLabel: enabled ? 'Disponível' : 'Vazio',
      statusColor: enabled ? PremiumTokens.brandGreen : Colors.grey,
      trailing: _AsyncActionMenu(
        tooltip: 'Ações do relatório consolidado',
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
        ],
        onSelected: (value) => _handleAction(context, value),
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String value) async {
    if (!enabled) return;
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
) async {
  final rows = <Map<String, dynamic>>[];
  for (final occurrence in occurrences) {
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
  final html = await OcorrenciaHtmlRenderer.renderLista(
    ocorrencias: rows,
    clienteNome: 'Todos os clientes',
    agronomistNome: branding.consultantName,
    dataVisita: DateTime.now(),
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantRole: branding.consultantRole,
  );

  return _GeneratedReportPayload(
    title: 'Lista de Ocorrências',
    fileBaseName: 'lista_ocorrencias',
    html: html,
    json: {'tipo': 'lista_ocorrencias', 'ocorrencias': rows},
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
      ...occurrences.map(
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
) async {
  final now = DateTime.now();
  final first = relatorios.isNotEmpty ? relatorios.first : null;
  final fieldsById = <String, Map<String, dynamic>>{};
  for (final report in relatorios) {
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
  final html = await PropriedadeHtmlRenderer.renderPropriedade(
    farmId: first?.farmName ?? 'propriedade',
    farmNome: first?.farmName ?? 'Propriedade',
    clienteNome: first?.clientId ?? 'Cliente',
    areaTotal: areaTotal,
    createdAt: first?.createdAt ?? now,
    updatedAt: relatorios.isNotEmpty ? relatorios.last.updatedAt : now,
    fields: fields,
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantName: branding.consultantName,
    consultantRole: branding.consultantRole,
  );

  return _GeneratedReportPayload(
    title: 'Resumo da Propriedade',
    fileBaseName: 'resumo_propriedade',
    html: html,
    json: {
      'tipo': 'resumo_propriedade',
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
) async {
  final rows = relatorios.map(_historyRow).toList();
  final agronomists = {
    for (final report in relatorios) report.agronomistId: report.agronomistId,
  };

  final branding = await _resolveReportBrandingContext(
    ref,
    fallbackConsultantName: 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  final html = await PropriedadeHtmlRenderer.renderHistorico(
    clienteNome: 'Todos os clientes',
    farmName: relatorios.length == 1
        ? relatorios.first.farmName
        : 'Todas as propriedades',
    relatorios: rows,
    agronomistNomes: agronomists,
    reportBrandName: branding.brandName,
    reportLogoPath: branding.logoPath,
    consultantName: branding.consultantName,
    consultantRole: branding.consultantRole,
  );

  return _GeneratedReportPayload(
    title: 'Histórico de Visitas',
    fileBaseName: 'historico_visitas',
    html: html,
    json: {'tipo': 'historico_visitas', 'relatorios': rows},
    csv: ConsultoriaReportExportData.toCsv([
      [
        'id',
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
      ...relatorios.map(
        (report) => [
          report.id,
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
  MarketingCase item,
) async {
  final branding = await _resolveReportBrandingContext(
    ref,
    fallbackConsultantName: item.nomeVendedor ?? 'Equipe técnica',
    fallbackConsultantRole: 'Consultoria',
  );
  final data = {
    ...item.toJson(),
    'avaliacoes': item.avaliacoes.map((bloco) => bloco.toJson()).toList(),
    'report_brand_name': branding.brandName,
    'report_logo_path': branding.logoPath,
    'nome_vendedor': branding.consultantName,
  };
  final html = await MarketingHtmlRenderer.render(data);
  return _GeneratedReportPayload(
    title: 'Marketing ${item.produtorFazenda}',
    fileBaseName: 'marketing_${item.id}',
    html: html,
    json: {'tipo': 'marketing_case', 'case': data},
    csv: ConsultoriaReportExportData.toCsv([
      [
        'id',
        'tipo',
        'produtor_fazenda',
        'produto_utilizado',
        'status',
        'criado_em',
        'lat',
        'lng',
      ],
      [
        item.id,
        item.tipo.toValue(),
        item.produtorFazenda,
        item.produtoUtilizado,
        item.status.toValue(),
        item.criadoEm.toIso8601String(),
        item.lat,
        item.lng,
      ],
    ]),
  );
}
