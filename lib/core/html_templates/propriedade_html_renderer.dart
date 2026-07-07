import 'relatorio_html_renderer.dart';

class PropriedadeHtmlRenderer {
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

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'nome': RelatorioHtmlRenderer.escapeHtml(farmNome),
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'area_total_formatado': RelatorioHtmlRenderer.formatHectares(areaTotal),
      'municipio': RelatorioHtmlRenderer.escapeHtml(municipio),
      'uf': RelatorioHtmlRenderer.escapeHtml(uf),
      'total_fields': fields.length.toString(),
      'area_produtiva_total_formatado': RelatorioHtmlRenderer.formatHectares(
        areaProdutiva,
      ),
      'created_at_formatado': RelatorioHtmlRenderer.formatDate(createdAt),
      'updated_at_formatado': RelatorioHtmlRenderer.formatDate(updatedAt),
      'id_curto': RelatorioHtmlRenderer.shortId(farmId),
      'gerado_em_formatado': RelatorioHtmlRenderer.geradoEm(),
    });

    final fieldsHtml = _renderFields(fields);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'fields.length > 0',
      include: fieldsHtml.isNotEmpty,
      truthyHtml: '<div class="field-list">$fieldsHtml</div>',
      falsyHtml:
          '<div class="empty-state"><div class="empty-state-emoji">🗺️</div><div class="empty-state-text">Nenhum talhão cadastrado para esta fazenda.</div></div>',
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

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'farm_name': RelatorioHtmlRenderer.escapeHtml(farmName),
      'total_visitas': total.toString(),
      'total_publicados': publicados.toString(),
      'total_pendentes': pendentes.toString(),
      'total_ocorrencias_geral': totalOcorrencias.toString(),
      'periodo_inicio': periodoInicio,
      'periodo_fim': periodoFim,
      'gerado_em_formatado': RelatorioHtmlRenderer.geradoEm(),
    });

    final timelineHtml = _renderTimeline(relatorios, agronomistNomes);
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'relatorios.length > 0',
      include: timelineHtml.isNotEmpty,
      truthyHtml: '<div class="timeline">$timelineHtml</div>',
      falsyHtml:
          '<div class="empty-state"><div class="empty-state-emoji">📋</div><div class="empty-state-text">Nenhuma visita registrada para este cliente.</div></div>',
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
  }

  static String _renderFields(List<Map<String, dynamic>> fields) {
    if (fields.isEmpty) return '';
    final sb = StringBuffer();
    for (final f in fields) {
      final nome = RelatorioHtmlRenderer.escapeHtml(f['nome'] as String? ?? '');
      final codigo = f['codigo'] as String?;
      final area = (f['area_produtiva'] as num?)?.toDouble();
      final temBordadura = (f['bordadura_geo'] as String?)?.isNotEmpty ?? false;
      final temCentro = (f['centro_geo'] as String?)?.isNotEmpty ?? false;

      sb.write('''
      <div class="field-card">
        <div class="field-left">
          <div class="field-nome">$nome</div>
          ${codigo != null ? '<div class="field-codigo">#${RelatorioHtmlRenderer.escapeHtml(codigo)}</div>' : ''}
          <div class="field-meta">
            ${temCentro ? '<span class="field-meta-chip sf-location" aria-label="Localização">📍</span>' : ''}
            ${temBordadura ? '<span class="field-meta-chip">🗺️ Com bordadura</span>' : ''}
          </div>
        </div>
        ${area != null ? '<div class="field-area-badge">${RelatorioHtmlRenderer.formatHectares(area)}<span class="field-area-badge-unit">ha</span></div>' : ''}
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
      final statusLabel = _statusLabel(status);
      final title = RelatorioHtmlRenderer.escapeHtml(
        (r['title'] as String?)?.isNotEmpty == true
            ? r['title'] as String
            : r['farm_name'] as String? ?? '',
      );
      final farmName = RelatorioHtmlRenderer.escapeHtml(
        r['farm_name'] as String? ?? '',
      );
      final agronomistId = r['agronomist_id'] as String? ?? '';
      final agronomistNome = RelatorioHtmlRenderer.escapeHtml(
        agronomistNomes[agronomistId] ?? agronomistId,
      );

      final pStart = _parseDate(r['period_start'] as String?);
      final pEnd = _parseDate(r['period_end'] as String?);

      final ocCount = (r['ocorrencias'] as List?)?.length ?? 0;
      final talhCount = (r['talhoes'] as List?)?.length ?? 0;
      final fotoCount = (r['fotos'] as List?)?.length ?? 0;
      final pubCount = (r['publicacoes_refs'] as List?)?.length ?? 0;
      final notes = RelatorioHtmlRenderer.escapeHtml(
        r['custom_notes'] as String?,
      );

      sb.write('''
      <div class="timeline-item">
        <div class="timeline-dot $status"></div>
        <div class="visita-card">
          <div class="visita-card-top">
            <div class="visita-titulo">$title</div>
            <span class="status-badge $status">$statusLabel</span>
          </div>
          <div class="visita-periodo">
            <svg viewBox="0 0 24 24"><path d="M9 11H7v2h2v-2zm4 0h-2v2h2v-2zm4 0h-2v2h2v-2zm2-7h-1V2h-2v2H8V2H6v2H5c-1.11 0-1.99.9-1.99 2L3 20c0 1.1.89 2 2 2h14c1.1 0 2-.9 2-2V6c0-1.1-.9-2-2-2zm0 16H5V9h14v11z"/></svg>
            <span class="visita-periodo-text">
              <strong>$pStart</strong>
              ${pEnd != pStart ? ' → <strong>$pEnd</strong>' : ''}
            </span>
          </div>
          <div class="visita-meta">
            <span class="visita-meta-item"><svg viewBox="0 0 24 24"><path d="M12 12c2.21 0 4-1.79 4-4s-1.79-4-4-4-4 1.79-4 4 1.79 4 4 4zm0 2c-2.67 0-8 1.34-8 4v2h16v-2c0-2.66-5.33-4-8-4z"/></svg><strong>$agronomistNome</strong></span>
            <span class="visita-meta-item"><svg viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>$farmName</span>
          </div>
          <div class="visita-counters">
            ${ocCount > 0 ? '<span class="counter-chip">🔍 $ocCount ocorrências</span>' : ''}
            ${talhCount > 0 ? '<span class="counter-chip">🗺️ $talhCount talhões</span>' : ''}
            ${fotoCount > 0 ? '<span class="counter-chip">📷 $fotoCount fotos</span>' : ''}
            ${pubCount > 0 ? '<span class="counter-chip">📄 $pubCount publicações</span>' : ''}
          </div>
          ${notes.isNotEmpty ? '<div class="visita-notes">$notes</div>' : ''}
        </div>
      </div>
      ''');
    }
    return sb.toString();
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'publicado':
        return 'Publicado';
      case 'arquivado':
        return 'Arquivado';
      default:
        return 'Em Revisão';
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
