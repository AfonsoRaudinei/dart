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
            expiresAt: DateTime.now().add(const Duration(days: 30)),
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

  test('fazenda própria não esconde os talhões compartilhados', () {
    const own = ProducerOwnProperty(
      clientId: 'producer-1',
      name: 'Jonathan',
      email: null,
      farms: [
        ProducerOwnFarm(
          id: 'farm-mv',
          name: 'Morro Verde',
          city: 'Paraíso',
          state: 'TO',
          areaHa: 750.72,
          fields: [
            ProducerOwnField(
              id: 'talhao-novo',
              name: 'Talhão Novo',
              areaHa: 750.72,
              hasGeometry: true,
            ),
          ],
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
            expiresAt: DateTime.now().add(const Duration(days: 30)),
            usedAt: DateTime.utc(2026, 11, 14),
            createdAt: DateTime.utc(2026, 11, 14),
            updatedAt: DateTime.utc(2026, 11, 14),
          ),
          name: 'Jonathan',
          phone: null,
          email: null,
          city: null,
          state: null,
          farms: const [
            ProducerLinkedFarm(
              id: 'farm-mv',
              name: 'Morro Verde',
              city: 'Paraíso',
              state: 'TO',
              areaHa: 750,
              fields: [
                ProducerLinkedField(
                  id: 'talhao-1',
                  name: 'Talhão 1',
                  areaHa: 94.806,
                  geometryJson: '{"type":"Polygon"}',
                ),
                ProducerLinkedField(
                  id: 'th-2',
                  name: 'Th 2',
                  areaHa: 205.243,
                  geometryJson: '{"type":"Polygon"}',
                ),
              ],
            ),
          ],
          reports: const [],
        ),
      ],
    );

    expect(visible, hasLength(1));
    expect(visible.single.fields.map((field) => field.id), [
      'talhao-novo',
      'talhao-1',
      'th-2',
    ]);
    expect(visible.single.fields[1].hasGeometry, isTrue);
    expect(visible.single.fields[2].geometryJson, contains('Polygon'));
  });

  test('MultiPolygon compartilhado vira um talhão por parte', () {
    final parts = ProducerLinkedDrawingLoader.drawingsKeepingEachPart(const [
      ProducerLinkedDrawing(
        id: 'draw-farm',
        name: 'Talhão Novo',
        areaHa: 750.72,
        farmId: 'farm-mv',
        geometryJson:
            '{"type":"MultiPolygon","coordinates":[[[[-48, -10],[-47.9,-10],[-47.9,-9.9],[-48,-10]]],[[[-47.8,-10],[-47.7,-10],[-47.7,-9.9],[-47.8,-10]]]]}',
      ),
    ]);

    expect(parts.map((part) => part.id), [
      'draw-farm__parte_1',
      'draw-farm__parte_2',
    ]);
    expect(parts.map((part) => part.name), ['Talhão 1', 'Talhão 2']);
    expect(parts.every((part) => part.areaHa > 0), isTrue);
    expect(
      parts.every((part) => part.geometryJson!.contains('"Polygon"')),
      isTrue,
    );
    expect(parts.every((part) => part.farmId == 'farm-mv'), isTrue);
  });

  test('talhão fonte some quando o desenho vira partes', () {
    final parts = ProducerLinkedDrawingLoader.drawingsKeepingEachPart(const [
      ProducerLinkedDrawing(
        id: 'draw-farm',
        name: 'Talhão Novo',
        areaHa: 750.72,
        farmId: 'farm-mv',
        geometryJson:
            '{"type":"MultiPolygon","coordinates":[[[[-48, -10],[-47.9,-10],[-47.9,-9.9],[-48,-10]]],[[[-47.8,-10],[-47.7,-10],[-47.7,-9.9],[-47.8,-10]]]]}',
      ),
    ]);
    final attached = attachDrawingsToLinkedFarms(
      farms: const [
        ProducerLinkedFarm(
          id: 'farm-mv',
          name: 'Morro Verde',
          city: 'Paraíso',
          state: 'TO',
          areaHa: 750,
          fields: [
            ProducerLinkedField(
              id: 'draw-farm',
              name: 'Talhão Novo',
              areaHa: 750.72,
            ),
          ],
        ),
      ],
      drawings: parts,
    );

    expect(attached.single.fields.map((field) => field.id), [
      'draw-farm__parte_1',
      'draw-farm__parte_2',
    ]);
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
