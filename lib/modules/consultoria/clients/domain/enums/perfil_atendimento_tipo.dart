/// Perfis do diagnóstico comercial (DISC simplificado).
enum PerfilAtendimentoTipo {
  pragmatico,
  analitico,
  afavel,
  expressivo;

  /// Chave persistida em SQLite / Supabase.
  String get storageKey => name;

  static const Set<String> allowedStorageKeys = {
    'pragmatico',
    'analitico',
    'afavel',
    'expressivo',
  };

  static PerfilAtendimentoTipo? fromStorageKey(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    for (final value in PerfilAtendimentoTipo.values) {
      if (value.storageKey == raw) return value;
    }
    return null;
  }

  String get labelDisplay {
    switch (this) {
      case PerfilAtendimentoTipo.pragmatico:
        return 'Pragmático';
      case PerfilAtendimentoTipo.analitico:
        return 'Analítico';
      case PerfilAtendimentoTipo.afavel:
        return 'Afável';
      case PerfilAtendimentoTipo.expressivo:
        return 'Expressivo';
    }
  }
}