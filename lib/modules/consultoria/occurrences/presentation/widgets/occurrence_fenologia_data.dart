// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart' show Color;

/// Dados dos estádios fenológicos da soja — ADR-014 (Schema v14)
///
/// Fonte: referência agronômica validada (17 estádios VE→R8).
/// ZERO invenção de dados — apenas os fornecidos na especificação do prompt.

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

// ── Nutrientes ──────────────────────────────────────────────────────────────
/// Par (símbolo, nome) para o grid de nutrientes.
const List<(String, String)> kNutrientes = [
  ('N', 'Nitrogênio'),
  ('P', 'Fósforo'),
  ('K', 'Potássio'),
  ('Ca', 'Cálcio'),
  ('Mg', 'Magnésio'),
  ('S', 'Enxofre'),
  ('B', 'Boro'),
  ('Zn', 'Zinco'),
  ('Fe', 'Ferro'),
  ('Mn', 'Manganês'),
  ('Cu', 'Cobre'),
  ('Mo', 'Molibdênio'),
];

// ── Cores das categorias ────────────────────────────────────────────────────
const kCategoryColors = {
  'doenca': Color(0xFF34C759),
  'insetos': Color(0xFFFF2D55),
  'daninhas': Color(0xFFFF9500),
  'nutrientes': Color(0xFF8E8E93),
  'agua': Color(0xFF30B0C7),
};

// ── Labels dos sliders 0–3 ──────────────────────────────────────────────────
const kSliderLabels = ['Nenhum', 'Baixa', 'Média', 'Alta'];
const kSliderColors = [
  Color(0xFF8E8E93), // Nenhum → cinza
  Color(0xFFFFCC00), // Baixa → amarelo
  Color(0xFFFF9500), // Média → laranja
  Color(0xFFFF3B30), // Alta → vermelho
];

// ── Métricas por categoria ──────────────────────────────────────────────────
/// Retorna os campos de slider para cada categoria.
List<String> categoryMetrics(String cat) {
  switch (cat) {
    case 'doenca':
      return ['incidencia', 'severidade'];
    case 'insetos':
      return ['desfolha', 'infestacao', 'acamamento'];
    case 'daninhas':
      return ['severidade'];
    case 'agua':
      return ['status'];
    default:
      return [];
  }
}

/// Nome legível de uma métrica.
String metricLabel(String metric) {
  switch (metric) {
    case 'incidencia':
      return 'Incidência';
    case 'severidade':
      return 'Severidade';
    case 'desfolha':
      return 'Desfolha';
    case 'infestacao':
      return 'Taxa de Infestação';
    case 'acamamento':
      return 'Acamamento';
    case 'status':
      return 'Status';
    default:
      return metric;
  }
}

/// Labels específicos para o slider de Água (0-2).
const kAguaLabels = ['Adequado', 'Seco', 'Excesso'];


