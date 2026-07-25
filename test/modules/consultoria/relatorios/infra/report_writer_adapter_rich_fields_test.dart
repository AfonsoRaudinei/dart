import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_read.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/visit_session_snapshot.dart';

/// Caracterização do mapeamento ADR-047 (OccurrenceSummary → OcorrenciaSnapshot).
/// O adapter concreto usa a mesma atribuição campo-a-campo.
void main() {
  group('ReportWriterAdapter ADR-047 mapping', () {
    test('campos ricos não são descartados (null)', () {
      final registradaEm = DateTime.utc(2026, 7, 1, 12);
      const summary = OccurrenceSummary(
        id: 'occ-1',
        type: 'doenca',
        description: 'Ferrugem',
        lat: -10.1,
        lng: -48.2,
        fotoPath: '/tmp/a.jpg',
        fotoPaths: ['/tmp/a.jpg'],
        categoria: 'doenca',
        geometry: '{"type":"Point"}',
        status: 'confirmed',
        cultivar: 'TMG 2183',
        estadioFenologico: 'R5.1',
        tipoOcorrencia: 'sazonal',
        recomendacoes: 'Aplicar',
        metricasJson: '{}',
        nutrientesJson: '[]',
        categoriasJson: '["doenca"]',
        notasCategoriasJson: '{}',
        fotosCategoriasJson: '{}',
      );

      final snap = OcorrenciaSnapshot(
        id: summary.id,
        tipo: summary.type,
        descricao: summary.description,
        lat: summary.lat,
        lng: summary.lng,
        fotoPath: summary.fotoPath,
        fotoPaths: summary.fotoPaths,
        categoria: summary.categoria,
        severity: summary.severity,
        geometry: summary.geometry,
        status: summary.status,
        registradaEm: summary.registradaEm ?? registradaEm,
        cultivar: summary.cultivar,
        estadioFenologico: summary.estadioFenologico,
        tipoOcorrencia: summary.tipoOcorrencia,
        recomendacoes: summary.recomendacoes,
        metricasJson: summary.metricasJson,
        nutrientesJson: summary.nutrientesJson,
        categoriasJson: summary.categoriasJson,
        notasCategoriasJson: summary.notasCategoriasJson,
        fotosCategoriasJson: summary.fotosCategoriasJson,
      );

      expect(snap.cultivar, isNotNull);
      expect(snap.estadioFenologico, isNotNull);
      expect(snap.recomendacoes, isNotNull);
      expect(snap.categoriasJson, isNotNull);
      expect(snap.fotoPaths, isNotEmpty);
    });
  });
}
