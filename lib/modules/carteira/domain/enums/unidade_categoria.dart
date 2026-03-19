/// Define a unidade de medida de uma categoria de carteira.
///
/// Determina como o custo/meta é interpretado e exibido.
/// ADR-022 — SoloForte
enum UnidadeCategoria {
  /// Custo em R$ por hectare.
  /// Conversão: valorReferencia / valorGrao = sacas/ha
  realPorHa,

  /// Meta em toneladas por hectare (fertilizantes).
  /// Sem conversão para grão.
  toneladaPorHa,

  /// Meta em big bags (unidade absoluta — sementes de soja).
  /// 1 big bag = 5.000.000 sementes = 25 sacas de 200.000 sementes.
  bigBag,

  /// Meta em sacas de 60.000 sementes (sementes de milho).
  /// Unidade absoluta — não relacionada à área.
  sacas60k;

  /// Rótulo de exibição para o usuário.
  String get label {
    switch (this) {
      case UnidadeCategoria.realPorHa:
        return 'R\$/ha';
      case UnidadeCategoria.toneladaPorHa:
        return 'ton/ha';
      case UnidadeCategoria.bigBag:
        return 'Big Bag';
      case UnidadeCategoria.sacas60k:
        return 'Sacas 60k';
    }
  }

  /// Valor para persistência no SQLite.
  String get dbValue {
    switch (this) {
      case UnidadeCategoria.realPorHa:
        return 'realPorHa';
      case UnidadeCategoria.toneladaPorHa:
        return 'toneladaPorHa';
      case UnidadeCategoria.bigBag:
        return 'bigBag';
      case UnidadeCategoria.sacas60k:
        return 'sacas60k';
    }
  }

  /// Reconstrói a partir do valor salvo no SQLite.
  /// Retorna [realPorHa] como fallback seguro.
  static UnidadeCategoria fromDb(String? value) {
    switch (value) {
      case 'toneladaPorHa':
        return UnidadeCategoria.toneladaPorHa;
      case 'bigBag':
        return UnidadeCategoria.bigBag;
      case 'sacas60k':
        return UnidadeCategoria.sacas60k;
      default:
        return UnidadeCategoria.realPorHa;
    }
  }
}
