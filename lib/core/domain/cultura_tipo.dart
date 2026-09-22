/// Tipos de cultura compartilhados (cliente, talhão do mapa, labels).
enum CulturaTipo {
  soja,
  milho,
  algodao,
  feijao,
  sorgo,
  trigo,
  cafe,
  cana,
  arroz,
  pastagem,
  eucalipto,
  citros,
  horticultura,
  fruticultura,
  outro;

  String get label => switch (this) {
    CulturaTipo.soja => 'Soja',
    CulturaTipo.milho => 'Milho',
    CulturaTipo.algodao => 'Algodão',
    CulturaTipo.feijao => 'Feijão',
    CulturaTipo.sorgo => 'Sorgo',
    CulturaTipo.trigo => 'Trigo',
    CulturaTipo.cafe => 'Café',
    CulturaTipo.cana => 'Cana-de-açúcar',
    CulturaTipo.arroz => 'Arroz',
    CulturaTipo.pastagem => 'Pastagem',
    CulturaTipo.eucalipto => 'Eucalipto',
    CulturaTipo.citros => 'Citros',
    CulturaTipo.horticultura => 'Horticultura',
    CulturaTipo.fruticultura => 'Fruticultura',
    CulturaTipo.outro => 'Outra',
  };

  static CulturaTipo fromName(String name) => CulturaTipo.values.firstWhere(
    (e) => e.name == name,
    orElse: () => CulturaTipo.outro,
  );

  /// Interpreta valor persistido no talhão (label, name ou texto livre).
  static CulturaTipo? matchStored(String? stored) {
    if (stored == null || stored.trim().isEmpty) return null;
    final trimmed = stored.trim();
    for (final tipo in CulturaTipo.values) {
      if (tipo == CulturaTipo.outro) continue;
      if (tipo.name == trimmed ||
          tipo.label.toLowerCase() == trimmed.toLowerCase()) {
        return tipo;
      }
    }
    return CulturaTipo.outro;
  }

  static String displayLabel(String? stored) {
    final tipo = matchStored(stored);
    if (tipo == null) return '';
    if (tipo == CulturaTipo.outro) return stored!.trim();
    return tipo.label;
  }
}
