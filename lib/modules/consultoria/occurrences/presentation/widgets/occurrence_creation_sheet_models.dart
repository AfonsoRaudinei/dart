part of 'occurrence_creation_sheet.dart';

class _OccurrenceCategory {
  final String label;
  final IconData icon;
  final String value;
  final OccurrenceCategory? enumValue; // compatibilidade com métricas (SEÇÃO 4)
  const _OccurrenceCategory({
    required this.label,
    required this.icon,
    required this.value,
    this.enumValue,
  });
}

const _categories = [
  _OccurrenceCategory(
    label: 'Doença',
    icon: Icons.coronavirus_outlined,
    value: 'doenca',
    enumValue: OccurrenceCategory.doenca,
  ),
  _OccurrenceCategory(
    label: 'Insetos',
    icon: Icons.bug_report_outlined,
    value: 'insetos',
    enumValue: OccurrenceCategory.insetos,
  ),
  _OccurrenceCategory(
    label: 'Ervas Daninhas',
    icon: Icons.grass_outlined,
    value: 'ervas_daninhas',
    enumValue: OccurrenceCategory.daninhas,
  ),
  _OccurrenceCategory(
    label: 'Nutrientes',
    icon: Icons.science_outlined,
    value: 'nutrientes',
    enumValue: OccurrenceCategory.nutricional,
  ),
  _OccurrenceCategory(
    label: 'Água',
    icon: Icons.water_drop_outlined,
    value: 'agua',
    enumValue: OccurrenceCategory.agua,
  ),
  _OccurrenceCategory(
    label: 'Amostra\nde Solo',
    icon: Icons.biotech_outlined,
    value: 'amostra_solo',
  ),
];

/// Empacota todos os campos coletados pelo formulário agronômico v14.
class OccurrenceFormData {
  final String type; // urgência: "Baixa" | "Média" | "Alta"
  final String description;
  final String? clientId;
  final String? photoPath; // primeiro caminho de foto (se houver)
  final String? category; // categoria principal (1ª selecionada)
  final String? cultivar;
  final String? dataPlantio; // "yyyy-MM-dd"
  final String? estadioFenologico; // código ex.: "V4", "R5.1"
  final String? tipoOcorrencia; // "sazonal" | "permanente"
  final bool amostraSolo;
  final String? recomendacoes;
  final String? metricasJson;
  final String? nutrientesJson;
  final String? categoriasJson;
  final String? notasCategoriasJson;
  final String? fotosCategoriasJson;

  const OccurrenceFormData({
    required this.type,
    required this.description,
    this.clientId,
    this.photoPath,
    this.category,
    this.cultivar,
    this.dataPlantio,
    this.estadioFenologico,
    this.tipoOcorrencia,
    this.amostraSolo = false,
    this.recomendacoes,
    this.metricasJson,
    this.nutrientesJson,
    this.categoriasJson,
    this.notasCategoriasJson,
    this.fotosCategoriasJson,
  });
}

typedef OccurrenceConfirmCallback = void Function(OccurrenceFormData data);
