import '../domain/soy_nodulos.dart';
import 'relatorio_html_renderer.dart';

/// Barras coloridas (verde, amarelo, laranja, vermelho) do relatório de
/// ocorrência: urgência (3 níveis) e intensidade das métricas (0–3).
abstract final class OcorrenciaHtmlBarras {
  static const _niveis = ['Nenhum', 'Baixa', 'Média', 'Alta'];

  /// Urgência por classe (`baixa`, `media`, `alta`): 1, 2 ou 3 segmentos.
  /// Com [raw], classe desconhecida/vazia não gera barra.
  static String urgencia(String urgenciaClass, {bool raw = false}) {
    if (raw && !const {'alta', 'media', 'baixa'}.contains(urgenciaClass)) {
      return '';
    }
    final (filled, cor) = switch (urgenciaClass) {
      'alta' => (3, 'vermelho'),
      'media' => (2, 'laranja'),
      _ => (1, 'verde'),
    };
    return RelatorioHtmlRenderer.nivelBar(filled: filled, total: 3, cor: cor);
  }

  /// Valor de uma métrica: escala 0–3 vira barra + rótulo; o resto, texto.
  static String metrica(Object? valor) {
    final nivel = int.tryParse(valor.toString());
    if (nivel == null || nivel < 0 || nivel > 3) {
      return RelatorioHtmlRenderer.escapeHtml(valor.toString());
    }
    final barra = RelatorioHtmlRenderer.nivelBar(
      filled: nivel,
      total: 3,
      cor: RelatorioHtmlRenderer.corIntensidade(nivel),
      rotulo: _niveis[nivel],
    );
    return '$barra${_niveis[nivel]}';
  }

  /// Linha "rótulo + valor" de uma métrica. Nódulos mostram o texto da escolha
  /// (ex.: "Bom (10–30)"); as demais, a barra de intensidade.
  static String linhaMetrica(String chave, Object? valor) {
    final nodulo = nodulosValueLabel(chave, valor);
    final conteudo = nodulo != null
        ? RelatorioHtmlRenderer.escapeHtml(nodulo)
        : metrica(valor);
    final rotulo =
        kNodulosTitles[chave] ?? RelatorioHtmlRenderer.humanizeKey(chave);
    return '<div class="sf-row">'
        '<span class="sf-row-label">${RelatorioHtmlRenderer.escapeHtml(rotulo)}</span>'
        '<span class="sf-row-value">$conteudo</span>'
        '</div>';
  }
}
