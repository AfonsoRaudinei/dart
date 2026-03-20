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

  /// Unidade de medida desta categoria.
  /// Define como [valorReferencia] é interpretado.
  final UnidadeCategoria unidade;

  /// Valor de referência para cálculo de meta.
  ///
  /// Semântica depende de [unidade]:
  /// - [UnidadeCategoria.realPorHa] → custo em R$/ha
  /// - [UnidadeCategoria.toneladaPorHa] → toneladas por hectare
  /// - [UnidadeCategoria.bigBag] → quantidade absoluta de meta
  /// - [UnidadeCategoria.sacas60k] → quantidade absoluta de meta
  final double? valorReferencia;

  // ── Campos legados — mantidos apenas para leitura do banco ─────
  // Não usar em lógica nova. Serão removidos na v25.
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
    this.unidade = UnidadeCategoria.realPorHa,
    this.valorReferencia,
    // legados
    this.valorReal,
    this.valorDolar,
    this.sacasPorHa,
  });

  factory CategoriaGlobal.fromMap(Map<String, Object?> map) {
    return CategoriaGlobal(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      nome: map['nome'] as String,
      cor: map['cor'] as String,
      ativo: (map['ativo'] as int? ?? 1) == 1,
      ordem: map['ordem'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      unidade: UnidadeCategoria.fromDb(map['unidade'] as String?),
      valorReferencia: (map['valor_referencia'] as num?)?.toDouble(),
      // legados
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
      'unidade': unidade.dbValue,
      'valor_referencia': valorReferencia,
      // legados — persistir para retrocompat
      'valor_real': valorReal,
      'valor_dolar': valorDolar,
      'sacas_por_ha': sacasPorHa,
    };
  }

  /// Custo em sacas de grão por hectare.
  ///
  /// Só aplicável quando [unidade] == [UnidadeCategoria.realPorHa].
  /// Retorna null para outras unidades ou se [valorGrao] <= 0.
  double? custoSacasHa(double valorGrao) {
    if (unidade != UnidadeCategoria.realPorHa) return null;
    if (valorReferencia == null || valorReferencia! <= 0) return null;
    if (valorGrao <= 0) return null;
    return valorReferencia! / valorGrao;
  }

  CategoriaGlobal copyWith({
    String? nome,
    String? cor,
    bool? ativo,
    int? ordem,
    UnidadeCategoria? unidade,
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
      unidade: unidade ?? this.unidade,
      valorReferencia: valorReferencia ?? this.valorReferencia,
      // legados inalterados
      valorReal: valorReal,
      valorDolar: valorDolar,
      sacasPorHa: sacasPorHa,
    );
  }
}
