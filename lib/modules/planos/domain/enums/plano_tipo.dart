// ADR-012 — planos/domain/enums/plano_tipo.dart
enum PlanoTipo {
  bronze,
  prata,
  ouro;

  /// Cota de cases **Bronze** publicáveis para contas neste plano pago ativo.
  int get cotaCasesBronze {
    switch (this) {
      case PlanoTipo.bronze:
      case PlanoTipo.prata:
      case PlanoTipo.ouro:
        return 5;
    }
  }

  /// Cota de cases **Prata** publicáveis para contas neste plano pago ativo.
  int get cotaCasesPrata {
    switch (this) {
      case PlanoTipo.bronze:
        return 0;
      case PlanoTipo.prata:
      case PlanoTipo.ouro:
        return 5;
    }
  }

  /// Cota de cases **Ouro** publicáveis para contas neste plano pago ativo.
  int get cotaCasesOuro {
    switch (this) {
      case PlanoTipo.bronze:
      case PlanoTipo.prata:
        return 0;
      case PlanoTipo.ouro:
        return 10;
    }
  }

  /// Soma das cotas por metal — legado para telas que exibem um número único.
  /// Não significa teto global nem ilimitado no Ouro.
  int get limiteCases =>
      cotaCasesBronze + cotaCasesPrata + cotaCasesOuro;

  /// Teto de talhões do Desenho sincronizados na nuvem (conta paga).
  ///
  /// `null` = ilimitado (Ouro). Grátis (`UserPlan` com `id == 'free'`) usa 0
  /// via [UserPlan.limiteTalhoesSincronizados], não este getter.
  int? get limiteTalhoesSincronizados {
    switch (this) {
      case PlanoTipo.bronze:
        return 150;
      case PlanoTipo.prata:
        return 500;
      case PlanoTipo.ouro:
        return null;
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