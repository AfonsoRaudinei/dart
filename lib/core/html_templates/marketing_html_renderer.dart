import 'relatorio_html_renderer.dart';

class MarketingHtmlRenderer {
  /// Renderiza o HTML correto para o tipo do case.
  ///
  /// [data] = MarketingCase.toMap()/toJson() convertido pelo chamador.
  static Future<String> render(Map<String, dynamic> data) async {
    switch (data['tipo'] as String? ?? 'resultado') {
      case 'resultado':
        return _renderResultado(data);
      case 'antes_depois':
        return _renderAntesDepois(data);
      case 'avaliacao':
        return _renderAvaliacao(data);
      default:
        return _renderResultado(data);
    }
  }

  static Future<String> _renderResultado(Map<String, dynamic> data) async {
    final tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_resultado.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: data['report_brand_name'] as String?,
      customLogoPath: data['report_logo_path'] as String?,
      consultantName: data['nome_vendedor'] as String?,
      consultantRole: 'Consultoria',
    );
    final fotoPrincipalUrl = data['foto_principal_url'] as String?;
    final foto = await RelatorioHtmlRenderer.photoPathToBase64(
      fotoPrincipalUrl,
    );

    final html = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'produtor_fazenda': RelatorioHtmlRenderer.escapeHtml(
        data['produtor_fazenda'] as String? ?? '',
      ),
      'produto_utilizado': RelatorioHtmlRenderer.escapeHtml(
        data['produto_utilizado'] as String? ?? '',
      ),
      'localizacao_texto': RelatorioHtmlRenderer.escapeHtml(
        data['localizacao_texto'] as String? ?? '',
      ),
      'visibilidade': data['visibilidade'] as String? ?? '',
      'foto_principal_url': foto ?? fotoPrincipalUrl ?? '',
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': data['produtividade_unidade'] as String? ?? '',
      'quantidade_produzida': data['quantidade_produzida']?.toString() ?? '',
      'economia_gerada': RelatorioHtmlRenderer.escapeHtml(
        data['economia_gerada'] as String? ?? '',
      ),
      'roi_calculado': data['roi_calculado']?.toString() ?? '',
      'roi_investimento': data['roi_investimento']?.toString() ?? '',
      'roi_retorno': data['roi_retorno']?.toString() ?? '',
      'descricao': RelatorioHtmlRenderer.escapeHtml(
        data['descricao'] as String? ?? '',
      ),
      'lat': data['lat']?.toString() ?? '',
      'lng': data['lng']?.toString() ?? '',
      'nome_vendedor': RelatorioHtmlRenderer.escapeHtml(
        data['nome_vendedor'] as String? ?? '',
      ),
      'nome_vendedor_inicial': _inicial(data['nome_vendedor'] as String?),
      'telefone_vendedor': RelatorioHtmlRenderer.escapeHtml(
        data['telefone_vendedor'] as String? ?? '',
      ),
      'criado_em_formatado': _parseDate(data['criado_em'] as String?),
      'status': data['status'] as String? ?? '',
    });
    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(html);
  }

  static Future<String> _renderAntesDepois(Map<String, dynamic> data) async {
    final tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_antes_depois.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: data['report_brand_name'] as String?,
      customLogoPath: data['report_logo_path'] as String?,
      consultantName: data['nome_vendedor'] as String?,
      consultantRole: 'Consultoria',
    );

    final html = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'produtor_fazenda': RelatorioHtmlRenderer.escapeHtml(
        data['produtor_fazenda'] as String? ?? '',
      ),
      'produto_utilizado': RelatorioHtmlRenderer.escapeHtml(
        data['produto_utilizado'] as String? ?? '',
      ),
      'localizacao_texto': RelatorioHtmlRenderer.escapeHtml(
        data['localizacao_texto'] as String? ?? '',
      ),
      'visibilidade': data['visibilidade'] as String? ?? '',
      'foto_antes_url': data['foto_antes_url'] as String? ?? '',
      'foto_depois_url': data['foto_depois_url'] as String? ?? '',
      'ganho_produtividade': RelatorioHtmlRenderer.escapeHtml(
        data['ganho_produtividade'] as String? ?? '',
      ),
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': data['produtividade_unidade'] as String? ?? '',
      'economia_gerada': RelatorioHtmlRenderer.escapeHtml(
        data['economia_gerada'] as String? ?? '',
      ),
      'descricao': RelatorioHtmlRenderer.escapeHtml(
        data['descricao'] as String? ?? '',
      ),
      'lat': data['lat']?.toString() ?? '',
      'lng': data['lng']?.toString() ?? '',
      'nome_vendedor': RelatorioHtmlRenderer.escapeHtml(
        data['nome_vendedor'] as String? ?? '',
      ),
      'nome_vendedor_inicial': _inicial(data['nome_vendedor'] as String?),
      'telefone_vendedor': RelatorioHtmlRenderer.escapeHtml(
        data['telefone_vendedor'] as String? ?? '',
      ),
      'criado_em_formatado': _parseDate(data['criado_em'] as String?),
      'status': data['status'] as String? ?? '',
    });
    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(html);
  }

  static Future<String> _renderAvaliacao(Map<String, dynamic> data) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_avaliacao.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: data['report_brand_name'] as String?,
      customLogoPath: data['report_logo_path'] as String?,
      consultantName: data['nome_vendedor'] as String?,
      consultantRole: 'Consultoria',
    );

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      'produtor_fazenda': RelatorioHtmlRenderer.escapeHtml(
        data['produtor_fazenda'] as String? ?? '',
      ),
      'produto_utilizado': RelatorioHtmlRenderer.escapeHtml(
        data['produto_utilizado'] as String? ?? '',
      ),
      'localizacao_texto': RelatorioHtmlRenderer.escapeHtml(
        data['localizacao_texto'] as String? ?? '',
      ),
      'visibilidade': data['visibilidade'] as String? ?? '',
      'nome_talhao': RelatorioHtmlRenderer.escapeHtml(
        data['nome_talhao'] as String? ?? '',
      ),
      'tamanho_ha': RelatorioHtmlRenderer.formatHectares(
        (data['tamanho_ha'] as num?)?.toDouble(),
      ),
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': data['produtividade_unidade'] as String? ?? '',
      'conclusao': RelatorioHtmlRenderer.escapeHtml(
        data['conclusao'] as String? ?? '',
      ),
      'roi_calculado': data['roi_calculado']?.toString() ?? '',
      'roi_investimento': data['roi_investimento']?.toString() ?? '',
      'roi_retorno': data['roi_retorno']?.toString() ?? '',
      'descricao': RelatorioHtmlRenderer.escapeHtml(
        data['descricao'] as String? ?? '',
      ),
      'lat': data['lat']?.toString() ?? '',
      'lng': data['lng']?.toString() ?? '',
      'nome_vendedor': RelatorioHtmlRenderer.escapeHtml(
        data['nome_vendedor'] as String? ?? '',
      ),
      'nome_vendedor_inicial': _inicial(data['nome_vendedor'] as String?),
      'telefone_vendedor': RelatorioHtmlRenderer.escapeHtml(
        data['telefone_vendedor'] as String? ?? '',
      ),
      'criado_em_formatado': _parseDate(data['criado_em'] as String?),
      'status': data['status'] as String? ?? '',
    });

    final blocos = data['avaliacoes'] as List<dynamic>? ?? [];
    final blocosHtml = StringBuffer();
    for (var index = 0; index < blocos.length; index++) {
      final bloco = blocos[index];
      if (bloco is Map<String, dynamic>) {
        blocosHtml.write(_renderAvaliacaoBloco(bloco, index + 1));
      } else if (bloco is Map) {
        blocosHtml.write(
          _renderAvaliacaoBloco(Map<String, dynamic>.from(bloco), index + 1),
        );
      }
    }

    tpl = RelatorioHtmlRenderer.resolveEachBlock(
      tpl,
      'avaliacoes',
      html: blocosHtml.toString(),
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
  }

  static String _renderAvaliacaoBloco(Map<String, dynamic> data, int ordem) {
    final isDuas = (data['layout'] as String? ?? 'duas_fotos') == 'duas_fotos';
    return '''
    <div class="avaliacao-block">
      <div class="avaliacao-header">
        <div class="avaliacao-ordem">
          <div class="avaliacao-ordem-num">$ordem</div>
          <span class="avaliacao-ordem-text">Avaliação $ordem</span>
        </div>
        <span class="avaliacao-layout-tag">${isDuas ? 'Lado A vs Lado B' : 'Foto Única'}</span>
      </div>
      <div class="lados-grid${isDuas ? '' : ' uma-foto'}">
        ${_renderLado('a', data['lado_a_label'] as String?, data['lado_a_foto_url'] as String?, data['lado_a_cultura'] as String?, data['lado_a_obs'] as String?)}
        ${isDuas ? _renderLado('b', data['lado_b_label'] as String?, data['lado_b_foto_url'] as String?, data['lado_b_cultura'] as String?, data['lado_b_obs'] as String?) : ''}
      </div>
    </div>
    ''';
  }

  static String _renderLado(
    String lado,
    String? label,
    String? fotoUrl,
    String? cultura,
    String? obs,
  ) {
    final fotoHtml = (fotoUrl != null && fotoUrl.isNotEmpty)
        ? '<img src="$fotoUrl" alt="Lado ${lado.toUpperCase()}" loading="lazy">'
        : '<div class="lado-foto-placeholder"><svg width="32" height="32" viewBox="0 0 24 24" fill="#9CA3AF"><path d="M21 19V5c0-1.1-.9-2-2-2H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2zM8.5 13.5l2.5 3.01L14.5 12l4.5 6H5l3.5-4.5z"/></svg></div>';

    return '''
    <div class="lado">
      <div class="lado-header">
        <span class="lado-badge $lado">${lado.toUpperCase()}</span>
        <span class="lado-label">${RelatorioHtmlRenderer.escapeHtml(label)}</span>
      </div>
      <div class="lado-foto">$fotoHtml</div>
      <div class="lado-info">
        ${cultura != null ? '<span class="lado-cultura">${RelatorioHtmlRenderer.escapeHtml(cultura)}</span>' : ''}
        ${obs != null ? '<div class="lado-obs">${RelatorioHtmlRenderer.escapeHtml(obs)}</div>' : ''}
      </div>
    </div>
    ''';
  }

  static String _parseDate(String? iso) {
    if (iso == null) return '';
    try {
      return RelatorioHtmlRenderer.formatDate(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  static String _inicial(String? nome) {
    if (nome == null || nome.isEmpty) return '?';
    return nome[0].toUpperCase();
  }
}
