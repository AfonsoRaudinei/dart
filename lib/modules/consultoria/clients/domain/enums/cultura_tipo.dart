/// Tipos de cultura suportados pelo módulo de clientes.
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
}
