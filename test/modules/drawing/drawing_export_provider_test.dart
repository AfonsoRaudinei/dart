import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_export_provider.dart';
import 'package:xml/xml.dart';

void main() {
  test('GPX escapa caracteres reservados no nome do talhão', () {
    final gpx = DrawingExportNotifier().buildGpxForTesting([
      _feature(nome: 'Soja & Milho <Norte>'),
    ]);

    expect(() => XmlDocument.parse(gpx), returnsNormally);
    expect(gpx, contains('Soja &amp; Milho &lt;Norte&gt;'));
  });
}

DrawingFeature _feature({required String nome}) {
  final now = DateTime(2026);
  return DrawingFeature(
    id: 'feature-1',
    geometry: DrawingPolygon(
      coordinates: [
        [
          [-48, -10],
          [-47.99, -10],
          [-47.99, -9.99],
          [-48, -10],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: nome,
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
