class CategoriaGlobal {
  final String id;
  final String userId;
  final String nome;
  final String cor;
  final bool ativo;
  final int ordem;
  final DateTime createdAt;
  final DateTime updatedAt;
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
    this.valorReal,
    this.valorDolar,
    this.sacasPorHa,
  });

  double? get custoSacasHa {
    final real = valorReal;
    final sacas = sacasPorHa;
    if (real == null || sacas == null || sacas == 0) return null;
    return real / sacas;
  }

  double? get custoSacasHaUsd {
    final dolar = valorDolar;
    final sacas = sacasPorHa;
    if (dolar == null || sacas == null || sacas == 0) return null;
    return dolar / sacas;
  }

  CategoriaGlobal copyWith({
    String? nome,
    String? cor,
    bool? ativo,
    int? ordem,
    double? valorReal,
    double? valorDolar,
    double? sacasPorHa,
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
      valorReal: valorReal ?? this.valorReal,
      valorDolar: valorDolar ?? this.valorDolar,
      sacasPorHa: sacasPorHa ?? this.sacasPorHa,
    );
  }
}
