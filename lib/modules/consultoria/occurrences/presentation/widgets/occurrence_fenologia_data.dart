// ignore_for_file: depend_on_referenced_packages
import 'package:flutter/material.dart' show Color;

export 'package:soloforte_app/core/domain/soy_phenology.dart';

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
  'plantio': Color(0xFFA16207),
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
