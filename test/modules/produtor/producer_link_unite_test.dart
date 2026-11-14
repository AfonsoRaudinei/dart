import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';
import 'package:soloforte_app/modules/produtor/data/producer_linked_drawings.dart';

void main() {
  group('attachDrawingsToLinkedFarms', () {
    const farms = [
      ProducerLinkedFarm(
        id: 'farm-tv',
        name: 'Terra Viva',
        city: 'Pium',
        state: 'TO',
        areaHa: 200,
        fields: [],
      ),
      ProducerLinkedFarm(
        id: 'farm-mv',
        name: 'Morro Verde',
        city: 'Pium',
        state: 'TO',
        areaHa: 700,
        fields: [],
      ),
    ];

    test('encaixa o desenho na fazenda pelo fazenda_id', () {
      final attached = attachDrawingsToLinkedFarms(
        farms: farms,
        drawings: const [
          ProducerLinkedDrawing(
            id: 'draw-1',
            name: 'Talhão 1',
            areaHa: 94.806,
            farmId: 'farm-tv',
            geometryJson: '{"type":"Polygon"}',
          ),
          ProducerLinkedDrawing(
            id: 'draw-2',
            name: 'Th 2',
            areaHa: 205.243,
            farmId: 'farm-mv',
            geometryJson: '{"type":"Polygon"}',
          ),
        ],
      );

      expect(attached.first.fields.single.name, 'Talhão 1');
      expect(attached.first.fields.single.fromDrawing, isTrue);
      expect(attached.last.fields.single.name, 'Th 2');
    });

    test('sem fazenda_id usa o grupo com o nome da fazenda', () {
      final attached = attachDrawingsToLinkedFarms(
        farms: farms,
        drawings: const [
          ProducerLinkedDrawing(
            id: 'draw-1',
            name: 'Talhão 1',
            areaHa: 10,
            groupName: 'terra viva',
            geometryJson: '{"type":"Polygon"}',
          ),
        ],
      );

      expect(attached.first.fields.single.id, 'draw-1');
      expect(attached.last.fields, isEmpty);
    });

    test('desenho sem dono fica na primeira fazenda', () {
      final attached = attachDrawingsToLinkedFarms(
        farms: farms,
        drawings: const [
          ProducerLinkedDrawing(
            id: 'draw-1',
            name: 'Talhão 1',
            areaHa: 10,
            geometryJson: '{"type":"Polygon"}',
          ),
        ],
      );

      expect(attached.first.fields.single.name, 'Talhão 1');
      expect(attached.last.fields, isEmpty);
    });
  });

  test('fazenda do vínculo aparece para o produtor sem duplicar a própria', () {
    const own = ProducerOwnProperty(
      clientId: 'producer-1',
      name: 'Jonathan',
      email: 'jonathan.terraviva@gmail.com',
      farms: [
        ProducerOwnFarm(
          id: 'farm-own',
          name: 'Retiro',
          city: '',
          state: '',
          areaHa: 10,
          fields: [],
        ),
      ],
    );
    final visible = producerFarmsForProducer(
      own: own,
      linkedClients: [
        ProducerLinkedClient(
          link: ProducerClientLink(
            id: 'link-1',
            consultorUserId: 'consultor-1',
            clientId: 'client-jonathan',
            producerUserId: 'producer-1',
            status: 'active',
            expiresAt: DateTime.utc(2026, 11, 21),
            usedAt: DateTime.utc(2026, 11, 14),
            createdAt: DateTime.utc(2026, 11, 14),
            updatedAt: DateTime.utc(2026, 11, 14),
          ),
          name: 'Jonathan',
          phone: null,
          email: null,
          city: 'Pium',
          state: 'TO',
          farms: const [
            ProducerLinkedFarm(
              id: 'farm-own',
              name: 'Retiro',
              city: '',
              state: '',
              areaHa: 10,
              fields: [],
            ),
            ProducerLinkedFarm(
              id: 'farm-tv',
              name: 'Terra Viva',
              city: 'Pium',
              state: 'TO',
              areaHa: 200,
              fields: [
                ProducerLinkedField(
                  id: 'talhao-1',
                  name: 'Talhão 1',
                  areaHa: 94.8,
                  geometryJson: '{"type":"Polygon"}',
                  fromDrawing: true,
                ),
              ],
            ),
          ],
          reports: const [],
        ),
      ],
    );

    expect(visible.map((farm) => farm.id), ['farm-own', 'farm-tv']);
    expect(visible.last.sharedByConsultant, isTrue);
    expect(visible.last.sourceClientId, 'client-jonathan');
    expect(visible.last.fields.single.hasGeometry, isTrue);
  });

  test('linha remota de desenho vira talhão do vínculo', () {
    final drawings = ProducerLinkedDrawingLoader.drawingsFromRemoteRows([
      {
        'id': 'draw-1',
        'deleted_at': null,
        'geometry': {
          'type': 'Polygon',
          'coordinates': [
            [
              [-48.0, -10.0],
              [-48.1, -10.0],
              [-48.1, -10.1],
              [-48.0, -10.0],
            ],
          ],
        },
        'properties': {
          'nome': 'Talhão 1',
          'tipo': 'talhao',
          'ativo': true,
          'area_ha': 94.806,
          'fazenda_id': 'farm-tv',
          'grupo': 'Terra Viva',
        },
      },
      {
        'id': 'draw-skip',
        'deleted_at': '2026-11-14T00:00:00Z',
        'geometry': {'type': 'Polygon', 'coordinates': []},
        'properties': {'nome': 'Apagado', 'tipo': 'talhao', 'ativo': true},
      },
    ]);

    expect(drawings, hasLength(1));
    expect(drawings.single.name, 'Talhão 1');
    expect(drawings.single.farmId, 'farm-tv');
    expect(drawings.single.groupName, 'Terra Viva');
    expect(drawings.single.geometryJson, contains('Polygon'));
  });
}
