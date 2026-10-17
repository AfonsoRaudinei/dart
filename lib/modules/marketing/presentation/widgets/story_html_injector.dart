import '../../../../core/html_templates/relatorio_html_renderer.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/entities/marketing_roi_calculation.dart';
import '../../domain/enums/case_tipo.dart';

/// Injeta dados do [MarketingCase] nos marcadores do `assets/story.html`.
///
/// Ordem:
/// 1. Visibilidade a partir do case.
/// 2. Remove `<!--IF:CHAVE-->...<!--/IF:CHAVE-->` quando a chave é falsa.
/// 3. Mantém só o `<!--STORY:tipo-->` do case. Sem sentinela, o HTML fica.
/// 4. Substitui `<!--MARCADOR-->`.
/// 5. Fotos e logo.
///
/// Texto livre passa por [RelatorioHtmlRenderer.escapeHtml].
/// Números, safra, ROI formatado e data URIs não são escapados.
/// Cultura vem das avaliações livres e nunca vira traço.
String injectStoryData(
  String html,
  MarketingCase marketingCase, {
  String? fotoSrc,
  String? fotoAntesSrc,
  String? fotoDepoisSrc,
  String? logoSrc,
}) {
  final roi = marketingCase.computeRoi();
  final ganho = _ganhoText(marketingCase, roi);
  final roiValor = _roiValorText(roi, marketingCase);
  final roiSacas = _roiSacasText(roi, marketingCase);
  final areaRaw = _areaText(marketingCase);
  final safra = _safraText(marketingCase);
  final produtorRaw = marketingCase.produtorFazenda.trim();
  final inicialRaw = produtorRaw.isEmpty ? '—' : produtorRaw[0].toUpperCase();
  final municipioRaw = marketingCase.localizacaoTexto.trim();
  final depoimentoRaw = _firstNonEmpty([
    marketingCase.conclusaoTecnica,
    marketingCase.conclusao,
    marketingCase.descricao,
  ]);
  final consultorRaw = marketingCase.nomeVendedor?.trim() ?? '';
  final produtoRaw = marketingCase.produtoUtilizado.trim();
  final categoriaRaw = _categoriaLabel(marketingCase.tipo);
  final testemunha = marketingCase.prodSemProduto != null
      ? _formatNumber(marketingCase.prodSemProduto!)
      : '—';
  final comProduto = marketingCase.prodComProduto != null
      ? _formatNumber(marketingCase.prodComProduto!)
      : '—';

  String? cultura;
  for (final item in marketingCase.avaliacoesLivres) {
    final t = item.cultura?.trim();
    if (t != null && t.isNotEmpty) {
      cultura = t;
      break;
    }
  }

  final showGanho = _present(ganho);
  final showRoiValor = _present(roiValor);
  final showRoiSacas = _present(roiSacas);
  final showArea = _present(areaRaw);

  final flags = <String, bool>{
    'PRODUTO': produtoRaw.isNotEmpty,
    'CULTURA': cultura != null,
    'DEPOIMENTO': depoimentoRaw != null,
    'MUNICIPIO': municipioRaw.isNotEmpty,
    'PRODUTOR': produtorRaw.isNotEmpty,
    'CONSULTOR': consultorRaw.isNotEmpty,
    'GANHO': showGanho,
    'ROI_VALOR': showRoiValor,
    'ROI_SACAS': showRoiSacas,
    'AREA': showArea,
    'TESTEMUNHA': marketingCase.prodSemProduto != null,
    'COM_PRODUTO': marketingCase.prodComProduto != null,
  };

  var out = _stripFalseIfs(html, flags);
  out = _keepStoryBlock(out, marketingCase.tipo);

  final municipio = municipioRaw.isEmpty ? '—' : _escapeText(municipioRaw);
  final produtor = produtorRaw.isEmpty ? '—' : _escapeText(produtorRaw);
  final produto = produtoRaw.isEmpty ? '—' : _escapeText(produtoRaw);
  final depoimento = depoimentoRaw == null ? '—' : _escapeText(depoimentoRaw);
  final consultor = consultorRaw.isEmpty ? '—' : _escapeText(consultorRaw);
  final categoria = _escapeText(categoriaRaw);
  final area = showArea ? _escapeText(areaRaw) : '—';
  final inicial = _escapeText(inicialRaw);
  final ganhoEscaped = showGanho ? _escapeText(ganho) : '—';

  final markers = <String, String>{
    'LOCALIZAÇÃO': municipio,
    'MUNICIPIO': municipio,
    'PRODUTOR': produtor,
    'FAZENDA': produtor,
    'PRODUTO': produto,
    'GANHO': ganhoEscaped,
    'ROI_VALOR': showRoiValor ? roiValor : '—',
    'ROI_SACAS': showRoiSacas ? roiSacas : '—',
    'AREA': area,
    'SAFRA': safra,
    'DEPOIMENTO': depoimento,
    'INICIAL': inicial,
    'CONSULTOR': consultor,
    'CATEGORIA': categoria,
    'CULTURA': cultura == null ? '' : _escapeText(cultura),
    'TESTEMUNHA': testemunha,
    'COM_PRODUTO': comProduto,
  };

  // Um único passe — evita que um valor injetado seja engolido pelo próximo.
  out = out.replaceAllMapped(RegExp('<!--([A-ZÁÉÍÓÚÂÊÔÃÕÇ_]+)-->[^<]*'), (
    match,
  ) {
    final key = match.group(1)!;
    return markers[key] ?? match.group(0)!;
  });

  // Evita "R$ R$" quando o template já prefixa a moeda.
  out = out.replaceAll('R\$ R\$', 'R\$ ');

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

String _stripFalseIfs(String html, Map<String, bool> flags) {
  var out = html;
  for (final entry in flags.entries) {
    if (entry.value) continue;
    final key = RegExp.escape(entry.key);
    out = out.replaceAll(RegExp('<!--IF:$key-->[\\s\\S]*?<!--/IF:$key-->'), '');
  }
  return out;
}

String _keepStoryBlock(String html, CaseTipo tipo) {
  if (!html.contains('<!--STORY:')) return html;
  final keep = _storyKey(tipo);
  return html.replaceAllMapped(
    RegExp('<!--STORY:([a-z_]+)-->[\\s\\S]*?<!--/STORY:\\1-->'),
    (match) => match.group(1) == keep ? match.group(0)! : '',
  );
}

String _storyKey(CaseTipo tipo) {
  switch (tipo) {
    case CaseTipo.resultado:
      return 'resultado';
    case CaseTipo.antesDepois:
      return 'antes_depois';
    case CaseTipo.avaliacao:
      return 'avaliacao';
  }
}

bool _present(String value) {
  final t = value.trim();
  return t.isNotEmpty && t != '—' && t != '-' && t != '–';
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

String _ganhoText(MarketingCase c, MarketingRoiCalculation? roi) {
  if (c.ganhoProdutividade != null && c.ganhoProdutividade!.trim().isNotEmpty) {
    return c.ganhoProdutividade!.trim().replaceFirst(RegExp(r'^\+'), '');
  }
  if (roi != null) {
    return _formatNumber(roi.ganhoScHa);
  }
  if (c.produtividadeValor != null) {
    return _formatNumber(c.produtividadeValor!);
  }
  if (c.mediaGanhoPercent != 0) {
    return _formatNumber(c.mediaGanhoPercent);
  }
  return '—';
}

String _roiValorText(MarketingRoiCalculation? roi, MarketingCase c) {
  if (roi != null) {
    return 'R\$ ${_formatMoney(roi.roiLiquidoRsHa)}/ha';
  }
  if (c.roi != null) {
    return 'R\$ ${_formatMoney(c.roi!.roiCalculado)}';
  }
  return '—';
}

String _roiSacasText(MarketingRoiCalculation? roi, MarketingCase c) {
  if (roi != null) return _formatNumber(roi.roiEmSacasHa);
  if (c.roi != null) return _formatNumber(c.roi!.roiCalculado);
  return '—';
}

String _areaText(MarketingCase c) {
  if (c.nomeTalhao != null && c.nomeTalhao!.trim().isNotEmpty) {
    if (c.tamanhoHa != null) {
      return '${c.nomeTalhao!.trim()} · ${_formatNumber(c.tamanhoHa!)} ha';
    }
    return c.nomeTalhao!.trim();
  }
  if (c.tamanhoHa != null) {
    return _formatNumber(c.tamanhoHa!);
  }
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
  return RelatorioHtmlRenderer.escapeHtml(value);
}

String? _firstNonEmpty(List<String?> values) {
  for (final v in values) {
    final t = v?.trim();
    if (t != null && t.isNotEmpty) return t;
  }
  return null;
}

String _formatNumber(double value) {
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatMoney(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
