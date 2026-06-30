// ADR-012 — planos/domain/entities/referral_code.dart

/// Código de indicação único por usuário.
/// Gerado automaticamente no cadastro ou na primeira visita à tela de indicações.
class ReferralCode {
  final String id;
  final String userId;
  final String code;

  /// Total de indicações que converterem para pagamento confirmado.
  final int indicacoesValidadas;
  final DateTime criadoEm;

  const ReferralCode({
    required this.id,
    required this.userId,
    required this.code,
    required this.indicacoesValidadas,
    required this.criadoEm,
  });

  factory ReferralCode.fromJson(Map<String, dynamic> json) {
    return ReferralCode(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      code: json['code'] as String,
      indicacoesValidadas: json['indicacoes_validadas'] as int,
      criadoEm: DateTime.parse(json['criado_em'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'user_id': userId,
    'code': code,
    'indicacoes_validadas': indicacoesValidadas,
    'criado_em': criadoEm.toIso8601String(),
  };
}
