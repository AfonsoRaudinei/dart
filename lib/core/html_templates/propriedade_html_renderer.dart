import 'relatorio_html_renderer.dart';

class PropriedadeHtmlRenderer {
  static final _rawIdPattern = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  // ─── T-07: Resumo da Propriedade ─────────────────────────────────
  static Future<String> renderPropriedade({
    required String farmId,
    required String farmNome,
    required String clienteNome,
    double? areaTotal,
    String? municipio,
    String? uf,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<Map<String, dynamic>> fields,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantName,
    String? consultantRole,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'resumo_propriedade.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: reportBrandName,
      customLogoPath: reportLogoPath,
      consultantName: consultantName,
      consultantRole: consultantRole,
    );

    final areaProdutiva = fields
        .map((f) => (f['area_produtiva'] as num?)?.toDouble() ?? 0.0)
        .fold<double>(0, (a, b) => a + b);
    final localizacao = [municipio, uf]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .map(RelatorioHtmlRenderer.escapeHtml)
        .join(' · ');
    final contextoLinha = [
      if (clienteNome.trim().isNotEmpty)
        RelatorioHtmlRenderer.escapeHtml(clienteNome.trim()),
      if (localizacao.isNotEmpty) localizacao,
    ].join(' · ');
    final consultant = consultantName?.trim() ?? '';
    final role = consultantRole?.trim() ?? '';

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'nome': RelatorioHtmlRenderer.escapeHtml(farmNome),
      'contexto_linha': contextoLinha,
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'localizacao': localizacao,
      'area_total_formatado': RelatorioHtmlRenderer.formatHectares(areaTotal),
      'total_fields': fields.length.toString(),
      'total_fields_label': fields.length == 1 ? 'talhão' : 'talhões',
      'area_produtiva_total_formatado': RelatorioHtmlRenderer.formatHectares(
        areaProdutiva,
      ),
      'created_at_formatado': RelatorioHtmlRenderer.formatDate(createdAt),
      'updated_at_formatado': RelatorioHtmlRenderer.formatDate(updatedAt),
      'consultant_nome': RelatorioHtmlRenderer.escapeHtml(consultant),
      'consultant_role': RelatorioHtmlRenderer.escapeHtml(role),
      'emitido_em': RelatorioHtmlRenderer.formatDate(DateTime.now()),
    });

    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'contexto_linha',
      include: contextoLinha.isNotEmpty,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'area_total',
      include: areaTotal != null,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'cliente_nome',
      include: clienteNome.trim().isNotEmpty,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'localizacao',
      include: localizacao.isNotEmpty,
    );
    tpl = _resolveSignature(tpl, consultant: consultant, role: role);

    final fieldsHtml = _renderFields(fields);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'fields.length > 0',
      include: fieldsHtml.isNotEmpty,
      truthyHtml: '<div class="sf-sheet field-list">$fieldsHtml</div>',
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
  }

  // ─── T-08: Histórico de Visitas ──────────────────────────────────
  static Future<String> renderHistorico({
    required String clienteNome,
    String? farmName,
    required List<Map<String, dynamic>> relatorios,
    required Map<String, String> agronomistNomes,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantName,
    String? consultantRole,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'historico_visitas.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: reportBrandName,
      customLogoPath: reportLogoPath,
      consultantName: consultantName,
      consultantRole: consultantRole,
    );

    final total = relatorios.length;
    final publicados = relatorios
        .where((r) => r['status'] == 'publicado')
        .length;
    final pendentes = relatorios
        .where((r) => r['status'] == 'pendente_revisao')
        .length;

    var totalOcorrencias = 0;
    for (final r in relatorios) {
      final list = r['ocorrencias'] as List?;
      totalOcorrencias += list?.length ?? 0;
    }

    final datas =
        relatorios
            .map((r) => r['period_start'] as String?)
            .where((d) => d != null)
            .map((d) => DateTime.tryParse(d!))
            .where((d) => d != null)
            .cast<DateTime>()
            .toList()
          ..sort();

    final periodoInicio = datas.isNotEmpty
        ? RelatorioHtmlRenderer.formatDate(datas.first)
        : '';
    final periodoFim = datas.isNotEmpty
        ? RelatorioHtmlRenderer.formatDate(datas.last)
        : '';
    final periodo = periodoInicio.isEmpty
        ? ''
        : periodoInicio == periodoFim
        ? periodoInicio
        : '$periodoInicio – $periodoFim';
    final contextoLinha = [
      if (farmName?.trim().isNotEmpty == true)
        RelatorioHtmlRenderer.escapeHtml(farmName!.trim()),
      if (periodo.isNotEmpty) periodo,
    ].join(' · ');
    final consultant = consultantName?.trim() ?? '';
    final role = consultantRole?.trim() ?? '';

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'contexto_linha': contextoLinha,
      'total_visitas': total.toString(),
      'total_visitas_label': total == 1 ? 'visita' : 'visitas',
      'total_publicados': publicados.toString(),
      'total_publicados_label': publicados == 1 ? 'publicada' : 'publicadas',
      'total_pendentes': pendentes.toString(),
      'total_ocorrencias_geral': totalOcorrencias.toString(),
      'total_ocorrencias_label': totalOcorrencias == 1
          ? 'ocorrência'
          : 'ocorrências',
      'consultant_nome': RelatorioHtmlRenderer.escapeHtml(consultant),
      'consultant_role': RelatorioHtmlRenderer.escapeHtml(role),
      'emitido_em': RelatorioHtmlRenderer.formatDate(DateTime.now()),
    });

    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'contexto_linha',
      include: contextoLinha.isNotEmpty,
    );
    tpl = _resolveSignature(tpl, consultant: consultant, role: role);

    final timelineHtml = _renderTimeline(relatorios, agronomistNomes);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'relatorios.length > 0',
      include: timelineHtml.isNotEmpty,
      truthyHtml: '<div class="sf-sheet timeline">$timelineHtml</div>',
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
  }

  static String _resolveSignature(
    String tpl, {
    required String consultant,
    required String role,
  }) {
    var result = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'consultant_nome',
      include: consultant.isNotEmpty,
    );
    result = RelatorioHtmlRenderer.resolveIfBlock(
      result,
      'consultant_role',
      include: role.isNotEmpty,
    );
    return result;
  }

  static String _renderFields(List<Map<String, dynamic>> fields) {
    if (fields.isEmpty) return '';
    final sb = StringBuffer();
    for (final f in fields) {
      final nome = RelatorioHtmlRenderer.escapeHtml(f['nome'] as String? ?? '');
      final codigo = _readableText(f['codigo']);
      final cultura = _readableText(f['cultura']);
      final safra = _readableText(f['safra']);
      final area = (f['area_produtiva'] as num?)?.toDouble();
      final temBordadura = (f['bordadura_geo'] as String?)?.isNotEmpty ?? false;
      final temCentro = (f['centro_geo'] as String?)?.isNotEmpty ?? false;

      final sub = [
        if (codigo != null)
          'Código ${RelatorioHtmlRenderer.escapeHtml(codigo)}',
        if (cultura != null)
          'Cultura: ${RelatorioHtmlRenderer.escapeHtml(cultura)}',
        if (safra != null) 'Safra: ${RelatorioHtmlRenderer.escapeHtml(safra)}',
        if (temCentro) 'Ponto registrado no mapa',
        if (temBordadura) 'Com bordadura',
      ].join(' · ');

      sb.write('''
      <div class="sf-row field-row">
        <span class="sf-row-label"><span class="sf-item-title">$nome</span>${sub.isNotEmpty ? '<span class="sf-row-sub">$sub</span>' : ''}</span>
        ${area != null ? '<span class="sf-row-value">${RelatorioHtmlRenderer.formatHectares(area)} ha</span>' : ''}
      </div>
      ''');
    }
    return sb.toString();
  }

  static String _renderTimeline(
    List<Map<String, dynamic>> relatorios,
    Map<String, String> agronomistNomes,
  ) {
    final sb = StringBuffer();
    for (final r in relatorios) {
      final status = r['status'] as String? ?? 'pendente_revisao';
      final titleRaw = (r['title'] as String?)?.isNotEmpty == true
          ? r['title'] as String
          : r['farm_name'] as String? ?? '';
      final title = RelatorioHtmlRenderer.escapeHtml(titleRaw);
      final farmName = _readableText(r['farm_name']);
      final agronomistId = r['agronomist_id'] as String? ?? '';
      final agronomistNome = _readableText(
        agronomistNomes[agronomistId] ?? agronomistId,
      );

      final pStart = _parseDate(r['period_start'] as String?);
      final pEnd = _parseDate(r['period_end'] as String?);
      final periodo = pEnd.isEmpty || pEnd == pStart
          ? pStart
          : '$pStart – $pEnd';

      final ocCount = (r['ocorrencias'] as List?)?.length ?? 0;
      final talhCount = (r['talhoes'] as List?)?.length ?? 0;
      final fotoCount = (r['fotos'] as List?)?.length ?? 0;
      final pubCount = (r['publicacoes_refs'] as List?)?.length ?? 0;
      final notes = RelatorioHtmlRenderer.escapeHtml(
        (r['custom_notes'] as String?)?.trim(),
      );

      final meta = [
        if (periodo.isNotEmpty) periodo,
        if (agronomistNome != null)
          RelatorioHtmlRenderer.escapeHtml(agronomistNome),
        if (farmName != null && farmName != titleRaw.trim())
          RelatorioHtmlRenderer.escapeHtml(farmName),
      ];
      final counters = [
        if (ocCount > 0) _plural(ocCount, 'ocorrência', 'ocorrências'),
        if (talhCount > 0) _plural(talhCount, 'talhão', 'talhões'),
        if (fotoCount > 0) _plural(fotoCount, 'foto', 'fotos'),
        if (pubCount > 0) _plural(pubCount, 'publicação', 'publicações'),
      ];

      sb.write('''
      <div class="sf-item visita-row">
        <div class="sf-item-body">
          <div class="sf-item-head">
            <span class="sf-item-title">$title</span>
            <span class="sf-status"><span class="sf-dot ${_statusDot(status)}"></span>${_statusLabel(status)}</span>
          </div>
          ${meta.isEmpty ? '' : '<span class="sf-caption">${meta.join(' · ')}</span>'}
          ${counters.isEmpty ? '' : '<span class="sf-caption">${counters.join(' · ')}</span>'}
          ${notes.isEmpty ? '' : '<p class="sf-prose">$notes</p>'}
        </div>
      </div>
      ''');
    }
    return sb.toString();
  }

  /// Texto exibível; descarta vazio e UUID cru (ids não são informação).
  static String? _readableText(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || _rawIdPattern.hasMatch(text)) return null;
    return text;
  }

  static String _plural(int count, String singular, String plural) {
    return '$count ${count == 1 ? singular : plural}';
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'publicado':
        return 'Publicado';
      case 'arquivado':
        return 'Arquivado';
      default:
        return 'Em revisão';
    }
  }

  static String _statusDot(String status) {
    switch (status) {
      case 'publicado':
        return 'ok';
      case 'arquivado':
        return 'draft';
      default:
        return 'media';
    }
  }

  static String _parseDate(String? iso) {
    if (iso == null) return '';
    try {
      return RelatorioHtmlRenderer.formatDate(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }
}
