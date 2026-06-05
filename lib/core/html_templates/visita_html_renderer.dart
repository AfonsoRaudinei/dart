import 'relatorio_html_renderer.dart';

class VisitaHtmlRenderer {
  /// Renderiza T-R1 a partir de um relatório técnico serializado.
  ///
  /// [relatorio] deve seguir o formato de RelatorioTecnico.toJson().
  /// O renderer fica em core/ e não importa tipos de modules/.
  static Future<String> render({
    required Map<String, dynamic> relatorio,
    required String agronomistNome,
    required String clienteNome,
    required Map<String, String> publicacoesTitulos,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantRole,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate('relatorio_visita.html');
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: reportBrandName,
      customLogoPath: reportLogoPath,
      consultantName: agronomistNome,
      consultantRole: consultantRole,
    );

    final status = _string(relatorio['status'], fallback: 'pendente_revisao');
    final title = _string(relatorio['title']);
    final farmName = _string(relatorio['farmName']);
    final titleOuFarm = title.isNotEmpty ? title : farmName;
    final ocorrencias = _listOfMaps(relatorio['ocorrencias']);
    final talhoes = _listOfMaps(relatorio['talhoes']);
    final monitoramentos = _listOfMaps(relatorio['monitoramentos']);
    final fotos = _listOfStrings(relatorio['fotos']);
    final publicacoesRefs = _listOfStrings(relatorio['publicacoesRefs']);

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'status': RelatorioHtmlRenderer.escapeHtml(status),
      'status_label': _statusLabel(status),
      'title_ou_farm_name': RelatorioHtmlRenderer.escapeHtml(titleOuFarm),
      'farm_name': RelatorioHtmlRenderer.escapeHtml(farmName),
      'cliente_nome': RelatorioHtmlRenderer.escapeHtml(clienteNome),
      'agronomist_nome': RelatorioHtmlRenderer.escapeHtml(agronomistNome),
      'period_start_formatado': _formatIsoDateTime(relatorio['periodStart']),
      'period_end_formatado': _formatIsoDateTime(relatorio['periodEnd']),
      'custom_notes': RelatorioHtmlRenderer.escapeHtml(
        _string(relatorio['customNotes']),
      ),
      'ocorrencias_count': ocorrencias.length.toString(),
      'id_curto': RelatorioHtmlRenderer.shortId(_string(relatorio['id'])),
      'gerado_em_formatado': RelatorioHtmlRenderer.geradoEm(),
    });

    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'custom_notes',
      include: _string(relatorio['customNotes']).isNotEmpty,
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'talhoes.length > 0',
      include: talhoes.isNotEmpty,
      truthyHtml: '<div class="talhao-list">${_renderTalhoes(talhoes)}</div>',
      falsyHtml:
          '<div class="empty-section">Nenhum talhão registrado nesta visita.</div>',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'ocorrencias.length > 0',
      include: ocorrencias.isNotEmpty,
      truthyHtml:
          '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Ocorrências Registradas</span>
    </div>
    <div class="ocorrencia-list">${await _renderOcorrencias(ocorrencias)}</div>
    ''',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'monitoramentos.length > 0',
      include: monitoramentos.isNotEmpty,
      truthyHtml:
          '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Monitoramentos</span>
    </div>
    <div class="monitoramento-list">${_renderMonitoramentos(monitoramentos)}</div>
    ''',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'fotos.length > 0',
      include: fotos.isNotEmpty,
      truthyHtml:
          '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Registro Fotográfico</span>
    </div>
    <div class="fotos-grid">${await _renderFotos(fotos)}</div>
    ''',
    );
    tpl = RelatorioHtmlRenderer.resolveIfBlock(
      tpl,
      'publicacoes_refs.length > 0',
      include: publicacoesRefs.isNotEmpty,
      truthyHtml:
          '''
    <div class="section-label">
      <div class="section-label-bar"></div>
      <span class="section-label-text">Publicações Técnicas</span>
    </div>
    <div class="publicacoes-list">${_renderPublicacoes(publicacoesRefs, publicacoesTitulos)}</div>
    ''',
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
  }

  static String _renderTalhoes(List<Map<String, dynamic>> talhoes) {
    if (talhoes.isEmpty) return '';
    final sb = StringBuffer();
    for (final talhao in talhoes) {
      final nome = RelatorioHtmlRenderer.escapeHtml(
        _string(talhao['nomeTalhao']),
      );
      final cultura = RelatorioHtmlRenderer.escapeHtml(
        _string(talhao['cultura']),
      );
      final safra = RelatorioHtmlRenderer.escapeHtml(_string(talhao['safra']));
      final area = _double(talhao['areaHectares']);

      sb.write('''
      <div class="talhao-card">
        <div>
          <div class="talhao-nome">$nome</div>
          <div class="talhao-meta">
            ${cultura.isNotEmpty ? '<span class="talhao-chip">Cultura: $cultura</span>' : ''}
            ${safra.isNotEmpty ? '<span class="talhao-chip">Safra: $safra</span>' : ''}
          </div>
        </div>
        ${area != null ? '<div class="talhao-area">${RelatorioHtmlRenderer.formatHectares(area)}<span class="talhao-area-unit">ha</span></div>' : ''}
      </div>
      ''');
    }
    return sb.toString();
  }

  static Future<String> _renderOcorrencias(
    List<Map<String, dynamic>> ocorrencias,
  ) async {
    if (ocorrencias.isEmpty) return '';
    final sb = StringBuffer();
    for (final ocorrencia in ocorrencias) {
      final fotoB64 = await RelatorioHtmlRenderer.photoPathToBase64(
        _stringOrNull(ocorrencia['fotoPath']),
      );
      final tipo = RelatorioHtmlRenderer.escapeHtml(
        _string(ocorrencia['tipo']),
      );
      final descricao = RelatorioHtmlRenderer.escapeHtml(
        _string(ocorrencia['descricao']),
      );
      final dataHora = _formatIsoDateTime(ocorrencia['registradaEm']);
      final hasLoc = ocorrencia['lat'] != null && ocorrencia['lng'] != null;

      sb.write('''
      <div class="ocorrencia-card">
        <div class="ocorrencia-foto">
          ${fotoB64 != null ? '<img src="$fotoB64" alt="Foto" loading="lazy">' : _fotoPlaceholder()}
        </div>
        <div class="ocorrencia-info">
          <span class="ocorrencia-tipo">$tipo</span>
          <div class="ocorrencia-descricao">$descricao</div>
          <div class="ocorrencia-meta">
            <span class="ocorrencia-meta-item">
              <svg viewBox="0 0 24 24"><path d="M12 2C6.5 2 2 6.5 2 12s4.5 10 10 10 10-4.5 10-10S17.5 2 12 2zm.5 11H8v-2h2.5V7H13v6z"/></svg>
              $dataHora
            </span>
            ${hasLoc ? '<span class="ocorrencia-meta-item"><svg viewBox="0 0 24 24"><path d="M12 2C8.13 2 5 5.13 5 9c0 5.25 7 13 7 13s7-7.75 7-13c0-3.87-3.13-7-7-7zm0 9.5c-1.38 0-2.5-1.12-2.5-2.5s1.12-2.5 2.5-2.5 2.5 1.12 2.5 2.5-1.12 2.5-2.5 2.5z"/></svg>Georreferenciada</span>' : ''}
          </div>
        </div>
      </div>
      ''');
    }
    return sb.toString();
  }

  static String _renderMonitoramentos(
    List<Map<String, dynamic>> monitoramentos,
  ) {
    if (monitoramentos.isEmpty) return '';
    final sb = StringBuffer();
    for (final monitoramento in monitoramentos) {
      final tipo = RelatorioHtmlRenderer.escapeHtml(
        _string(monitoramento['tipo']),
      );
      final data = _formatIsoDateTime(monitoramento['coletadoEm']);
      final dados = _map(monitoramento['dados']);
      final dadosHtml = dados.entries
          .map(
            (entry) =>
                '''
        <div class="dado-item">
          <div class="dado-chave">${RelatorioHtmlRenderer.escapeHtml(entry.key)}</div>
          <div class="dado-valor">${RelatorioHtmlRenderer.escapeHtml(entry.value?.toString())}</div>
        </div>
      ''',
          )
          .join();

      sb.write('''
      <div class="monitoramento-card">
        <div class="monitoramento-header">
          <div class="monitoramento-tipo">$tipo</div>
          <div class="monitoramento-data">$data</div>
        </div>
        <div class="monitoramento-dados">$dadosHtml</div>
      </div>
      ''');
    }
    return sb.toString();
  }

  static Future<String> _renderFotos(List<String> fotos) async {
    if (fotos.isEmpty) return '';
    final sb = StringBuffer();
    for (final path in fotos) {
      final b64 = await RelatorioHtmlRenderer.photoPathToBase64(path);
      if (b64 != null) {
        sb.write('''
        <div class="foto-item">
          <img src="$b64" alt="Foto da visita" loading="lazy">
        </div>
        ''');
      }
    }
    return sb.toString();
  }

  static String _renderPublicacoes(
    List<String> refs,
    Map<String, String> titulos,
  ) {
    if (refs.isEmpty) return '';
    final sb = StringBuffer();
    for (final ref in refs) {
      final titulo = RelatorioHtmlRenderer.escapeHtml(
        titulos[ref] ?? 'Publicação ${RelatorioHtmlRenderer.shortId(ref)}',
      );
      sb.write('''
      <div class="publicacao-badge">
        <svg viewBox="0 0 24 24"><path d="M14 2H6c-1.1 0-1.99.9-1.99 2L4 20c0 1.1.89 2 1.99 2H18c1.1 0 2-.9 2-2V8l-6-6zm2 16H8v-2h8v2zm0-4H8v-2h8v2zm-3-5V3.5L18.5 9H13z"/></svg>
        $titulo
      </div>
      ''');
    }
    return sb.toString();
  }

  static String _fotoPlaceholder() => '''
    <div class="ocorrencia-foto-placeholder">
      <svg viewBox="0 0 24 24" fill="#9CA3AF">
        <path d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"/>
      </svg>
    </div>
  ''';

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

  static String _formatIsoDateTime(Object? value) {
    final raw = _string(value);
    if (raw.isEmpty) return '';
    try {
      return RelatorioHtmlRenderer.formatDateTime(DateTime.parse(raw));
    } catch (_) {
      return raw;
    }
  }

  static String _string(Object? value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString();
    return text.isEmpty ? fallback : text;
  }

  static String? _stringOrNull(Object? value) {
    final text = _string(value);
    return text.isEmpty ? null : text;
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(_string(value).replaceAll(',', '.'));
  }

  static Map<String, dynamic> _map(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return const {};
  }

  static List<Map<String, dynamic>> _listOfMaps(Object? value) {
    if (value is! List) return const [];
    return value
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  static List<String> _listOfStrings(Object? value) {
    if (value is! List) return const [];
    return value.map((item) => item.toString()).toList();
  }
}
