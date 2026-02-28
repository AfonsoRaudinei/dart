enum PlanoMarketing {
  ouro,
  prata,
  bronze;

  factory PlanoMarketing.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'ouro':
        return PlanoMarketing.ouro;
      case 'prata':
        return PlanoMarketing.prata;
      case 'bronze':
        return PlanoMarketing.bronze;
      default:
        throw ArgumentError('Plano de marketing desconhecido: $value');
    }
  }

  String toValue() {
    return name;
  }
}
