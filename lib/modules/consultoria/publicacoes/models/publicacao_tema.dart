/// Enums de Publicação Técnica — ADR-009
///
/// Define o tema e a visibilidade de uma [PublicacaoTecnica].
library;

// ============================================================
// TEMA DA PUBLICAÇÃO
// ============================================================

/// Categorias temáticas de uma publicação técnica agronômica.
///
/// - [praga]: conteúdo sobre pragas e manejo integrado.
/// - [doenca]: doenças vegetais, fungos, vírus e bactérias.
/// - [solo]: análise, correção e fertilidade do solo.
/// - [fenologia]: estágios fenológicos das culturas.
/// - [recomendacao]: boas práticas e recomendações técnicas.
/// - [outro]: temas não classificados nas categorias acima.
enum PublicacaoTema {
  praga,
  doenca,
  solo,
  fenologia,
  recomendacao,
  outro;

  String toJson() => name;

  static PublicacaoTema fromJson(String json) => values.byName(json);
}

// ============================================================
// VISIBILIDADE DA PUBLICAÇÃO
// ============================================================

/// Define quem pode visualizar a publicação técnica na plataforma.
///
/// - [publica]: visível para todos os usuários da plataforma.
/// - [restrita]: visível apenas para o agrônomo e clientes vinculados.
enum PublicacaoVisibility {
  publica,
  restrita;

  String toJson() => name;

  static PublicacaoVisibility fromJson(String json) => values.byName(json);
}
