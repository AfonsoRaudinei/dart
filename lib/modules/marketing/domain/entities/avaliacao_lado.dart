class AvaliacaoLado {
  final String label;
  final String? fotoUrl;
  final String? tipoCultura;
  final String? observacoes;

  const AvaliacaoLado({
    required this.label,
    this.fotoUrl,
    this.tipoCultura,
    this.observacoes,
  });

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'foto_url': fotoUrl,
      'tipo_cultura': tipoCultura,
      'observacoes': observacoes,
    };
  }

  factory AvaliacaoLado.fromJson(Map<String, dynamic> json) {
    return AvaliacaoLado(
      label: json['label'] as String? ?? 'Desconhecido',
      fotoUrl: json['foto_url'] as String?,
      tipoCultura: json['tipo_cultura'] as String?,
      observacoes: json['observacoes'] as String?,
    );
  }
}
