/// Ordem de aplicação da ocorrência (TBDC): ação, dose e janela.
///
/// O texto livre [legacy] permanece para leitores antigos. Na leitura, se os
/// três campos estão vazios e o legado tem texto, o valor aparece só em
/// [acao]. Na gravação, [mirrorLegacy] reescreve o legado quando algum dos
/// três está preenchido.
class OccurrenceRecomendacaoOrdem {
  const OccurrenceRecomendacaoOrdem({this.acao, this.dose, this.quando});

  final String? acao;
  final String? dose;
  final String? quando;

  static const sectionTitle = 'Ordem de aplicação';
  static const labelAcao = 'O que fazer';
  static const labelDose = 'Dose';
  static const labelQuando = 'Quando';

  bool get isEmpty => acao == null && dose == null && quando == null;

  List<({String label, String value})> get rows => [
    if (acao != null) (label: labelAcao, value: acao!),
    if (dose != null) (label: labelDose, value: dose!),
    if (quando != null) (label: labelQuando, value: quando!),
  ];

  /// Linhas rotuladas para a coluna legada `recomendacoes`.
  String? get legacyText {
    if (isEmpty) return null;
    return rows.map((row) => '${row.label}: ${row.value}').join('\n');
  }

  static String? normalize(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null;
    return trimmed;
  }

  /// Três campos preenchidos vencem. Legado só vira ação quando os três
  /// estão vazios — sem tentar repartir o texto antigo.
  static OccurrenceRecomendacaoOrdem resolve({
    String? acao,
    String? dose,
    String? quando,
    String? legacy,
  }) {
    final structured = OccurrenceRecomendacaoOrdem(
      acao: normalize(acao),
      dose: normalize(dose),
      quando: normalize(quando),
    );
    if (!structured.isEmpty) return structured;
    final legado = normalize(legacy);
    if (legado == null) return const OccurrenceRecomendacaoOrdem();
    return OccurrenceRecomendacaoOrdem(acao: legado);
  }

  /// Valor a persistir em `recomendacoes`.
  static String? mirrorLegacy({
    String? acao,
    String? dose,
    String? quando,
    String? legacy,
  }) {
    final structured = OccurrenceRecomendacaoOrdem(
      acao: normalize(acao),
      dose: normalize(dose),
      quando: normalize(quando),
    );
    return structured.legacyText ?? normalize(legacy);
  }
}
