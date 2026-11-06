import '../domain/occurrence_recomendacao_ordem.dart';
import 'relatorio_html_renderer.dart';

/// Seção "Ordem de aplicação" do HTML da ocorrência (ADR-056).
///
/// O HTML vai no link público do relatório: todo valor sai escapado.
class OcorrenciaHtmlOrdemAplicacao {
  const OcorrenciaHtmlOrdemAplicacao(this.ordem);

  /// Três campos vencem; sem eles, o texto legado `recomendacoes` vira ação.
  factory OcorrenciaHtmlOrdemAplicacao.fromData(Map<String, dynamic> data) {
    return OcorrenciaHtmlOrdemAplicacao(
      OccurrenceRecomendacaoOrdem.resolve(
        acao: data['recomendacao_acao'] as String?,
        dose: data['recomendacao_dose'] as String?,
        quando: data['recomendacao_quando'] as String?,
        legacy: data['recomendacoes'] as String?,
      ),
    );
  }

  final OccurrenceRecomendacaoOrdem ordem;

  Map<String, String> get placeholders => {
    'recomendacao_acao': RelatorioHtmlRenderer.escapeHtml(ordem.acao),
    'recomendacao_dose': RelatorioHtmlRenderer.escapeHtml(ordem.dose),
    'recomendacao_quando': RelatorioHtmlRenderer.escapeHtml(ordem.quando),
  };

  String resolveIfs(
    String tpl,
    String Function(String tpl, String condition, bool include) resolveIf,
  ) {
    var result = resolveIf(tpl, 'recomendacao_acao', ordem.acao != null);
    result = resolveIf(result, 'recomendacao_dose', ordem.dose != null);
    result = resolveIf(result, 'recomendacao_quando', ordem.quando != null);
    return resolveIf(result, 'ordem_aplicacao', !ordem.isEmpty);
  }
}
