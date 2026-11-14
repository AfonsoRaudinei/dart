import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/app/producer_linked_drawing_sync_service.dart';
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
}
