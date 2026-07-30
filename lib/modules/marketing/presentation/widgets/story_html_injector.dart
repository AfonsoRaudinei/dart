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
  final ganho = _ganhoText(marketingCase, roi);
  final roiValor = _roiValorText(roi, marketingCase);
  final roiSacas = roi != null ? _formatNumber(roi.roiEmSacasHa) : '—';
  final areaRaw = _areaText(marketingCase);
  final safra = _safraText(marketingCase);
  final produtorRaw = marketingCase.produtorFazenda.trim();
  final inicialRaw =
      produtorRaw.isEmpty ? '—' : produtorRaw[0].toUpperCase();
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
  final ganhoEscaped = _escapeText(ganho);

  final markers = <String, String>{
    'LOCALIZAÇÃO': municipio,
    'MUNICIPIO': municipio,
    'PRODUTOR': produtor,
    'FAZENDA': produtor,
    'PRODUTO': produto,
    'GANHO': ganhoEscaped,
    'ROI_VALOR': roiValor,
    'ROI_SACAS': roiSacas,
    'AREA': area,
    'SAFRA': safra,
    'DEPOIMENTO': depoimento,
    'INICIAL': inicial,
    'CONSULTOR': consultor,
    'CATEGORIA': categoria,
    'CULTURA': '—',
    'TESTEMUNHA': testemunha,
    'COM_PRODUTO': comProduto,
  };

  // Um único passe — evita que um valor injetado seja engolido pelo próximo.
  var out = html.replaceAllMapped(
    RegExp('<!--([A-ZÁÉÍÓÚÂÊÔÃÕÇ_]+)-->[^<]*'),
    (match) {
      final key = match.group(1)!;
      return markers[key] ?? match.group(0)!;
    },
  );

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
  return value.toStringAsFixed(1).replaceAll('.', ',');
}

String _formatMoney(double value) {
  return value.toStringAsFixed(2).replaceAll('.', ',');
}
