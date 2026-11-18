import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/geo/kml_exporter.dart';

const _openTriangle = [
  [-51.25, -23.5],
  [-51.1, -23.5],
  [-51.1, -23.6],
];

void main() {
  test('polígono simples sai lng,lat e fecha o anel', () {
    final kml = buildKmlDocument(
      documentName: 'Fazenda',
      placemarks: [
        const KmlPlacemark(
          name: 'Talhão',
          areaHa: 28.71,
          geometry: {
            'type': 'Polygon',
            'coordinates': [_openTriangle],
          },
        ),
      ],
    );

    final coords = RegExp(
      r'<coordinates>([^<]+)</coordinates>',
    ).firstMatch(kml)!.group(1)!;
    final parts = coords.split(' ');
    expect(parts.first, '-51.2500000,-23.5000000');
    expect(parts[1], '-51.1000000,-23.5000000');
    expect(parts.last, parts.first);
    expect(parts, hasLength(4));
    expect(kml, contains('<description>28.71 ha</description>'));
    expect(kml, isNot(contains('innerBoundaryIs')));
  });

  test('furo vira innerBoundaryIs', () {
    final kml = buildKmlDocument(
      documentName: 'Fazenda',
      placemarks: [
        KmlPlacemark(
          name: 'Talhão',
          geometry: jsonEncode({
            'type': 'Polygon',
            'coordinates': [
              [
                [-51.0, -23.0],
                [-51.2, -23.0],
                [-51.2, -23.2],
                [-51.0, -23.2],
                [-51.0, -23.0],
              ],
              [
                [-51.05, -23.05],
                [-51.08, -23.05],
                [-51.06, -23.08],
              ],
            ],
          }),
        ),
      ],
    );

    expect(kml, contains('<outerBoundaryIs>'));
    expect(kml, contains('<innerBoundaryIs>'));
    expect('<innerBoundaryIs>'.allMatches(kml), hasLength(1));
    expect(kml, contains('-51.0500000,-23.0500000'));
    expect(kml, isNot(contains('<description>')));
  });

  test('MultiPolygon vira MultiGeometry com 2 Polygon', () {
    final kml = buildKmlDocument(
      documentName: 'Fazenda',
      placemarks: [
        const KmlPlacemark(
          name: 'Talhão',
          geometry: {
            'type': 'MultiPolygon',
            'coordinates': [
              [
                [
                  [-51.0, -23.0],
                  [-51.1, -23.0],
                  [-51.1, -23.1],
                  [-51.0, -23.0],
                ],
              ],
              [
                [
                  [-50.0, -22.0],
                  [-50.1, -22.0],
                  [-50.1, -22.1],
                  [-50.0, -22.0],
                ],
              ],
            ],
          },
        ),
      ],
    );

    expect(kml, contains('<MultiGeometry>'));
    expect('<Polygon>'.allMatches(kml), hasLength(2));
    expect(kml, contains('-50.0000000,-22.0000000'));
    expect(kml, isNot(contains('innerBoundaryIs')));
  });

  test('nome com & e < é escapado', () {
    final kml = buildKmlDocument(
      documentName: 'A & B',
      placemarks: [
        const KmlPlacemark(
          name: 'Talhão <norte> & sul',
          geometry: {
            'type': 'Polygon',
            'coordinates': [_openTriangle],
          },
        ),
      ],
    );

    expect(kml, contains('<name>A &amp; B</name>'));
    expect(kml, contains('<name>Talhão &lt;norte&gt; &amp; sul</name>'));
    expect(kml, isNot(contains('Talhão <norte>')));
    expect(kml, isNot(contains('<name>A & B</name>')));
  });

  test('KMZ contém doc.kml com o mesmo texto', () {
    const placemarks = [
      KmlPlacemark(
        name: 'Talhão',
        areaHa: 1.5,
        geometry: {
          'type': 'Polygon',
          'coordinates': [_openTriangle],
        },
      ),
    ];
    final kml = buildKmlDocument(
      documentName: 'Fazenda',
      placemarks: placemarks,
    );
    final bytes = buildKmzBytes(
      documentName: 'Fazenda',
      placemarks: placemarks,
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    final entries = archive.files.where((file) => file.name == 'doc.kml');
    expect(entries, hasLength(1));
    expect(utf8.decode(entries.single.content), kml);
    expect(archive.files.where((file) => file.isFile), hasLength(1));
  });

  test('entrada sem polígono lança', () {
    expect(
      () => buildKmlDocument(
        documentName: 'Vazio',
        placemarks: const [
          KmlPlacemark(
            name: 'Ponto',
            geometry: {
              'type': 'Point',
              'coordinates': [-51.0, -23.0],
            },
          ),
        ],
      ),
      throwsA(
        isA<KmlExportException>().having(
          (error) => error.message,
          'message',
          contains('polígono'),
        ),
      ),
    );
  });

  test('Feature desembrulha geometry', () {
    final kml = buildKmlDocument(
      documentName: 'Fazenda',
      placemarks: [
        KmlPlacemark(
          name: 'Talhão',
          geometry: jsonEncode({
            'type': 'Feature',
            'geometry': {
              'type': 'Polygon',
              'coordinates': [_openTriangle],
            },
          }),
        ),
      ],
    );

    expect(kml, contains('<Polygon>'));
    expect(kml, contains('-51.2500000,-23.5000000'));
  });
}
