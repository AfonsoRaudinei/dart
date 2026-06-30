// ADR-012 — planos/domain/enums/plano_origem.dart
enum PlanoOrigem {
  pagamento,
  indicacao;

  String get label {
    switch (this) {
      case PlanoOrigem.pagamento:
        return 'Pagamento';
      case PlanoOrigem.indicacao:
        return 'Indicação';
    }
  }

  static PlanoOrigem fromString(String value) {
    return PlanoOrigem.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('PlanoOrigem inválido: $value'),
    );
  }
}
