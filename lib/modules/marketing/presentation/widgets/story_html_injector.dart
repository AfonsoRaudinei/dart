import 'package:intl/intl.dart';

import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/entities/marketing_roi_calculation.dart';
import '../../domain/enums/case_tipo.dart';

/// Injeta dados do [MarketingCase] nos marcadores do `assets/story.html`.
///
/// Formatos suportados:
/// - `<!--MARCADOR-->textoDefault` → valor (ou `—` se vazio)
/// - `{{FOTO_BASE64}}` / `{{FOTO_URL}}` / `{{LOGO_URL}}` etc.
///
/// Valores textuais livres passam por [RelatorioHtmlRenderer.escapeHtml].
/// Números formatados, URLs e data URIs de foto/logo não são escapados.
String injectStoryData(
  String html,
  MarketingCase marketingCase, {
  String? fotoSrc,
  String? fotoAntesSrc,
  String? fotoDepoisSrc,
  String? logoSrc,
}) {
  final roi = marketingCase.computeRoi();
  final ganho = _Ganho.from(marketingCase, roi);
  final roiTexto = _Roi.from(marketingCase, roi);
  final unidade = _unidadeText(marketingCase);
  final roiSacas = roi != null ? _formatNumber(roi.roiEmSacasHa) : '—';
  final roiSacasUnidade = roi != null && unidade.isNotEmpty
      ? '$unidade pagas'
      : '';
  final areaRaw = _areaText(marketingCase);
  final safra = _safraText(marketingCase);
  final produtorRaw = marketingCase.produtorFazenda.trim();
  final inicialRaw = produtorRaw.isEmpty ? '—' : produtorRaw[0].toUpperCase();
  final municipioRaw = marketingCase.localizacaoTexto.trim().isEmpty
      ? '—'
      : marketingCase.localizacaoTexto.trim();
  final depoimentoRaw = _firstNonEmpty([
    marketingCase.conclusaoTecnica,
    marketingCase.conclusao,
    marketingCase.descricao,
  ]);
  final consultorRaw = _orDash(marketingCase.nomeVendedor);
  final produtoRaw = marketingCase.produtoUtilizado.trim().isEmpty
      ? '—'
      : marketingCase.produtoUtilizado.trim();
  final categoriaRaw = _categoriaLabel(marketingCase.tipo);
  final testemunha = marketingCase.prodSemProduto != null
      ? _formatNumber(marketingCase.prodSemProduto!)
      : '—';
  final comProduto = marketingCase.prodComProduto != null
      ? _formatNumber(marketingCase.prodComProduto!)
      : '—';

  // Texto livre do usuário → escape. Numéricos / safra / ROI formatado → intactos.
  final municipio = _escapeText(municipioRaw);
  final produtor = produtorRaw.isEmpty ? '—' : _escapeText(produtorRaw);
  final produto = _escapeText(produtoRaw);
  final depoimento = _escapeText(depoimentoRaw);
  final consultor = _escapeText(consultorRaw);
  final categoria = _escapeText(categoriaRaw);
  final area = _escapeText(areaRaw);
  final inicial = _escapeText(inicialRaw);
  // ganhoProdutividade pode ser texto livre; escape é no-op em números.
  final ganhoEscaped = _escapeText(ganho.valor);

  final markers = <String, String>{
    'LOCALIZAÇÃO': municipio,
    'MUNICIPIO': municipio,
    'PRODUTOR': produtor,
    'FAZENDA': produtor,
    'PRODUTO': produto,
    'GANHO_SINAL': ganho.sinal,
    'GANHO': ganhoEscaped,
    'GANHO_UNIDADE': _escapeText(ganho.unidade),
    'GANHO_TITULO': _escapeText(ganho.titulo),
    'GANHO_BASE': _escapeText(ganho.base),
    'GANHO_ROTULO': _escapeText(ganho.rotulo),
    'UNIDADE': _escapeText(unidade),
    'ROI_VALOR': roiTexto.valor,
    'ROI_SUFIXO': roiTexto.sufixo,
    'ROI_UNIDADE': roiTexto.unidade,
    'ROI_SACAS': roiSacas,
    'ROI_SACAS_UNIDADE': _escapeText(roiSacasUnidade),
    'AREA': area,
    'AREA_UNIDADE': marketingCase.tamanhoHa != null ? 'hectares' : '',
    'SAFRA': safra,
    'DEPOIMENTO': depoimento,
    'INICIAL': inicial,
    'CONSULTOR': consultor,
    'CATEGORIA': categoria,
    'TESTEMUNHA': testemunha,
    'COM_PRODUTO': comProduto,
  };

  // Um único passe — evita que um valor injetado seja engolido pelo próximo.
  var out = html.replaceAllMapped(RegExp('<!--([A-ZÁÉÍÓÚÂÊÔÃÕÇ_]+)-->[^<]*'), (
    match,
  ) {
    final key = match.group(1)!;
    return markers[key] ?? match.group(0)!;
  });

  // Verde é afirmação de ganho: um resultado negativo não pode sair verde,
  // nem no número nem na faixa do card.
  if (ganho.negativo) {
    out = out.replaceAll('metric-value positive', 'metric-value negative');
    out = out.replaceAll('metric-card gain', 'metric-card loss');
  }

  final logo = logoSrc?.trim() ?? '';
  out = out.replaceAll('{{LOGO_URL}}', logo);

  final principal = fotoSrc?.trim() ?? '';
  out = out.replaceAll('{{FOTO_BASE64}}', principal);
  out = out.replaceAll('{{FOTO_URL}}', principal);
  if (principal.isNotEmpty) {
    out = _replacePhotoPlaceholder(
      out,
      className: 'hero-photo-placeholder',
      src: principal,
      alt: 'Foto do Resultado',
    );
  }

  final antes = fotoAntesSrc?.trim() ?? '';
  out = out.replaceAll('{{FOTO_ANTES_BASE64}}', antes);
  if (antes.isNotEmpty) {
    out = _replacePhotoPlaceholder(
      out,
      className: 'compare-placeholder before',
      src: antes,
      alt: 'Foto Antes',
    );
  }

  final depois = fotoDepoisSrc?.trim() ?? '';
  out = out.replaceAll('{{FOTO_DEPOIS_BASE64}}', depois);
  if (depois.isNotEmpty) {
    out = _replacePhotoPlaceholder(
      out,
      className: 'compare-placeholder after',
      src: depois,
      alt: 'Foto Depois',
    );
  }

  return out;
}

