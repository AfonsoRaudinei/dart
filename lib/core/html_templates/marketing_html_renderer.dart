import 'dart:convert';
import 'dart:typed_data';

import '../services/geocoding/reverse_geocoder.dart';
import '../utils/municipio_uf.dart';
import 'relatorio_html_renderer.dart';

class MarketingHtmlRenderer {
  /// Renderiza o HTML correto para o tipo do case.
  ///
  /// [data] = MarketingCase.toMap()/toJson() convertido pelo chamador.
  /// [resolveUf] completa "Município" sem UF a partir de lat/lng do case
  /// (padrão: geocodificação reversa nativa, tolerante a falha/offline).
  static Future<String> render(
    Map<String, dynamic> rawData, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
    Future<String?> Function(double lat, double lng)? resolveUf,
    bool asFragment = false,
  }) async {
    final data = await _withMunicipioUf(rawData, resolveUf: resolveUf);
    switch (data['tipo'] as String? ?? 'resultado') {
      case 'resultado':
        return _renderResultado(
          data,
          fetchRemoteBytes: fetchRemoteBytes,
          asFragment: asFragment,
        );
      case 'antes_depois':
        return _renderAntesDepois(
          data,
          fetchRemoteBytes: fetchRemoteBytes,
          asFragment: asFragment,
        );
      case 'avaliacao':
        return _renderAvaliacao(
          data,
          fetchRemoteBytes: fetchRemoteBytes,
          asFragment: asFragment,
        );
      default:
        return _renderResultado(
          data,
          fetchRemoteBytes: fetchRemoteBytes,
          asFragment: asFragment,
        );
    }
  }

  static Future<String> _renderResultado(
    Map<String, dynamic> data, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
    bool asFragment = false,
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
    tpl = _resolveFlags(tpl, {
      'resultado_numeros': roi != null || data['quantidade_produzida'] != null,
      'roi_agronomico': roi != null,
      'ganho_percent': _ganhoPercentLabel(roi).isNotEmpty,
      'roi_talhao': roi?.hasTalhao == true,
      'roi_total': roi?.hasAreaTotal == true,
      'quantidade_produzida': data['quantidade_produzida'] != null,
      'foto_principal_url': foto.isNotEmpty,
    });
    final contexto = _contexto(data);
    tpl = _resolveCommonBlocks(tpl, data, contexto: contexto);

    final html = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      ..._commonValues(data, contexto: contexto),
      'foto_principal_url': foto,
      'foto_legenda': dataCase.isEmpty ? 'Foto 1' : 'Foto 1 · $dataCase',
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': _esc(data, 'produtividade_unidade'),
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
      'ganho_percent': _ganhoPercentLabel(roi),
      'ganho_class': (roi?.ganhoScHa ?? 0) < 0 ? 'negative' : 'positive',
      'produto_rotulo': _produtoRotulo(data['produto_utilizado'] as String?),
      'receita_ganho': _formatMoney(roi?.receitaGanho),
      'roi_liquido_rs_ha': _formatMoney(roi?.roiLiquidoRsHa),
      'roi_em_sacas_ha': _formatNumber(roi?.roiEmSacasHa),
      'roi_sacas_talhao': _formatNumber(roi?.roiSacasTalhao),
      'roi_reais_talhao': _formatMoney(roi?.roiReaisTalhao),
      'roi_sacas_total': _formatNumber(roi?.roiSacasTotal),
      'roi_reais_total': _formatMoney(roi?.roiReaisTotal),
      'tamanho_ha': _formatNumber(roi?.tamanhoHa),
      'area_total': _formatNumber(roi?.areaTotal),
      'economia_gerada': _esc(data, 'economia_gerada'),
      'roi_calculado': data['roi_calculado']?.toString() ?? '',
      'roi_investimento': data['roi_investimento']?.toString() ?? '',
      'roi_retorno': data['roi_retorno']?.toString() ?? '',
    });
    return RelatorioHtmlRenderer.completeRender(html, asFragment: asFragment);
  }

  static Future<String> _renderAntesDepois(
    Map<String, dynamic> data, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
    bool asFragment = false,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_antes_depois.html',
    );
    final branding = await _branding(data);
    final dataCase = _parseDate(data['data_case'] as String?);
    final todos = _MarketingAvaliacaoData.listFrom(data['avaliacoes_json']);
    // Blocos só são fonte se algum tem foto/parâmetro; senão vale o legado.
    // Com blocos, só os 100% vazios (sem foto, parâmetro, texto) saem.
    final usaBlocos = todos.any((b) => b.temConteudo);
    final blocos = usaBlocos
        ? todos.where((b) => b.temConteudo || b.temTexto).toList()
        : const <_MarketingAvaliacaoData>[];
    final parametros = usaBlocos
        ? const <_MarketingParametroData>[]
        : _MarketingParametroData.listFrom(data['parametros_json']);
    final temParametros =
        parametros.isNotEmpty || blocos.any((b) => b.parametros.isNotEmpty);
    final conclusao = _conclusaoTexto(data);
    final hasGanho =
        (data['ganho_produtividade'] as String?)?.isNotEmpty == true;
    final hasEconomia =
        (data['economia_gerada'] as String?)?.isNotEmpty == true;
    final resultadosLegados =
        !temParametros &&
        (hasGanho || hasEconomia || data['produtividade_valor'] != null);

    Future<String> fotoLegada(String key) => usaBlocos
        ? Future.value('')
        : RelatorioHtmlRenderer.resolvePhotoSrcForExport(
            data[key] as String?,
            fetchRemoteBytes: fetchRemoteBytes,
          );
    final fotoAntes = await fotoLegada('foto_antes_url');
    final fotoDepois = await fotoLegada('foto_depois_url');

    // 'blocos_avaliacao' primeiro: é o bloco externo dos demais.
    final condicoes = <String, bool>{
      'blocos_avaliacao': usaBlocos,
      'parametros_comparativos': parametros.isNotEmpty,
      'conclusao': conclusao.isNotEmpty,
      'resultados_legados': resultadosLegados,
      // Com resultados legados o ganho já aparece em "Resultados".
      'ganho_produtividade_ficha': hasGanho && !resultadosLegados,
      'ganho_produtividade': hasGanho,
      'economia_gerada': hasEconomia,
      'produtividade_valor': data['produtividade_valor'] != null,
      'foto_antes_url': fotoAntes.isNotEmpty,
      'foto_depois_url': fotoDepois.isNotEmpty,
    };
    tpl = _resolveFlags(tpl, condicoes);
    final contexto = _contexto(data);
    tpl = _resolveCommonBlocks(tpl, data, contexto: contexto);

    final html = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      ..._commonValues(data, contexto: contexto),
      'foto_antes_url': fotoAntes,
      'foto_depois_url': fotoDepois,
      'data_case_sufixo': dataCase.isEmpty ? '' : ' · $dataCase',
      'ganho_produtividade': _esc(data, 'ganho_produtividade'),
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': _esc(data, 'produtividade_unidade'),
      'economia_gerada': _esc(data, 'economia_gerada'),
      'media_ganho_percent': _formatSigned(_mediaParametros(parametros)),
      'parametros_comparativos_html': _renderParametrosHtml(parametros),
      'conclusao': RelatorioHtmlRenderer.escapeHtml(conclusao),
    });

    final completo = RelatorioHtmlRenderer.resolveEachBlock(
      html,
      'avaliacoes',
      html: await _renderBlocosHtml(
        blocos,
        fetchRemoteBytes: fetchRemoteBytes,
        ocultarLadosSemFoto: true,
      ),
    );
    return RelatorioHtmlRenderer.completeRender(
      completo,
      asFragment: asFragment,
    );
  }

  static Future<String> _renderAvaliacao(
    Map<String, dynamic> data, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
    bool asFragment = false,
  }) async {
    var tpl = await RelatorioHtmlRenderer.loadTemplate(
      'marketing_avaliacao.html',
    );
    final branding = await _branding(data);

    final avaliacoesLivres = _MarketingAvaliacaoData.listFrom(
      data['avaliacoes_json'],
    );
    final conclusao = _conclusaoTexto(data);
    final nomeTalhao = (data['nome_talhao'] as String?)?.trim() ?? '';
    final tamanhoHa = RelatorioHtmlRenderer.formatHectares(
      (data['tamanho_ha'] as num?)?.toDouble(),
    );
    final contexto = _contexto(data, extra: nomeTalhao);

    tpl = _resolveFlags(tpl, {
      'conclusao': conclusao.isNotEmpty,
      'roi_calculado': false,
      'nome_talhao': nomeTalhao.isNotEmpty,
      'tamanho_ha': tamanhoHa.isNotEmpty,
      'produtividade_valor': data['produtividade_valor'] != null,
    });
    tpl = _resolveCommonBlocks(tpl, data, contexto: contexto);

    tpl = RelatorioHtmlRenderer.replacePlaceholders(tpl, {
      ...branding,
      ..._commonValues(data, contexto: contexto),
      'nome_talhao': RelatorioHtmlRenderer.escapeHtml(nomeTalhao),
      'tamanho_ha': tamanhoHa,
      'produtividade_valor': data['produtividade_valor']?.toString() ?? '',
      'produtividade_unidade': _esc(data, 'produtividade_unidade'),
      'conclusao': RelatorioHtmlRenderer.escapeHtml(conclusao),
      'roi_calculado': data['roi_calculado']?.toString() ?? '',
      'roi_investimento': data['roi_investimento']?.toString() ?? '',
      'roi_retorno': data['roi_retorno']?.toString() ?? '',
    });

    final blocosHtml = StringBuffer(
      await _renderBlocosHtml(
        avaliacoesLivres,
        fetchRemoteBytes: fetchRemoteBytes,
      ),
    );
    if (avaliacoesLivres.isEmpty) {
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

    return RelatorioHtmlRenderer.completeRender(tpl, asFragment: asFragment);
  }

  static Future<Map<String, String>> _branding(Map<String, dynamic> data) {
    return RelatorioHtmlRenderer.brandingPlaceholders(
      customBrandName: data['report_brand_name'] as String?,
      customLogoPath: data['report_logo_path'] as String?,
      consultantName: data['nome_vendedor'] as String?,
      consultantRole: 'Consultoria',
    );
  }

  /// Conclusão técnica do case; `conclusao` só entra quando a técnica está vazia.
  static String _conclusaoTexto(Map<String, dynamic> data) =>
      [data['conclusao_tecnica'], data['conclusao']]
          .map((v) => (v as String?)?.trim() ?? '')
          .firstWhere((v) => v.isNotEmpty, orElse: () => '');

  static Future<Map<String, dynamic>> _withMunicipioUf(
    Map<String, dynamic> data, {
    Future<String?> Function(double lat, double lng)? resolveUf,
  }) async {
    final texto = (data['localizacao_texto'] as String?)?.trim() ?? '';
    if (texto.isEmpty || MunicipioUf.hasUf(texto)) return data;
    final lat = RelatorioHtmlRenderer.readCoordinate(data['lat']);
    final lng = RelatorioHtmlRenderer.readCoordinate(data['lng']);
    if (lat == null || lng == null) return data;
    final resolver =
        resolveUf ??
        (double la, double ln) =>
            ReverseGeocoder.instance.resolveUf(latitude: la, longitude: ln);
    final uf = await resolver(lat, lng);
    final completo = MunicipioUf.compose(texto, uf);
    if (completo == texto) return data;
    return {...data, 'localizacao_texto': completo};
  }

  /// Linha de contexto do timbre: `[extra ·] Município · data`.
  /// O produto tem linha própria de destaque (`sf-product`) no timbre.
  static String _contexto(Map<String, dynamic> data, {String extra = ''}) {
    final dataCase = _parseDate(data['data_case'] as String?);
    return [extra, data['localizacao_texto'] as String?]
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
      'ficha_dados':
          (data['lat'] != null && data['lng'] != null) ||
          hasText('telefone_vendedor'),
      'descricao': hasText('descricao'),
      'nome_vendedor': hasText('nome_vendedor'),
      'telefone_vendedor': hasText('telefone_vendedor'),
      'criado_em': hasText('criado_em'),
    };
    return _resolveFlags(template, conditions);
  }

  static Map<String, String> _commonValues(
    Map<String, dynamic> data, {
    required String contexto,
  }) {
    final status = (data['status'] as String?)?.trim() ?? '';
    return {
      'contexto_linha': contexto,
      'produtor_fazenda': _esc(data, 'produtor_fazenda'),
      'produto_utilizado': _esc(data, 'produto_utilizado'),
      'localizacao_texto': _esc(data, 'localizacao_texto'),
      'visibilidade_label': RelatorioHtmlRenderer.escapeHtml(
        _visibilidadeLabel(data['visibilidade'] as String?),
      ),
      'status_label': RelatorioHtmlRenderer.escapeHtml(_statusLabel(status)),
      'status_dot': _statusDot(status),
      'descricao': _esc(data, 'descricao'),
      'nome_vendedor': _esc(data, 'nome_vendedor'),
      'telefone_vendedor': _esc(data, 'telefone_vendedor'),
      'emitido_em': _formatDateSafe(DateTime.now()),
      'criado_em_formatado': _parseDate(data['criado_em'] as String?),
      'data_case_formatado': _parseDate(data['data_case'] as String?),
      'localizacao_mapa': _localizacaoMapa(data),
    };
  }

  static String _localizacaoMapa(Map<String, dynamic> data) {
    final lat = RelatorioHtmlRenderer.readCoordinate(data['lat']);
    final lng = RelatorioHtmlRenderer.readCoordinate(data['lng']);
    if (lat == null || lng == null) {
      return '';
    }
    return RelatorioHtmlRenderer.mapLocationAnchor(lat, lng);
  }

  static const _statusLabels = {
    'draft': 'Rascunho',
    'rascunho': 'Rascunho',
    'pending_sync': 'Aguardando sincronização',
    'published': 'Publicado',
    'publicado': 'Publicado',
    'archived': 'Arquivado',
    'arquivado': 'Arquivado',
  };

  static String _statusLabel(String status) =>
      _statusLabels[status] ?? RelatorioHtmlRenderer.humanizeKey(status);

  static String _statusDot(String status) =>
      const {
        'published': 'ok',
        'publicado': 'ok',
        'pending_sync': 'media',
      }[status] ??
      'draft';

  static const _visibilidadeLabels = {
    'ouro': 'Plano Ouro',
    'prata': 'Plano Prata',
    'bronze': 'Plano Bronze',
    'publico': 'Público',
    'privado': 'Privado',
  };

  static String _visibilidadeLabel(String? visibilidade) {
    final value = visibilidade?.trim().toLowerCase() ?? '';
    return _visibilidadeLabels[value] ??
        RelatorioHtmlRenderer.humanizeKey(value);
  }

  static Future<String> _renderBlocosHtml(
    List<_MarketingAvaliacaoData> blocos, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
    bool ocultarLadosSemFoto = false,
  }) async {
    final partes = await Future.wait([
      for (var i = 0; i < blocos.length; i++)
        _renderAvaliacaoLivre(
          blocos[i],
          i + 1,
          fetchRemoteBytes: fetchRemoteBytes,
          ocultarLadosSemFoto: ocultarLadosSemFoto,
        ),
    ]);
    return partes.join();
  }

  static Future<String> _renderAvaliacaoLivre(
    _MarketingAvaliacaoData data,
    int ordem, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
    bool ocultarLadosSemFoto = false,
  }) async {
    final nomeA = RelatorioHtmlRenderer.escapeHtml(data.nomeLadoA);
    final nomeB = RelatorioHtmlRenderer.escapeHtml(data.nomeLadoB);
    final parametrosHtml = _renderParametrosHtml(
      data.parametros,
      nomeA: nomeA,
      nomeB: nomeB,
    );
    final titulo = data.titulo.trim().isEmpty
        ? 'Avaliação $ordem'
        : data.titulo.trim();
    final observacoes = data.observacoes?.trim() ?? '';

    final lados = [
      ('a', data.nomeLadoA, data.fotoLadoAPath),
      ('b', data.nomeLadoB, data.fotoLadoBPath),
      ('c', data.nomeLadoC, data.fotoLadoCPath),
    ];
    final figuras = <String>[];
    for (var i = 0; i < lados.length; i++) {
      final (lado, nome, foto) = lados[i];
      final temFoto = foto?.trim().isNotEmpty == true;
      // Lado C só existe com foto; A/B mantêm o espaço comparativo na avaliação.
      final obrigatorio = !ocultarLadosSemFoto && i < 2;
      if (!temFoto && !obrigatorio) continue;
      figuras.add(
        await _ladoFigure(
          ordem,
          lado,
          nome,
          foto,
          data.cultura,
          fetchRemoteBytes: fetchRemoteBytes,
          larguraTotal: i == 2 && figuras.length == 2,
        ),
      );
    }
    final fotosHtml = figuras.isEmpty
        ? ''
        : '<div class="sf-figure-grid mk-compare${figuras.length == 1 ? ' uma-foto' : ''}">'
              '${figuras.join()}</div>';
    final mediaHtml = data.parametros.isEmpty
        ? ''
        : '<span class="mk-avaliacao-media">Média <strong>${_formatSigned(data.mediaGanhoPercent)}%</strong></span>';

    return '''
    <article class="mk-avaliacao avaliacao-block">
      <div class="mk-avaliacao-head">
        <span class="mk-avaliacao-title">${RelatorioHtmlRenderer.escapeHtml(titulo)}</span>
        $mediaHtml
      </div>
      $fotosHtml
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
    bool larguraTotal = false,
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
        <figure class="sf-figure lado"${larguraTotal ? ' style="grid-column: 1 / -1;"' : ''}>
          $fotoHtml
          <figcaption>$legenda</figcaption>
        </figure>
    ''';
  }

  static String _parseDate(String? iso) {
    try {
      return iso == null
          ? ''
          : RelatorioHtmlRenderer.formatDate(DateTime.parse(iso));
    } catch (_) {
      return iso ?? '';
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

  static String _esc(Map<String, dynamic> data, String key) =>
      RelatorioHtmlRenderer.escapeHtml(data[key] as String? ?? '');

  static String _resolveFlags(String template, Map<String, bool> flags) {
    var current = template;
    for (final entry in flags.entries) {
      current = _resolveAllIfBlocks(current, entry.key, include: entry.value);
    }
    return current;
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

  /// Rótulo da coluna "com produto": usa o nome real do produto do case.
  static String _produtoRotulo(String? produto) {
    final nome = produto?.trim() ?? '';
    return RelatorioHtmlRenderer.escapeHtml(
      nome.isEmpty ? 'Com produto' : 'Com $nome',
    );
  }

  /// Ganho relativo à testemunha, ex.: "+10,0%". Vazio sem base de cálculo.
  static String _ganhoPercentLabel(_MarketingRoiData? roi) {
    if (roi == null || roi.prodSemProduto <= 0) return '';
    final pct = roi.ganhoScHa / roi.prodSemProduto * 100;
    return '${_formatSigned(pct)}%';
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

  /// [nomeA]/[nomeB] (já escapados) prefixam os valores quando o bloco tem
  /// rótulos de lado; o par legado não tem e mostra só os números.
  static String _renderParametrosHtml(
    List<_MarketingParametroData> parametros, {
    String nomeA = '',
    String nomeB = '',
  }) {
    String lado(String nome) => nome.isEmpty ? '' : '$nome ';
    return parametros.map((parametro) {
      final unidade = parametro.unidade == null || parametro.unidade!.isEmpty
          ? ''
          : ' ${RelatorioHtmlRenderer.escapeHtml(parametro.unidade)}';
      return _parametroRow(
        parametro,
        sub:
            '${lado(nomeA)}${_formatNumber(parametro.testemunha)} → '
            '${lado(nomeB)}${_formatNumber(parametro.teste)}$unidade',
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
  final String nomeLadoC;
  final String? fotoLadoAPath;
  final String? fotoLadoBPath;
  final String? fotoLadoCPath;
  final String? cultura;
  final List<_MarketingParametroData> parametros;
  final String? observacoes;

  const _MarketingAvaliacaoData({
    required this.titulo,
    required this.nomeLadoA,
    required this.nomeLadoB,
    required this.nomeLadoC,
    this.fotoLadoAPath,
    this.fotoLadoBPath,
    this.fotoLadoCPath,
    this.cultura,
    this.parametros = const [],
    this.observacoes,
  });

  bool get temTexto => observacoes?.trim().isNotEmpty == true;

  bool get temConteudo =>
      parametros.isNotEmpty ||
      [
        fotoLadoAPath,
        fotoLadoBPath,
        fotoLadoCPath,
      ].any((foto) => foto?.trim().isNotEmpty == true);

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
          nomeLadoC: _nonEmpty(map['nome_lado_c'] as String?, 'Lado C'),
          fotoLadoAPath: map['foto_lado_a_path'] as String?,
          fotoLadoBPath: map['foto_lado_b_path'] as String?,
          fotoLadoCPath: map['foto_lado_c_path'] as String?,
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
