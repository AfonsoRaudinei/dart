import 'dart:convert';
import 'dart:typed_data';

import 'relatorio_html_renderer.dart';

class MarketingHtmlRenderer {
  /// Renderiza o HTML correto para o tipo do case.
  ///
  /// [data] = MarketingCase.toMap()/toJson() convertido pelo chamador.
  static Future<String> render(
    Map<String, dynamic> data, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  }) async {
    switch (data['tipo'] as String? ?? 'resultado') {
      case 'resultado':
        return _renderResultado(data, fetchRemoteBytes: fetchRemoteBytes);
      case 'antes_depois':
        return _renderAntesDepois(data, fetchRemoteBytes: fetchRemoteBytes);
      case 'avaliacao':
        return _renderAvaliacao(data, fetchRemoteBytes: fetchRemoteBytes);
      default:
        return _renderResultado(data, fetchRemoteBytes: fetchRemoteBytes);
    }
  }

  static Future<String> _renderResultado(
    Map<String, dynamic> data, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_resultado.html',
    );
    final branding = await _branding(data);
    final fotoPrincipalUrl = data['foto_principal_url'] as String?;
    final foto = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
      fotoPrincipalUrl,
      fetchRemoteBytes: fetchRemoteBytes,
    );
    final dataCase = _parseDate(data['data_case'] as String?);

    final roi = _MarketingRoiData.from(data);
    tpl = _resolveAllIfBlocks(
      tpl,
      'resultado_numeros',
      include: roi != null || data['quantidade_produzida'] != null,
    );
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
      'foto_principal_url',
      include: foto.isNotEmpty,
    );
    final contexto = _contexto(data);
    tpl = _resolveCommonBlocks(tpl, data, contexto: contexto);

    final html = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      ..._commonValues(data, contexto: contexto),
      'foto_principal_url': foto,
      'foto_legenda': dataCase.isEmpty ? 'Foto 1' : 'Foto 1 · $dataCase',
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': RelatorioHtmlRenderer.escapeHtml(
        data['produtividade_unidade'] as String?,
      ),
      'quantidade_produzida': data['quantidade_produzida']?.toString() ?? '',
      'prod_sem_produto': _formatNumber(roi?.prodSemProduto),
      'prod_com_produto': _formatNumber(roi?.prodComProduto),
      'unidade_produtividade': RelatorioHtmlRenderer.escapeHtml(
        data['unidade_produtividade'] as String? ??
            data['produtividade_unidade'] as String? ??
            '',
      ),
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
    });
    return RelatorioHtmlRenderer.finalizeDocument(html);
  }

  static Future<String> _renderAntesDepois(
    Map<String, dynamic> data, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_antes_depois.html',
    );
    final branding = await _branding(data);
    final dataCase = _parseDate(data['data_case'] as String?);

    final parametros = _MarketingParametroData.listFrom(
      data['parametros_json'],
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'parametros_comparativos',
      include: parametros.isNotEmpty,
    );
    final hasGanho =
        (data['ganho_produtividade'] as String?)?.isNotEmpty == true;
    final resultadosLegados =
        parametros.isEmpty &&
        (hasGanho ||
            (data['economia_gerada'] as String?)?.isNotEmpty == true ||
            data['produtividade_valor'] != null);
    tpl = _resolveAllIfBlocks(
      tpl,
      'resultados_legados',
      include: resultadosLegados,
    );
    // Com resultados legados o ganho já aparece em "Resultados".
    tpl = _resolveAllIfBlocks(
      tpl,
      'ganho_produtividade_ficha',
      include: hasGanho && !resultadosLegados,
    );
    tpl = _resolveAllIfBlocks(tpl, 'ganho_produtividade', include: hasGanho);
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

    final fotoAntes = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
      data['foto_antes_url'] as String?,
      fetchRemoteBytes: fetchRemoteBytes,
    );
    final fotoDepois = await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
      data['foto_depois_url'] as String?,
      fetchRemoteBytes: fetchRemoteBytes,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'foto_antes_url',
      include: fotoAntes.isNotEmpty,
    );
    tpl = _resolveAllIfBlocks(
      tpl,
      'foto_depois_url',
      include: fotoDepois.isNotEmpty,
    );
    final contexto = _contexto(data);
    tpl = _resolveCommonBlocks(tpl, data, contexto: contexto);

    final html = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      ..._commonValues(data, contexto: contexto),
      'foto_antes_url': fotoAntes,
      'foto_depois_url': fotoDepois,
      'data_case_sufixo': dataCase.isEmpty ? '' : ' · $dataCase',
      'ganho_produtividade': RelatorioHtmlRenderer.escapeHtml(
        data['ganho_produtividade'] as String? ?? '',
      ),
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': RelatorioHtmlRenderer.escapeHtml(
        data['produtividade_unidade'] as String?,
      ),
      'economia_gerada': RelatorioHtmlRenderer.escapeHtml(
        data['economia_gerada'] as String? ?? '',
      ),
      'media_ganho_percent': _formatSigned(_mediaParametros(parametros)),
      'parametros_comparativos_html': _renderParametrosHtml(parametros),
    });
    return RelatorioHtmlRenderer.finalizeDocument(html);
  }

  static Future<String> _renderAvaliacao(
    Map<String, dynamic> data, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_avaliacao.html',
    );
    final branding = await _branding(data);

    final avaliacoesLivres = _MarketingAvaliacaoData.listFrom(
      data['avaliacoes_json'],
    );
    final conclusao =
        data['conclusao_tecnica'] as String? ?? data['conclusao'] as String?;
    final nomeTalhao = (data['nome_talhao'] as String?)?.trim() ?? '';
    final tamanhoHa = RelatorioHtmlRenderer.formatHectares(
      (data['tamanho_ha'] as num?)?.toDouble(),
    );
    final contexto = _contexto(data, extra: nomeTalhao);

    tpl = _resolveAllIfBlocks(
      tpl,
      'conclusao',
      include: conclusao?.trim().isNotEmpty == true,
    );
    tpl = _resolveAllIfBlocks(tpl, 'roi_calculado', include: false);
    tpl = _resolveAllIfBlocks(
      tpl,
      'nome_talhao',
      include: nomeTalhao.isNotEmpty,
    );
    tpl = _resolveAllIfBlocks(tpl, 'tamanho_ha', include: tamanhoHa.isNotEmpty);
    tpl = _resolveAllIfBlocks(
      tpl,
      'produtividade_valor',
      include: data['produtividade_valor'] != null,
    );
    tpl = _resolveCommonBlocks(tpl, data, contexto: contexto);

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      ..._commonValues(data, contexto: contexto),
      'nome_talhao': RelatorioHtmlRenderer.escapeHtml(nomeTalhao),
      'tamanho_ha': tamanhoHa,
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': RelatorioHtmlRenderer.escapeHtml(
        data['produtividade_unidade'] as String?,
      ),
      'conclusao': RelatorioHtmlRenderer.escapeHtml(conclusao ?? ''),
      'roi_calculado': data['roi_calculado']?.toString() ?? '',
      'roi_investimento': data['roi_investimento']?.toString() ?? '',
      'roi_retorno': data['roi_retorno']?.toString() ?? '',
    });

    final blocosHtml = StringBuffer();
    if (avaliacoesLivres.isNotEmpty) {
      for (var index = 0; index < avaliacoesLivres.length; index++) {
        blocosHtml.write(
          await _renderAvaliacaoLivre(
            avaliacoesLivres[index],
            index + 1,
            fetchRemoteBytes: fetchRemoteBytes,
          ),
        );
      }
    } else {
      final blocos = data['avaliacoes'] as List<dynamic>? ?? [];
      for (var index = 0; index < blocos.length; index++) {
        final bloco = blocos[index];
        if (bloco is Map) {
          blocosHtml.write(
            await _renderAvaliacaoBloco(
              Map<String, dynamic>.from(bloco),
              index + 1,
              fetchRemoteBytes: fetchRemoteBytes,
            ),
          );
        }
      }
    }
    if (blocosHtml.isEmpty) {
      blocosHtml.write(
        '<p class="sf-muted">Nenhuma avaliação registrada neste case.</p>',
      );
    }

    tpl = RelatorioHtmlRenderer.resolveEachBlock(
      tpl,
      'avaliacoes',
      html: blocosHtml.toString(),
    );

    return RelatorioHtmlRenderer.finalizeDocument(tpl);
  }

  static Future<Map<String, String>> _branding(Map<String, dynamic> data) {
    return RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: data['report_brand_name'] as String?,
      customLogoPath: data['report_logo_path'] as String?,
      consultantName: data['nome_vendedor'] as String?,
      consultantRole: 'Consultoria',
    );
  }

  /// Linha de contexto do timbre: `Produto · [extra ·] Município · data`.
  static String _contexto(Map<String, dynamic> data, {String extra = ''}) {
    final dataCase = _parseDate(data['data_case'] as String?);
    return [
          data['produto_utilizado'] as String?,
          extra,
          data['localizacao_texto'] as String?,
        ]
        .map((value) => value?.trim() ?? '')
        .where((value) => value.isNotEmpty)
        .map(RelatorioHtmlRenderer.escapeHtml)
        .followedBy([if (dataCase.isNotEmpty) dataCase])
        .join(' · ');
  }

  static String _resolveCommonBlocks(
    String template,
    Map<String, dynamic> data, {
    required String contexto,
  }) {
    bool hasText(String key) =>
        (data[key] as String?)?.trim().isNotEmpty == true;

    final conditions = <String, bool>{
      'contexto_linha': contexto.isNotEmpty,
      'status': hasText('status'),
      'visibilidade': hasText('visibilidade'),
      'produtor_fazenda': hasText('produtor_fazenda'),
      'produto_utilizado': hasText('produto_utilizado'),
      'localizacao_texto': hasText('localizacao_texto'),
      'data_case': data['data_case'] != null,
      'localizacao': data['lat'] != null && data['lng'] != null,
      'descricao': hasText('descricao'),
      'nome_vendedor': hasText('nome_vendedor'),
      'telefone_vendedor': hasText('telefone_vendedor'),
      'criado_em': hasText('criado_em'),
    };
    var current = template;
    for (final entry in conditions.entries) {
      current = _resolveAllIfBlocks(current, entry.key, include: entry.value);
    }
    return current;
  }

  static Map<String, String> _commonValues(
    Map<String, dynamic> data, {
    required String contexto,
  }) {
    final status = (data['status'] as String?)?.trim() ?? '';
    return {
      'contexto_linha': contexto,
      'produtor_fazenda': RelatorioHtmlRenderer.escapeHtml(
        data['produtor_fazenda'] as String? ?? '',
      ),
      'produto_utilizado': RelatorioHtmlRenderer.escapeHtml(
        data['produto_utilizado'] as String? ?? '',
      ),
      'localizacao_texto': RelatorioHtmlRenderer.escapeHtml(
        data['localizacao_texto'] as String? ?? '',
      ),
      'visibilidade_label': RelatorioHtmlRenderer.escapeHtml(
        _visibilidadeLabel(data['visibilidade'] as String?),
      ),
      'status_label': RelatorioHtmlRenderer.escapeHtml(_statusLabel(status)),
      'status_dot': _statusDot(status),
      'descricao': RelatorioHtmlRenderer.escapeHtml(
        data['descricao'] as String? ?? '',
      ),
      'nome_vendedor': RelatorioHtmlRenderer.escapeHtml(
        data['nome_vendedor'] as String? ?? '',
      ),
      'telefone_vendedor': RelatorioHtmlRenderer.escapeHtml(
        data['telefone_vendedor'] as String? ?? '',
      ),
      'emitido_em': _formatDateSafe(DateTime.now()),
      'criado_em_formatado': _parseDate(data['criado_em'] as String?),
      'data_case_formatado': _parseDate(data['data_case'] as String?),
    };
  }

  static String _statusLabel(String status) {
    switch (status) {
      case 'draft':
      case 'rascunho':
        return 'Rascunho';
      case 'pending_sync':
        return 'Aguardando sincronização';
      case 'published':
      case 'publicado':
        return 'Publicado';
      case 'archived':
      case 'arquivado':
        return 'Arquivado';
      default:
        return RelatorioHtmlRenderer.humanizeKey(status);
    }
  }

  static String _statusDot(String status) {
    switch (status) {
      case 'published':
      case 'publicado':
        return 'ok';
      case 'pending_sync':
        return 'media';
      default:
        return 'draft';
    }
  }

  static String _visibilidadeLabel(String? visibilidade) {
    final value = visibilidade?.trim().toLowerCase() ?? '';
    switch (value) {
      case 'ouro':
        return 'Plano Ouro';
      case 'prata':
        return 'Plano Prata';
      case 'bronze':
        return 'Plano Bronze';
      case 'publico':
        return 'Público';
      case 'privado':
        return 'Privado';
      default:
        return RelatorioHtmlRenderer.humanizeKey(value);
    }
  }

  static Future<String> _renderAvaliacaoLivre(
    _MarketingAvaliacaoData data,
    int ordem, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  }) async {
    final nomeA = RelatorioHtmlRenderer.escapeHtml(data.nomeLadoA);
    final nomeB = RelatorioHtmlRenderer.escapeHtml(data.nomeLadoB);
    final parametrosHtml = data.parametros.map((parametro) {
      final unidade = parametro.unidade == null || parametro.unidade!.isEmpty
          ? ''
          : ' ${RelatorioHtmlRenderer.escapeHtml(parametro.unidade)}';
      return _parametroRow(
        parametro,
        sub:
            '$nomeA ${_formatNumber(parametro.testemunha)} → '
            '$nomeB ${_formatNumber(parametro.teste)}$unidade',
      );
    }).join();
    final titulo = data.titulo.trim().isEmpty
        ? 'Avaliação $ordem'
        : data.titulo.trim();
    final observacoes = data.observacoes?.trim() ?? '';

    return '''
    <article class="mk-avaliacao avaliacao-block">
      <div class="mk-avaliacao-head">
        <span class="mk-avaliacao-title">${RelatorioHtmlRenderer.escapeHtml(titulo)}</span>
        <span class="mk-avaliacao-media">Média <strong>${_formatSigned(data.mediaGanhoPercent)}%</strong></span>
      </div>
      <div class="sf-figure-grid mk-compare">
        ${await _ladoFigure(ordem, 'a', data.nomeLadoA, data.fotoLadoAPath, data.cultura, fetchRemoteBytes: fetchRemoteBytes)}
        ${await _ladoFigure(ordem, 'b', data.nomeLadoB, data.fotoLadoBPath, data.cultura, fetchRemoteBytes: fetchRemoteBytes)}
      </div>
      ${parametrosHtml.isEmpty ? '' : '<div class="sf-sheet">$parametrosHtml</div>'}
      ${observacoes.isEmpty ? '' : '<div class="sf-note"><p class="sf-note-label">Observações</p><p class="sf-prose">${RelatorioHtmlRenderer.escapeHtml(observacoes)}</p></div>'}
    </article>
    ''';
  }

  static Future<String> _renderAvaliacaoBloco(
    Map<String, dynamic> data,
    int ordem, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  }) async {
    final isDuas = (data['layout'] as String? ?? 'duas_fotos') == 'duas_fotos';
    final labelA = data['lado_a_label'] as String?;
    final labelB = data['lado_b_label'] as String?;
    final notas = <String>[
      _ladoNota(labelA, 'Lado A', data['lado_a_obs'] as String?),
      if (isDuas) _ladoNota(labelB, 'Lado B', data['lado_b_obs'] as String?),
    ].where((nota) => nota.isNotEmpty).join();

    return '''
    <article class="mk-avaliacao avaliacao-block">
      <div class="mk-avaliacao-head">
        <span class="mk-avaliacao-title">Avaliação $ordem</span>
        <span class="mk-avaliacao-media">${isDuas ? 'Lado A e lado B' : 'Foto única'}</span>
      </div>
      <div class="sf-figure-grid mk-compare${isDuas ? '' : ' uma-foto'}">
        ${await _ladoFigure(ordem, 'a', labelA, data['lado_a_foto_url'] as String?, data['lado_a_cultura'] as String?, fetchRemoteBytes: fetchRemoteBytes)}
        ${isDuas ? await _ladoFigure(ordem, 'b', labelB, data['lado_b_foto_url'] as String?, data['lado_b_cultura'] as String?, fetchRemoteBytes: fetchRemoteBytes) : ''}
      </div>
      $notas
    </article>
    ''';
  }

  static String _ladoNota(String? label, String fallback, String? obs) {
    final texto = obs?.trim() ?? '';
    if (texto.isEmpty) return '';
    final nome = label?.trim().isNotEmpty == true ? label!.trim() : fallback;
    return '<div class="sf-note"><p class="sf-note-label">${RelatorioHtmlRenderer.escapeHtml(nome)}</p>'
        '<p class="sf-prose">${RelatorioHtmlRenderer.escapeHtml(texto)}</p></div>';
  }

  static Future<String> _ladoFigure(
    int ordem,
    String lado,
    String? label,
    String? fotoUrl,
    String? cultura, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  }) async {
    final resolvedFoto = fotoUrl != null && fotoUrl.isNotEmpty
        ? await RelatorioHtmlRenderer.resolvePhotoSrcForExport(
            fotoUrl,
            fetchRemoteBytes: fetchRemoteBytes,
          )
        : '';
    final nome = label?.trim().isNotEmpty == true
        ? label!.trim()
        : 'Lado ${lado.toUpperCase()}';
    final legenda = [nome, cultura?.trim() ?? '']
        .where((part) => part.isNotEmpty)
        .map(RelatorioHtmlRenderer.escapeHtml)
        .join(' · ');
    final id = 'sf-mk-av-$ordem-$lado';
    final fotoHtml = resolvedFoto.isNotEmpty
        ? '<input type="checkbox" id="$id" class="sf-lb-toggle" hidden>'
              '<label for="$id"><img data-sf-photo src="$resolvedFoto" alt="${RelatorioHtmlRenderer.escapeHtml(nome)}" loading="lazy"></label>'
        : '<div class="mk-photo-empty">Sem foto</div>';

    return '''
        <figure class="sf-figure lado">
          $fotoHtml
          <figcaption>$legenda</figcaption>
        </figure>
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

  /// `formatDate` exige `initializeDateFormatting('pt_BR')`; sem ela, cai
  /// para dd/MM/yyyy montado à mão em vez de vazar a data ISO.
  static String _formatDateSafe(DateTime value) {
    try {
      return RelatorioHtmlRenderer.formatDate(value);
    } catch (_) {
      String two(int n) => n.toString().padLeft(2, '0');
      return '${two(value.day)}/${two(value.month)}/${value.year}';
    }
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
      return _parametroRow(
        parametro,
        sub:
            '${_formatNumber(parametro.testemunha)} → '
            '${_formatNumber(parametro.teste)}$unidade',
      );
    }).join();
  }

  static String _parametroRow(
    _MarketingParametroData parametro, {
    required String sub,
  }) {
    final delta = parametro.testemunha == 0
        ? '--'
        : '${_formatSigned(parametro.deltaPercent)}%';
    final deltaClass = parametro.deltaPercent < 0
        ? 'negative'
        : parametro.deltaPercent > 0
        ? 'positive'
        : 'neutral';
    return '<div class="sf-row param-row">'
        '<span class="sf-row-label">${RelatorioHtmlRenderer.escapeHtml(parametro.titulo)}'
        '<span class="sf-row-sub">$sub</span></span>'
        '<span class="sf-row-value"><span class="mk-delta $deltaClass">$delta</span></span>'
        '</div>';
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