String _replacePhotoPlaceholder(
  String html, {
  required String className,
  required String src,
  required String alt,
}) {
  final escapedClass = RegExp.escape(className);
  final pattern = RegExp(
    '<div class="$escapedClass"[\\s\\S]*?</div>',
    multiLine: true,
  );
  final img =
      '<img src="$src" alt="$alt" style="width:100%;height:100%;object-fit:cover;display:block;">';
  return html.replaceFirst(pattern, img);
}

/// Ganho quebrado em sinal, magnitude e unidade — o template não prefixa
/// sinal nem unidade, senão um ganho negativo vira "+-3,4 sc/ha".
class _Ganho {
  const _Ganho({
    this.sinal = '',
    required this.valor,
    this.unidade = '',
    required this.titulo,
    this.base = '',
    required this.rotulo,
    this.negativo = false,
  });

  final String sinal;
  final String valor;
  final String unidade;

  /// Título e base do slide 1, e rótulo do card: o número nem sempre é um
  /// incremento sobre testemunha, e o texto fixo dizia que sempre era.
  final String titulo;
  final String base;
  final String rotulo;
  final bool negativo;

  static const _tituloIncremento = 'Incremento de Produtividade';

  static _Ganho from(MarketingCase c, MarketingRoiCalculation? roi) {
    final livre = c.ganhoProdutividade?.trim();
    if (livre != null && livre.isNotEmpty) {
      // Texto livre do consultor já carrega sinal e unidade próprios.
      return _Ganho(
        valor: livre,
        titulo: _tituloIncremento,
        rotulo: 'Ganho',
        negativo: livre.startsWith('-') || livre.startsWith('−'),
      );
    }
    final unidade = _unidadeText(c);
    if (roi != null) {
      return _Ganho(
        sinal: _sinal(roi.ganhoScHa),
        valor: _formatNumber(roi.ganhoScHa.abs()),
        unidade: unidade,
        titulo: _tituloIncremento,
        base: 'sobre a testemunha',
        rotulo: 'Ganho',
        negativo: roi.ganhoScHa < 0,
      );
    }
    if (c.produtividadeValor != null) {
      // Produtividade absoluta, não incremento: sem sinal e sem "sobre a
      // testemunha", que afirmariam uma comparação que não existe.
      return _Ganho(
        valor: _formatNumber(c.produtividadeValor!),
        unidade: unidade,
        titulo: 'Produtividade',
        rotulo: 'Produtividade',
      );
    }
    if (c.mediaGanhoPercent != 0) {
      return _Ganho(
        sinal: _sinal(c.mediaGanhoPercent),
        valor: _formatNumber(c.mediaGanhoPercent.abs()),
        unidade: '%',
        titulo: 'Ganho Médio',
        base: 'média dos parâmetros',
        rotulo: 'Ganho médio',
        negativo: c.mediaGanhoPercent < 0,
      );
    }
    return const _Ganho(valor: '—', titulo: _tituloIncremento, rotulo: 'Ganho');
  }
}

