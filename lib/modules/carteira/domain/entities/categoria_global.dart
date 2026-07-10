import '../enums/unidade_categoria.dart';

/// Categoria global de produtos da carteira do agrônomo.
///
/// Cada categoria define a unidade de medida e o custo/referência
/// usado para calcular metas de venda por safra.
///
/// Campos legados (valorReal, valorDolar, sacasPorHa) mantidos
/// por retrocompatibilidade de banco — não usar em lógica nova.
/// ADR-022 — SoloForte
class CategoriaGlobal {
  final String id;
  final String userId;
  final String nome;
  final String cor;
  final bool ativo;
  final int ordem;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Código do tipo de produto (coluna `unidade` no SQLite).
  final String unidadeCodigo;

  /// Rótulo de exibição resolvido via [CarteiraTipoProduto].
  final String unidadeLabel;

  /// Indica se [custoSacasHa] se aplica a esta categoria.
  final bool converteSacasHa;

  /// Valor de referência para cálculo de meta.
  final double? valorReferencia;

  // ── Campos legados — mantidos apenas para leitura do banco ─────
  final double? valorReal;
  final double? valorDolar;
  final double? sacasPorHa;

  const CategoriaGlobal({
    required this.id,
    required this.userId,
    required this.nome,
    required this.cor,
    required this.ativo,
    required this.ordem,
    required this.createdAt,
    required this.updatedAt,
    this.unidadeCodigo = UnidadeCategoria.defaultCodigo,
    this.unidadeLabel = UnidadeCategoria.defaultLabel,
    this.converteSacasHa = true,
    this.valorReferencia,
    this.valorReal,
    this.valorDolar,
    this.sacasPorHa,
  });

  factory CategoriaGlobal.fromMap(
    Map<String, Object?> map, {
    String? unidadeLabel,
    bool? converteSacasHa,
  }) {
    final codigo = (map['unidade'] as String?) ?? UnidadeCategoria.defaultCodigo;
    return CategoriaGlobal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      nome: map['nome'] as String,
      cor: map['cor'] as String,
      ativo: (map['ativo'] as int? ?? 1) == 1,
      ordem: map['ordem'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      unidadeCodigo: codigo,
      unidadeLabel: unidadeLabel ?? UnidadeCategoria.labelForCodigo(codigo),
      converteSacasHa:
          converteSacasHa ?? UnidadeCategoria.converteSacasHaForCodigo(codigo),
      valorReferencia: (map['valor_referencia'] as num?)?.toDouble(),
      valorReal: (map['valor_real'] as num?)?.toDouble(),
      valorDolar: (map['valor_dolar'] as num?)?.toDouble(),
      sacasPorHa: (map['sacas_por_ha'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'nome': nome,
      'cor': cor,
      'ativo': ativo ? 1 : 0,
      'ordem': ordem,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'unidade': unidadeCodigo,
      'valor_referencia': valorReferencia,
      'valor_real': valorReal,
      'valor_dolar': valorDolar,
      'sacas_por_ha': sacasPorHa,
    };
  }

  /// Custo em sacas de grão por hectare.
  double? custoSacasHa(double valorGrao) {
    if (!converteSacasHa) return null;
    if (valorReferencia == null || valorReferencia! <= 0) return null;
    if (valorGrao <= 0) return null;
    return valorReferencia! / valorGrao;
  }

  CategoriaGlobal copyWith({
    String? nome,
    String? cor,
    bool? ativo,
    int? ordem,
    String? unidadeCodigo,
    String? unidadeLabel,
    bool? converteSacasHa,
    double? valorReferencia,
  }) {
    return CategoriaGlobal(
      id: id,
      userId: userId,
      nome: nome ?? this.nome,
      cor: cor ?? this.cor,
      ativo: ativo ?? this.ativo,
      ordem: ordem ?? this.ordem,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      unidadeCodigo: unidadeCodigo ?? this.unidadeCodigo,
      unidadeLabel: unidadeLabel ?? this.unidadeLabel,
      converteSacasHa: converteSacasHa ?? this.converteSacasHa,
      valorReferencia: valorReferencia ?? this.valorReferencia,
      valorReal: valorReal,
      valorDolar: valorDolar,
      sacasPorHa: sacasPorHa,
    );
  }
}
