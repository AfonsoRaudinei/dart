class RoiBloco {
  final double investimento;
  final double retorno;
  final double roiCalculado;

  const RoiBloco({
    required this.investimento,
    required this.retorno,
    required this.roiCalculado,
  });

  Map<String, dynamic> toJson() {
    return {
      'roi_investimento': investimento,
      'roi_retorno': retorno,
      'roi_calculado': roiCalculado,
    };
  }

  factory RoiBloco.fromJson(Map<String, dynamic> json) {
    return RoiBloco(
      investimento: (json['roi_investimento'] as num?)?.toDouble() ?? 0.0,
      retorno: (json['roi_retorno'] as num?)?.toDouble() ?? 0.0,
      roiCalculado: (json['roi_calculado'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
