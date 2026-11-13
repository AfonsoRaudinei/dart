// Catálogo dos estádios fenológicos da soja (VE até R8).
//
// Fonte: referência agronômica já usada na ocorrência. `dap` conta a
// partir de VE = 0 (dias após a emergência). Sem invenção de doenças.
// ADR-062.

class EstadioData {
  final String code;
  final String name;
  final String description;
  final int dap;
  final List<String> attention;

  const EstadioData({
    required this.code,
    required this.name,
    required this.description,
    required this.dap,
    required this.attention,
  });
}

const List<EstadioData> kEstadios = [
  EstadioData(
    code: 'VE',
    name: 'VE - Emergência',
    description: 'Cotilédones rompem o solo',
    dap: 0,
    attention: [
      'Absorção de água: mínimo 50% do peso da semente',
      'Temperatura ideal do solo: 20-30°C',
      'Início da colonização por Bradyrhizobium',
      'Embebição completa - eventos metabólicos preparando radícula',
    ],
  ),
  EstadioData(
    code: 'VC',
    name: 'VC - Cotilédones',
    description: 'Cotilédones totalmente abertos',
    dap: 3,
    attention: [
      'Planta utiliza reservas dos cotilédones',
      'Perda de 2 cotilédones pode reduzir 9% do rendimento',
      'Controle de plantas daninhas crítico',
      'Desenvolvimento do sistema radicular',
    ],
  ),
  EstadioData(
    code: 'V1',
    name: 'V1 - 1ª Trifoliolada',
    description: 'Primeira folha trifoliolada desenvolvida',
    dap: 8,
    attention: [
      'Fotossíntese sustenta o crescimento (independência dos cotilédones)',
      'Nova folha a cada 5 dias até V5',
      'Fixação biológica de N₂ em desenvolvimento',
      'Alta concentração de auxina - crescimento vegetativo',
    ],
  ),
  EstadioData(
    code: 'V2',
    name: 'V2 - 2ª Trifoliolada',
    description: 'Segunda folha trifoliolada',
    dap: 16,
    attention: [
      'Crescimento vegetativo intenso',
      'Aumento da demanda nutricional',
      'Controle de plantas daninhas',
      'Interceptação de luz aumentando',
    ],
  ),
  EstadioData(
    code: 'V3',
    name: 'V3 - 3ª Trifoliolada',
    description: 'Terceira folha trifoliolada',
    dap: 18,
    attention: [
      'Período crítico para competição com daninhas',
      'Crescimento radicular ativo',
      'Demanda hídrica aumentando',
      'Posicionamento de reguladores de crescimento',
    ],
  ),
  EstadioData(
    code: 'V4',
    name: 'V4 - 4ª Trifoliolada',
    description: 'Quarta folha trifoliolada',
    dap: 20,
    attention: [
      'Máximo crescimento vegetativo',
      'Alta demanda de água e nutrientes',
      'Controle de pragas (lagartas, percevejos)',
      'Arquitetura de planta definindo potencial produtivo',
    ],
  ),
  EstadioData(
    code: 'V5',
    name: 'V5 - 5ª Trifoliolada',
    description: 'Quinta folha trifoliolada',
    dap: 25,
    attention: [
      'A partir daqui: nova folha a cada 3 dias',
      'Preparação para fase reprodutiva',
      'Controle fitossanitário intensivo',
      'Auxinas em alta concentração',
    ],
  ),
  EstadioData(
    code: 'R1',
    name: 'R1 - Florescimento',
    description: 'Uma flor aberta em qualquer nó',
    dap: 25,
    attention: [
      'Início da fase reprodutiva (fotoperíodo crítico)',
      'Déficit hídrico extremamente crítico',
      'Boro essencial para formação do tubo polínico',
      'Estresse térmico causa abortamento de flores',
      'Intensificar fotossíntese para reservas',
    ],
  ),
  EstadioData(
    code: 'R2',
    name: 'R2 - Floração Plena',
    description: 'Flor aberta no terço superior',
    dap: 62,
    attention: [
      'Pleno florescimento da cultura',
      'Máxima demanda hídrica (5-7 mm/dia)',
      'Estresse térmico crítico para abortamento',
      'Etileno e ABA induzem queda de flores',
      'Controle de pragas desfolhadoras',
    ],
  ),
  EstadioData(
    code: 'R3',
    name: 'R3 - Vagens 1cm',
    description: 'Vagem com 1cm nos últimos 4 nós',
    dap: 65,
    attention: [
      'Formação inicial das vagens',
      'Translocação de fotoassimilados para vagens',
      'Número potencial de vagens definindo',
      'Monitoramento de percevejos intensificado',
    ],
  ),
  EstadioData(
    code: 'R4',
    name: 'R4 - Vagens 2cm',
    description: 'Vagem com 5mm nos 4 primeiros nós',
    dap: 72,
    attention: [
      'Vagens em pleno desenvolvimento',
      'Componente de produtividade: número de vagens',
      'Percevejos causam grande impacto',
      'Nutrição foliar para sustentação',
    ],
  ),
  EstadioData(
    code: 'R5.1',
    name: 'R5.1 - Início Enchimento',
    description: 'Grãos com 10% de granação',
    dap: 95,
    attention: [
      'Máximo desenvolvimento de área foliar e raízes',
      'Fixação de N₂ no máximo',
      'Translocação via fluxo de seiva (5-7 mm/dia)',
      'Déficit hídrico reduz duração do período',
    ],
  ),
  EstadioData(
    code: 'R5.3',
    name: 'R5.3 - 50% Enchimento',
    description: 'Grãos com 50% de granação',
    dap: 95,
    attention: [
      'Enchimento de grãos acelerado',
      'Período crítico para estresses',
      'Percevejos afetam qualidade dos grãos',
      'Lagartas reduzem área fotossintética',
    ],
  ),
  EstadioData(
    code: 'R5.5',
    name: 'R5.5 - 100% Enchimento',
    description: 'Grãos com 100% de granação',
    dap: 105,
    attention: [
      'Grãos completamente cheios',
      'Máximo acúmulo de matéria seca nos grãos',
      'Controle de percevejos ainda necessário',
      'Preparação para maturação',
    ],
  ),
  EstadioData(
    code: 'R6',
    name: 'R6 - Grãos Formados',
    description: 'Grãos totalmente formados',
    dap: 95,
    attention: [
      'Máxima matéria seca acumulada',
      'Plantas não absorvem mais água e nutrientes',
      'Percevejos afetam germinação e vigor',
      'Monitoramento para produção de sementes',
    ],
  ),
  EstadioData(
    code: 'R7',
    name: 'R7 - Início Maturação',
    description: 'Início da senescência',
    dap: 95,
    attention: [
      'Início da senescência',
      'Degradação de clorofila e proteínas',
      'Etileno e ABA regulam senescência',
      'Mobilização de reservas para grãos',
      'Atenção ao momento de dessecação',
    ],
  ),
  EstadioData(
    code: 'R8',
    name: 'R8 - Maturação Plena',
    description: '95% das vagens maduras',
    dap: 110,
    attention: [
      'Maturação completa (fim do ciclo biológico)',
      'Umidade ideal para colheita: 13-15%',
      'Evitar danos mecânicos na colheita',
      'Perda de folhas completa',
      'Sementes com todas as partes formadas',
    ],
  ),
];

