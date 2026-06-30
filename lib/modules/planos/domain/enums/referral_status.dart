// ADR-012 — planos/domain/enums/referral_status.dart
enum ReferralStatus {
  pendente,
  validada,
  expirada;

  static ReferralStatus fromString(String value) {
    return ReferralStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('ReferralStatus inválido: $value'),
    );
  }
}
