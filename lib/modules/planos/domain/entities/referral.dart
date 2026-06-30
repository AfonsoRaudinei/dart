// ADR-012 — planos/domain/entities/referral.dart
import '../enums/referral_status.dart';

/// Entidade de domínio — registro de indicação entre usuários.
class Referral {
  final String id;
  final String referrerId;
  final String referredId;
  final String code;
  final ReferralStatus status;
  final DateTime criadoEm;
  final DateTime? validadoEm;

  /// criadoEm + 30 dias, conforme ADR-012.
  final DateTime expiraEm;

  const Referral({
    required this.id,
    required this.referrerId,
    required this.referredId,
    required this.code,
    required this.status,
    required this.criadoEm,
    this.validadoEm,
    required this.expiraEm,
  });

  factory Referral.fromJson(Map<String, dynamic> json) {
    return Referral(
      id: json['id'] as String,
      referrerId: json['referrer_id'] as String,
      referredId: json['referred_id'] as String,
      code: json['code'] as String,
      status: ReferralStatus.fromString(json['status'] as String),
      criadoEm: DateTime.parse(json['criado_em'] as String),
      validadoEm: json['validado_em'] != null
          ? DateTime.parse(json['validado_em'] as String)
          : null,
      expiraEm: DateTime.parse(json['expira_em'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'referrer_id': referrerId,
    'referred_id': referredId,
    'code': code,
    'status': status.name,
    'criado_em': criadoEm.toIso8601String(),
    'validado_em': validadoEm?.toIso8601String(),
    'expira_em': expiraEm.toIso8601String(),
  };

  @override
  String toString() => 'Referral(id: $id, code: $code, status: ${status.name})';
}