/// Idade de calendário (hora zerada). Data ausente ou no futuro → null.
int? soyCalendarAgeDays(DateTime? from, DateTime today) {
  if (from == null) return null;
  final start = DateTime(from.year, from.month, from.day);
  final end = DateTime(today.year, today.month, today.day);
  final days = end.difference(start).inDays;
  if (days < 0) return null;
  return days;
}

DateTime? parseSoyIsoDate(String? iso) {
  final value = iso?.trim() ?? '';
  if (value.isEmpty) return null;
  return DateTime.tryParse(value);
}

/// Estádio da soja pelos dias após a emergência.
///
/// Vence o maior `dap` menor ou igual a [dae]. Empate fica com o primeiro
/// da lista (o seed não é monotônico: R6/R7 ficam abaixo de R5.5).
/// Cultura informada que não seja soja → null. Cultura vazia conta como soja.
EstadioData? suggestedEstadioForDae({required int? dae, String? cultura}) {
  if (dae == null || dae < 0) return null;
  final crop = cultura?.trim().toLowerCase() ?? '';
  if (crop.isNotEmpty && !crop.contains('soja')) return null;
  EstadioData? best;
  for (final estadio in kEstadios) {
    if (estadio.dap > dae) continue;
    if (best == null || estadio.dap > best.dap) best = estadio;
  }
  return best;
}

/// Colheita aproximada: emergência + ciclo. Sem emergência, plantio + ciclo.
/// Sem ciclo, sem data base ou ciclo negativo → null. Não usa duração fixa.
DateTime? approximateSoyHarvestDate({
  required String? dataEmergenciaIso,
  required String? dataPlantioIso,
  required int? cicloDias,
}) {
  if (cicloDias == null || cicloDias < 0) return null;
  final base =
      parseSoyIsoDate(dataEmergenciaIso) ?? parseSoyIsoDate(dataPlantioIso);
  if (base == null) return null;
  final start = DateTime(base.year, base.month, base.day);
  return start.add(Duration(days: cicloDias));
}
