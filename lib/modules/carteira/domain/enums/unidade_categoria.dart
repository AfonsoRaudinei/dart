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
    return [
      for (var i = 0; i < seeds.length; i++)
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
