import '../enums/avaliacao_layout.dart';
import 'avaliacao_lado.dart';

class AvaliacaoBloco {
  final String id;
  final String caseId;
  final int ordem;
  final AvaliacaoLayout layout;
  final bool colapsado;
  final AvaliacaoLado ladoA;
  final AvaliacaoLado ladoB;

  const AvaliacaoBloco({
    required this.id,
    required this.caseId,
    required this.ordem,
    required this.layout,
    required this.colapsado,
    required this.ladoA,
    required this.ladoB,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'case_id': caseId,
      'ordem': ordem,
      'layout': layout.toValue(),
      'colapsado': colapsado,
      'lado_a_label': ladoA.label,
      'lado_a_foto_url': ladoA.fotoUrl,
      'lado_a_cultura': ladoA.tipoCultura,
      'lado_a_obs': ladoA.observacoes,
      'lado_b_label': ladoB.label,
      'lado_b_foto_url': ladoB.fotoUrl,
      'lado_b_cultura': ladoB.tipoCultura,
      'lado_b_obs': ladoB.observacoes,
    };
  }

  factory AvaliacaoBloco.fromJson(Map<String, dynamic> json) {
    return AvaliacaoBloco(
      id: json['id'] as String,
      caseId: json['case_id'] as String,
      ordem: json['ordem'] as int? ?? 0,
      layout: AvaliacaoLayout.fromString(
        json['layout'] as String? ?? 'duas_fotos',
      ),
      colapsado: json['colapsado'] as bool? ?? false,
      ladoA: AvaliacaoLado(
        label: json['lado_a_label'] as String? ?? 'Produto A',
        fotoUrl: json['lado_a_foto_url'] as String?,
        tipoCultura: json['lado_a_cultura'] as String?,
        observacoes: json['lado_a_obs'] as String?,
      ),
      ladoB: AvaliacaoLado(
        label: json['lado_b_label'] as String? ?? 'Produto B',
        fotoUrl: json['lado_b_foto_url'] as String?,
        tipoCultura: json['lado_b_cultura'] as String?,
        observacoes: json['lado_b_obs'] as String?,
      ),
    );
  }
}
