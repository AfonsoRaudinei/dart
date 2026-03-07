import 'dart:convert';
import '../models/drawing_models.dart';

// =============================================================================
// RESULT
// =============================================================================

/// Resultado do parse de uma string GeoJSON.
class GeoJsonParseResult {
  final List<DrawingFeature> features;
  final String? error;

  const GeoJsonParseResult({required this.features, this.error});

  bool get isSuccess => error == null && features.isNotEmpty;
}

// =============================================================================
// SERVICE
// =============================================================================

/// Serviço puro de exportação e importação GeoJSON.
///
/// Sem dependências Flutter — apenas conversão de dados.
/// Pode ser instanciado como `const` e testado sem mocks.
///
/// Funções:
/// - [exportFeature] — serializa uma única feature (GeoJSON Feature)
/// - [exportFeatureCollection] — serializa lista (GeoJSON FeatureCollection)
/// - [parseGeoJson] — parse de Feature ou FeatureCollection
/// - [fileNameFor] / [collectionFileName] — geram nomes de arquivo seguros
class GeoJsonExporterService {
  const GeoJsonExporterService();

  static const _encoder = JsonEncoder.withIndent('  ');

  // ---------------------------------------------------------------------------
  // EXPORT
  // ---------------------------------------------------------------------------

  /// Serializa uma única [DrawingFeature] como string GeoJSON Feature (pretty).
  ///
  /// O resultado é um GeoJSON válido de acordo com RFC 7946.
  String exportFeature(DrawingFeature feature) {
    return _encoder.convert(feature.toJson());
  }

  /// Serializa uma lista de [DrawingFeature] como GeoJSON FeatureCollection.
  ///
  /// Inclui metadados SoloForte no nível `properties` de cada feature.
  String exportFeatureCollection(List<DrawingFeature> features) {
    final collection = {
      'type': 'FeatureCollection',
      'features': features.map((f) => f.toJson()).toList(),
    };
    return _encoder.convert(collection);
  }

  // ---------------------------------------------------------------------------
  // IMPORT (complemento do KML/KMZ existente)
  // ---------------------------------------------------------------------------

  /// Parseia uma string GeoJSON que pode ser Feature ou FeatureCollection.
  ///
  /// Retorna [GeoJsonParseResult] com lista de features parseadas ou erro.
  /// Nunca lança exceção — erros são encapsulados em [GeoJsonParseResult.error].
  GeoJsonParseResult parseGeoJson(String jsonString) {
    try {
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      final type = json['type'] as String?;

      if (type == 'Feature') {
        return GeoJsonParseResult(
          features: [DrawingFeature.fromJson(json)],
        );
      }

      if (type == 'FeatureCollection') {
        final rawList = json['features'] as List? ?? [];
        final parsed = rawList
            .map((f) => DrawingFeature.fromJson(f as Map<String, dynamic>))
            .toList();
        return GeoJsonParseResult(features: parsed);
      }

      return const GeoJsonParseResult(
        features: [],
        error:
            'Tipo GeoJSON não suportado. Esperado: Feature ou FeatureCollection.',
      );
    } catch (e) {
      return GeoJsonParseResult(
        features: [],
        error: 'Erro ao parsear GeoJSON: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // FILE NAMES
  // ---------------------------------------------------------------------------

  /// Gera nome de arquivo .geojson seguro para uma feature individual.
  ///
  /// Ex: `Talhao_Norte_a1b2c3d4.geojson`
  String fileNameFor(DrawingFeature feature) {
    final safe = feature.properties.nome
        // Mantém letras, dígitos, acentos, espaço, hífen e underscore
        .replaceAll(RegExp(r'[^\w\u00C0-\u024F\s_-]'), '')
        .trim()
        .replaceAll(RegExp(r'\s+'), '_');
    final shortId = feature.id.length >= 8 ? feature.id.substring(0, 8) : feature.id;
    return '${safe}_$shortId.geojson';
  }

  /// Gera nome de arquivo .geojson para exportação de toda a coleção.
  ///
  /// Ex: `soloforte_talhoes_2026-03-03.geojson`
  String collectionFileName() {
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return 'soloforte_talhoes_$date.geojson';
  }
}
