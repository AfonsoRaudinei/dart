import '../entities/carteira_tipo_produto.dart';

/// Tipos de produto padrão e helpers de retrocompatibilidade.
///
/// A UI carrega tipos dinâmicos de `carteira_tipos_produto`; este arquivo
/// mantém os seeds e fallbacks para categorias legadas.
class UnidadeCategoria {
  UnidadeCategoria._();

  static const defaultCodigo = 'realPorHa';
  static const defaultLabel = r'R$/ha';

  static const List<({String codigo, String label, bool converteSacasHa})>
  seeds = [
    (codigo: 'realPorHa', label: r'R$/ha', converteSacasHa: true),
    (codigo: 'toneladaPorHa', label: 'ton/ha', converteSacasHa: false),
    (codigo: 'bigBag', label: 'Big Bag', converteSacasHa: false),
    (codigo: 'sacas60k', label: 'Sacas 60k', converteSacasHa: false),
    (
      codigo: 'sacas500milSementes',
      label: 'Sacas 500 mil sementes',
      converteSacasHa: false,
    ),
    // Meta em valor total (ex.: adjuvantes), sem multiplicar pela área.
    (codigo: 'reaisTotal', label: r'R$ total', converteSacasHa: false),
  ];

  static String labelForCodigo(String codigo) {
    for (final seed in seeds) {
      if (seed.codigo == codigo) return seed.label;
    }
    return codigo;
  }

  static bool converteSacasHaForCodigo(String codigo) {
    for (final seed in seeds) {
      if (seed.codigo == codigo) return seed.converteSacasHa;
    }
    return false;
  }

  static List<CarteiraTipoProduto> seedEntities({
    required String userId,
    required DateTime now,
  }) {
    return seedsFaltantes(
      userId: userId,
      now: now,
      codigosExistentes: const <String>{},
    );
  }

  /// Seeds de sistema que o usuário ainda não tem.
  ///
  /// Permite que contas antigas recebam unidades novas (ex.: sorgo em
  /// sacas de 500 mil sementes) sem recriar nem alterar as já existentes.
  static List<CarteiraTipoProduto> seedsFaltantes({
    required String userId,
    required DateTime now,
    required Set<String> codigosExistentes,
  }) {
    return [
      for (var i = 0; i < seeds.length; i++)
        if (!codigosExistentes.contains(seeds[i].codigo))
          CarteiraTipoProduto(
            id: 'seed-${seeds[i].codigo}-$userId',
            userId: userId,
            codigo: seeds[i].codigo,
            label: seeds[i].label,
            converteSacasHa: seeds[i].converteSacasHa,
            sistema: true,
            ordem: i,
            createdAt: now,
            updatedAt: now,
          ),
    ];
  }
}
