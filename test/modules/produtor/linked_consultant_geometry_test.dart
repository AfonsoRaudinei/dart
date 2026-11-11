import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/produtor/data/linked_consultant_geometry.dart';
import 'package:soloforte_app/modules/produtor/data/producer_link_models.dart';

void main() {
  const polygon =
      '{"type":"Polygon","coordinates":[[[-48.0,-10.0],[-48.0,-10.1],[-47.9,-10.1],[-48.0,-10.0]]]}';

  test('aceita GeoJSON em texto ou objeto', () {
    expect(linkedFieldGeometryJson('  $polygon  '), polygon);
    expect(linkedFieldGeometryJson('   '), isNull);
    expect(linkedFieldGeometryJson(null), isNull);

    final asMap = linkedFieldGeometryJson({
      'type': 'Polygon',
      'coordinates': [
        [
          [-48.0, -10.0],
          [-48.0, -10.1],
          [-47.9, -10.1],
          [-48.0, -10.0],
        ],
      ],
    });
    expect(asMap, contains('"type":"Polygon"'));
    expect(linkedFieldGeometryMap(asMap)?['type'], 'Polygon');
  });

  test('pontos de foco saem só dos talhões vinculados', () {
    final now = DateTime.utc(2026, 6, 1);
    final points = focusPointsForLinkedClients([
      ProducerLinkedClient(
        link: ProducerClientLink(
          id: 'link-1',
          consultorUserId: 'consultor-1',
          clientId: 'client-1',
          producerUserId: 'produtor-1',
          status: 'active',
          expiresAt: now,
          usedAt: now,
          createdAt: now,
          updatedAt: now,
        ),
        name: 'Jonathan',
        phone: null,
        email: null,
        city: null,
        state: null,
        farms: const [
          ProducerLinkedFarm(
            id: 'farm-1',
            name: 'Pium',
            city: 'Pium',
            state: 'TO',
            areaHa: 10,
            fields: [
              ProducerLinkedField(
                id: 'field-1',
                name: 'Talhão A',
                areaHa: 4,
                geometryJson: polygon,
              ),
              ProducerLinkedField(
                id: 'field-2',
                name: 'Sem desenho',
                areaHa: 1,
              ),
            ],
          ),
        ],
        reports: const [],
      ),
    ]);

    expect(points, isNotEmpty);
    expect(points.first, const LatLng(-10.0, -48.0));
  });
}