/// ROI com sufixo e unidade próprios: o bloco `RoiBloco.roiCalculado` é
/// percentual (`(retorno-investimento)/investimento*100`), não R\$/ha.
class _Roi {
  const _Roi(this.valor, this.sufixo, this.unidade);

  final String valor;
  final String sufixo;
  final String unidade;

  static _Roi from(MarketingCase c, MarketingRoiCalculation? roi) {
    if (roi != null) {
      return _Roi(
        'R\$ ${_formatMoney(roi.roiLiquidoRsHa)}',
        '/ha',
        'por hectare',
      );
    }
    final bloco = c.roi;
    if (bloco != null) {
      return _Roi(
        '${_formatNumber(bloco.roiCalculado)}%',
        '',
        'sobre o investimento',
      );
    }
    return const _Roi('—', '', '');
  }
}

String _sinal(double value) => value < 0 ? '−' : '+';

/// Unidade real do case — o template não pode fixar `sc/ha`.
String _unidadeText(MarketingCase c) {
  final texto = c.unidadeProdutividade?.trim();
  if (texto != null && texto.isNotEmpty) return texto;
  return c.produtividadeUnidade?.toValue() ?? '';
}

String _areaText(MarketingCase c) {
  if (c.tamanhoHa != null) return _formatNumber(c.tamanhoHa!);
  return '—';
}

String _safraText(MarketingCase c) {
  final base = c.dataCase ?? c.criadoEm;
  final y = base.year;
  final next = (y + 1) % 100;
  return '$y/${next.toString().padLeft(2, '0')}';
}

String _categoriaLabel(CaseTipo tipo) {
  switch (tipo) {
    case CaseTipo.resultado:
      return 'Resultado';
    case CaseTipo.antesDepois:
      return 'Antes & Depois';
    case CaseTipo.avaliacao:
      return 'Avaliação';
  }
}

String _escapeText(String value) {
  // Reutiliza o helper canônico do projeto (&#x27; para apóstrofo).
  return RelatorioHtmlRenderer.escapeHtml(value);
}

String _orDash(String? value) {
  final t = value?.trim();
  if (t == null || t.isEmpty) return '—';
  return t;
}

String _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    final t = v?.trim();
    if (t != null && t.isNotEmpty) return t;
  }
  return '—';
}

String _formatNumber(double value) {
  return NumberFormat('#,##0.0', 'pt_BR').format(value);
}

String _formatMoney(double value) {
  return NumberFormat('#,##0.00', 'pt_BR').format(value);
}
