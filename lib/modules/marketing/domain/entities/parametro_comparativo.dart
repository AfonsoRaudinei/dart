class ParametroComparativo {
  final String id;
  final String titulo;
  final double testemunha;
  final double teste;
  final String? unidade;

  const ParametroComparativo({
    required this.id,
    required this.titulo,
    required this.testemunha,
    required this.teste,
    this.unidade,
  });

  double get deltaPercent =>
      testemunha != 0 ? ((teste - testemunha) / testemunha) * 100 : 0.0;

  bool get isPositivo => deltaPercent > 0;

  bool get isNegativo => deltaPercent < 0;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'titulo': titulo,
      'testemunha': testemunha,
      'teste': teste,
      'unidade': unidade,
    };
  }

  factory ParametroComparativo.fromJson(Map<String, dynamic> json) {
    return ParametroComparativo(
      id: json['id'] as String,
      titulo: json['titulo'] as String? ?? '',
      testemunha: (json['testemunha'] as num?)?.toDouble() ?? 0.0,
      teste: (json['teste'] as num?)?.toDouble() ?? 0.0,
      unidade: json['unidade'] as String?,
    );
  }

  ParametroComparativo copyWith({
    String? id,
    String? titulo,
    double? testemunha,
    double? teste,
    String? unidade,
    bool clearUnidade = false,
  }) {
    return ParametroComparativo(
      id: id ?? this.id,
      titulo: titulo ?? this.titulo,
      testemunha: testemunha ?? this.testemunha,
      teste: teste ?? this.teste,
      unidade: clearUnidade ? null : unidade ?? this.unidade,
    );
  }
}
