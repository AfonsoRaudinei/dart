// ADR-012 — planos/domain/enums/plano_tipo.dart
enum PlanoTipo {
  bronze,
  prata,
  ouro;

  /// Limite de cases ativos que o plano permite publicar no mapa.
  /// Admin sobrescreve este valor via UserPlan.limiteCases.
  int get limiteCases {
    switch (this) {
      case PlanoTipo.bronze:
        return 3;
      case PlanoTipo.prata:
        return 5;
      case PlanoTipo.ouro:
        return 999999; // ilimitado
    }
  }

  /// Rótulo legível para exibição na UI.
  String get label {
    switch (this) {
      case PlanoTipo.bronze:
        return 'Bronze';
      case PlanoTipo.prata:
        return 'Prata';
      case PlanoTipo.ouro:
        return 'Ouro';
    }
  }

  /// Converte string do banco para enum.
  static PlanoTipo fromString(String value) {
    return PlanoTipo.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('PlanoTipo inválido: $value'),
    );
  }
}
