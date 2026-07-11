import 'dart:convert';

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
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
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

    final roi = _MarketingRoiData.from(data);
    tpl = _resolveAllIfBlocks(tpl, 'roi_agronomico', include: roi != null);
    tpl = _resolveAllIfBlocks(
      tpl,
      'roi_talhao',
      include: roi?.hasTalhao == true,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'roi_total',
      include: roi?.hasAreaTotal == true,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'quantidade_produzida',
      include: data['quantidade_produzida'] != null,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'data_case',
      include: data['data_case'] != null,
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
      'prod_sem_produto': _formatNumber(roi?.prodSemProduto),
      'prod_com_produto': _formatNumber(roi?.prodComProduto),
      'unidade_produtividade':
          data['unidade_produtividade'] as String? ??
          data['produtividade_unidade'] as String? ??
          '',
      'custo_produto_por_ha': _formatMoney(roi?.custoProdutoPorHa),
      'valor_grao': _formatMoney(roi?.valorGrao),
      'ganho_sc_ha': _formatSigned(roi?.ganhoScHa),
      'receita_ganho': _formatMoney(roi?.receitaGanho),
      'roi_liquido_rs_ha': _formatMoney(roi?.roiLiquidoRsHa),
      'roi_em_sacas_ha': _formatNumber(roi?.roiEmSacasHa),
      'roi_sacas_talhao': _formatNumber(roi?.roiSacasTalhao),
      'roi_reais_talhao': _formatMoney(roi?.roiReaisTalhao),
      'roi_sacas_total': _formatNumber(roi?.roiSacasTotal),
      'roi_reais_total': _formatMoney(roi?.roiReaisTotal),
      'tamanho_ha': _formatNumber(roi?.tamanhoHa),
      'area_total': _formatNumber(roi?.areaTotal),
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
      'data_case_formatado': _parseDate(data['data_case'] as String?),
    });
    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(html);
  }

  static Future<String> _renderAntesDepois(Map<String, dynamic> data) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_antes_depois.html',
    );
    final branding = await RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: data['report_brand_name'] as String?,
      customLogoPath: data['report_logo_path'] as String?,
      consultantName: data['nome_vendedor'] as String?,
      consultantRole: 'Consultoria',
    );

    final parametros = _MarketingParametroData.listFrom(
      data['parametros_json'],
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'parametros_comparativos',
      include: parametros.isNotEmpty,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'ganho_produtividade',
      include: (data['ganho_produtividade'] as String?)?.isNotEmpty == true,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'economia_gerada',
      include: (data['economia_gerada'] as String?)?.isNotEmpty == true,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'produtividade_valor',
      include: data['produtividade_valor'] != null,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'data_case',
      include: data['data_case'] != null,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'resultados_legados',
      include:
          parametros.isEmpty &&
          ((data['ganho_produtividade'] as String?)?.isNotEmpty == true ||
              (data['economia_gerada'] as String?)?.isNotEmpty == true ||
              data['produtividade_valor'] != null),
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
      'media_ganho_percent': _formatSigned(_mediaParametros(parametros)),
      'parametros_comparativos_html': _renderParametrosHtml(parametros),
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
      'data_case_formatado': _parseDate(data['data_case'] as String?),
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

    final avaliacoesLivres = _MarketingAvaliacaoData.listFrom(
      data['avaliacoes_json'],
    );
    final conclusao =
        data['conclusao_tecnica'] as String? ?? data['conclusao'] as String?;

    tpl = _resolveAllIfBlocks(
      tpl,
      'data_case',
      include: data['data_case'] != null,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'conclusao',
      include: conclusao?.trim().isNotEmpty == true,
    );
    tpl = _resolveAllIfBlocks(tpl, 'roi_calculado', include: false);

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
      'conclusao': RelatorioHtmlRenderer.escapeHtml(conclusao ?? ''),
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
      'data_case_formatado': _parseDate(data['data_case'] as String?),
    });

    final blocosHtml = StringBuffer();
    if (avaliacoesLivres.isNotEmpty) {
      for (var index = 0; index < avaliacoesLivres.length; index++) {
        blocosHtml.write(
          _renderAvaliacaoLivre(avaliacoesLivres[index], index + 1),
        );
      }
    } else {
      final blocos = data['avaliacoes'] as List<dynamic>? ?? [];
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
    }

    tpl = RelatorioHtmlRenderer.resolveEachBlock(
      tpl,
      'avaliacoes',
      html: blocosHtml.toString(),
    );

    return RelatorioHtmlRenderer.stripUnresolvedPlaceholders(tpl);
  }

  static String _renderAvaliacaoLivre(_MarketingAvaliacaoData data, int ordem) {
    final parametrosHtml = data.parametros.map((parametro) {
      final unidade = parametro.unidade == null || parametro.unidade!.isEmpty
          ? ''
          : ' ${RelatorioHtmlRenderer.escapeHtml(parametro.unidade)}';
      final delta = parametro.testemunha == 0
          ? '--'
          : '${_formatSigned(parametro.deltaPercent)}%';
      final deltaClass = parametro.deltaPercent < 0
          ? 'negative'
          : parametro.deltaPercent > 0
          ? 'positive'
          : 'neutral';
      return '''
        <div class="lado-obs">
          <strong>${RelatorioHtmlRenderer.escapeHtml(parametro.titulo)}</strong><br>
          ${RelatorioHtmlRenderer.escapeHtml(data.nomeLadoA)}: ${_formatNumber(parametro.testemunha)} → ${RelatorioHtmlRenderer.escapeHtml(data.nomeLadoB)}: ${_formatNumber(parametro.teste)}$unidade
          <strong class="$deltaClass"> $delta</strong>
        </div>
      ''';
    }).join();

    return '''
    <div class="avaliacao-block">
      <div class="avaliacao-header">
        <div class="avaliacao-ordem">
          <div class="avaliacao-ordem-num">$ordem</div>
          <span class="avaliacao-ordem-text">${RelatorioHtmlRenderer.escapeHtml(data.titulo.isEmpty ? 'Avaliação $ordem' : data.titulo)}</span>
        </div>
        <span class="avaliacao-layout-tag">Média ${_formatSigned(data.mediaGanhoPercent)}%</span>
      </div>
      <div class="lados-grid">
        ${_renderLado('a', data.nomeLadoA, data.fotoLadoAPath, data.cultura, null)}
        ${_renderLado('b', data.nomeLadoB, data.fotoLadoBPath, data.cultura, data.observacoes)}
      </div>
      <div style="padding: 0 16px 16px;">
        $parametrosHtml
      </div>
    </div>
    ''';
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
        : '<div class="lado-foto-placeholder"><span>Sem foto</span></div>';

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

  static String _resolveAllIfBlocks(
    String template,
    String condition, {
    required bool include,
  }) {
    var current = template;
    while (current.contains('<!-- {{#if $condition}} -->')) {
      final next = RelatorioHtmlRenderer.resolveIfBlock(
        current,
        condition,
        include: include,
      );
      if (next == current) break;
      current = next;
    }
    return current;
  }

  static String _formatMoney(double? value) {
    if (value == null) return '';
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _formatNumber(double? value) {
    if (value == null) return '';
    return value.toStringAsFixed(1).replaceAll('.', ',');
  }

  static String _formatSigned(double? value) {
    if (value == null) return '';
    final formatted = _formatNumber(value);
    return value >= 0 ? '+$formatted' : formatted;
  }

  static double? _mediaParametros(List<_MarketingParametroData> parametros) {
    if (parametros.isEmpty) return null;
    final total = parametros.fold<double>(
      0,
      (sum, item) => sum + item.deltaPercent,
    );
    return total / parametros.length;
  }

  static String _renderParametrosHtml(
    List<_MarketingParametroData> parametros,
  ) {
    if (parametros.isEmpty) return '';
    return parametros.map((parametro) {
      final unidade = parametro.unidade == null || parametro.unidade!.isEmpty
          ? ''
          : ' ${RelatorioHtmlRenderer.escapeHtml(parametro.unidade)}';
      final delta = parametro.testemunha == 0
          ? '--'
          : '${_formatSigned(parametro.deltaPercent)}%';
      final deltaClass = parametro.deltaPercent < 0
          ? 'negative'
          : parametro.deltaPercent > 0
          ? 'positive'
          : 'neutral';
      return '''
        <div class="param-row">
          <div class="param-title">${RelatorioHtmlRenderer.escapeHtml(parametro.titulo)}</div>
          <div class="param-values">${_formatNumber(parametro.testemunha)} → ${_formatNumber(parametro.teste)}$unidade</div>
          <div class="param-delta $deltaClass">$delta</div>
        </div>
      ''';
    }).join();
  }
}

class _MarketingRoiData {
  final double prodSemProduto;
  final double prodComProduto;
  final String unidadeProdutividade;
  final double custoProdutoPorHa;
  final double valorGrao;
  final double? tamanhoHa;
  final double? areaTotal;

  const _MarketingRoiData({
    required this.prodSemProduto,
    required this.prodComProduto,
    required this.unidadeProdutividade,
    required this.custoProdutoPorHa,
    required this.valorGrao,
    this.tamanhoHa,
    this.areaTotal,
  });

  factory _MarketingRoiData.fromMap(Map<String, dynamic> data) {
    return _MarketingRoiData(
      prodSemProduto: _num(data['prod_sem_produto']) ?? 0,
      prodComProduto: _num(data['prod_com_produto']) ?? 0,
      unidadeProdutividade:
          data['unidade_produtividade'] as String? ??
          data['produtividade_unidade'] as String? ??
          'sc/ha',
      custoProdutoPorHa: _num(data['custo_produto_por_ha']) ?? 0,
      valorGrao: _num(data['valor_grao']) ?? 0,
      tamanhoHa: _num(data['tamanho_ha']),
      areaTotal: _num(data['area_total']),
    );
  }

  static _MarketingRoiData? from(Map<String, dynamic> data) {
    final roi = _MarketingRoiData.fromMap(data);
    return roi.isComplete ? roi : null;
  }

  bool get isComplete =>
      prodSemProduto > 0 &&
      prodComProduto > 0 &&
      custoProdutoPorHa > 0 &&
      valorGrao > 0;

  bool get hasTalhao => tamanhoHa != null && tamanhoHa! > 0;

  bool get hasAreaTotal => areaTotal != null && areaTotal! > 0;

  double get ganhoScHa => prodComProduto - prodSemProduto;

  double get receitaGanho => ganhoScHa * valorGrao;

  double get roiLiquidoRsHa => receitaGanho - custoProdutoPorHa;

  double get roiEmSacasHa => valorGrao > 0 ? roiLiquidoRsHa / valorGrao : 0;

  double? get roiSacasTalhao => hasTalhao ? roiEmSacasHa * tamanhoHa! : null;

  double? get roiReaisTalhao => hasTalhao ? roiLiquidoRsHa * tamanhoHa! : null;

  double? get roiSacasTotal => hasAreaTotal ? roiEmSacasHa * areaTotal! : null;

  double? get roiReaisTotal =>
      hasAreaTotal ? roiLiquidoRsHa * areaTotal! : null;

  static double? _num(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }
}

class _MarketingParametroData {
  final String titulo;
  final double testemunha;
  final double teste;
  final String? unidade;

  const _MarketingParametroData({
    required this.titulo,
    required this.testemunha,
    required this.teste,
    this.unidade,
  });

  double get deltaPercent =>
      testemunha != 0 ? ((teste - testemunha) / testemunha) * 100 : 0.0;

  static List<_MarketingParametroData> listFrom(dynamic raw) {
    if (raw == null) return const [];
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((item) {
            final map = Map<String, dynamic>.from(item);
            return _MarketingParametroData(
              titulo: map['titulo'] as String? ?? '',
              testemunha: _num(map['testemunha']) ?? 0.0,
              teste: _num(map['teste']) ?? 0.0,
              unidade: map['unidade'] as String?,
            );
          })
          .where((item) => item.titulo.trim().isNotEmpty)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  static double? _num(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.'));
    return null;
  }
}

class _MarketingAvaliacaoData {
  final String titulo;
  final String nomeLadoA;
  final String nomeLadoB;
  final String? fotoLadoAPath;
  final String? fotoLadoBPath;
  final String? cultura;
  final List<_MarketingParametroData> parametros;
  final String? observacoes;

  const _MarketingAvaliacaoData({
    required this.titulo,
    required this.nomeLadoA,
    required this.nomeLadoB,
    this.fotoLadoAPath,
    this.fotoLadoBPath,
    this.cultura,
    this.parametros = const [],
    this.observacoes,
  });

  double get mediaGanhoPercent {
    if (parametros.isEmpty) return 0.0;
    final total = parametros.fold<double>(
      0,
      (sum, item) => sum + item.deltaPercent,
    );
    return total / parametros.length;
  }

  static List<_MarketingAvaliacaoData> listFrom(dynamic raw) {
    if (raw == null) return const [];
    try {
      final decoded = raw is String ? jsonDecode(raw) : raw;
      if (decoded is! List) return const [];
      return decoded.whereType<Map>().map((item) {
        final map = Map<String, dynamic>.from(item);
        return _MarketingAvaliacaoData(
          titulo: map['titulo'] as String? ?? '',
          nomeLadoA: _nonEmpty(map['nome_lado_a'] as String?, 'Lado A'),
          nomeLadoB: _nonEmpty(map['nome_lado_b'] as String?, 'Lado B'),
          fotoLadoAPath: map['foto_lado_a_path'] as String?,
          fotoLadoBPath: map['foto_lado_b_path'] as String?,
          cultura: map['cultura'] as String?,
          parametros: _MarketingParametroData.listFrom(map['parametros']),
          observacoes: map['observacoes'] as String?,
        );
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static String _nonEmpty(String? value, String fallback) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? fallback : trimmed;
  }
}
