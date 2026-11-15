import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/app/producer_linked_drawing_sync_service.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';
import 'package:soloforte_app/modules/produtor/data/producer_linked_drawings.dart';

void main() {
  const producer = 'producer-jonathan';
  const consultor = 'consultor-raudinei';

  test('linha do consultor não é regravada', () {
    expect(
      decideLinkedDrawingWrite(
        currentUserId: producer,
        remoteOwnerId: consultor,
        localOwnerId: consultor,
      ),
      LinkedDrawingWrite.leave,
    );
  });

  test('linha tomada pelo vínculo volta para o consultor', () {
    expect(
      decideLinkedDrawingWrite(
        currentUserId: producer,
        remoteOwnerId: consultor,
        localOwnerId: producer,
      ),
      LinkedDrawingWrite.restoreOwner,
    );
  });

  test('sem linha local grava só uma cópia', () {
    expect(
      decideLinkedDrawingWrite(
        currentUserId: producer,
        remoteOwnerId: consultor,
        localOwnerId: null,
      ),
      LinkedDrawingWrite.insertMirror,
    );
  });

  test('cópia local some quando o desenho do consultor está no aparelho', () {
    final kept = ProducerLinkedDrawingLoader.preferOwnerDrawings(const [
      ProducerLinkedDrawing(
        id: 'draw-1',
        name: 'Talhão 1',
        areaHa: 94.8,
        farmId: 'farm-tv',
        geometryJson: '{"type":"Polygon"}',
      ),
      ProducerLinkedDrawing(
        id: 'vinc_draw-1',
        name: 'Talhão 1',
        areaHa: 94.8,
        farmId: 'farm-tv',
        geometryJson: '{"type":"Polygon"}',
      ),
    ]);

    expect(kept.map((drawing) => drawing.id), ['draw-1']);
  });

  test('cópia local vira o talhão quando o original não está no aparelho', () {
    final kept = ProducerLinkedDrawingLoader.preferOwnerDrawings(const [
      ProducerLinkedDrawing(
        id: 'vinc_draw-1',
        name: 'Talhão 1',
        areaHa: 94.8,
        farmId: 'farm-tv',
        geometryJson: '{"type":"Polygon"}',
      ),
    ]);

    expect(kept.single.id, 'draw-1');
  });

  test('MultiPolygon compartilhado grava um desenho por parte', () {
    final now = DateTime.utc(2026, 11, 15);
    final feature = DrawingFeature(
      id: 'draw-farm',
      geometry: DrawingMultiPolygon(
        coordinates: [
          [
            [
              [-48.0, -10.0],
              [-47.9, -10.0],
              [-47.9, -9.9],
              [-48.0, -10.0],
            ],
          ],
          [
            [
              [-47.8, -10.0],
              [-47.7, -10.0],
              [-47.7, -9.9],
              [-47.8, -10.0],
            ],
          ],
        ],
      ),
      properties: DrawingProperties(
        nome: 'Talhão Novo',
        tipo: DrawingType.talhao,
        origem: DrawingOrigin.importacao_kml,
        status: DrawingStatus.aprovado,
        autorId: 'consultor-1',
        autorTipo: AuthorType.consultor,
        areaHa: 750.72,
        versao: 1,
        ativo: true,
        createdAt: now,
        updatedAt: now,
      ),
    );

    final parts = linkedMirrorSources(feature);

    expect(parts.map((part) => part.id), [
      'draw-farm__parte_1',
      'draw-farm__parte_2',
    ]);
    expect(parts.every((part) => part.geometry is DrawingPolygon), isTrue);
    expect(parts.every((part) => part.properties.areaHa > 0), isTrue);
  });
}
