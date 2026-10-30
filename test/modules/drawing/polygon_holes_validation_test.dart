import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/drawing_utils.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/services/geometry_service.dart';

const _outer = [
  [-47.93, -15.78],
  [-47.92, -15.78],
  [-47.92, -15.77],
  [-47.93, -15.77],
  [-47.93, -15.78],
];

const _validHole = [
  [-47.927, -15.777],
  [-47.923, -15.777],
  [-47.923, -15.773],
  [-47.927, -15.773],
  [-47.927, -15.777],
];

DrawingPolygon _polyWithHoles(List<List<List<double>>> rings) =>
    DrawingPolygon(coordinates: rings);

void main() {
  group('arePolygonHolesValid / validateTopology / GeometryService', () {
    test('polígono válido com furo continua a passar', () {
      final poly = _polyWithHoles([_outer, _validHole]);

      expect(DrawingUtils.arePolygonHolesValid(poly), isTrue);
      expect(
        DrawingUtils.validateTopology(poly).isValid,
        isTrue,
        reason: DrawingUtils.validateTopology(poly).message,
      );
      expect(GeometryService.validatePolygon(poly).isValid, isTrue);
    });

    test('furo com vértice fora do anel externo falha', () {
      const holeOutside = [
        [-47.91, -15.777],
        [-47.905, -15.777],
        [-47.905, -15.773],
        [-47.91, -15.773],
        [-47.91, -15.777],
      ];
      final poly = _polyWithHoles([_outer, holeOutside]);

      expect(DrawingUtils.arePolygonHolesValid(poly), isFalse);
      _expectInvalidHoleMessage(poly);
    });

    test('furo cruzando a borda do externo falha', () {
      const crossingHole = [
        [-47.925, -15.776],
        [-47.915, -15.776],
        [-47.915, -15.774],
        [-47.925, -15.774],
        [-47.925, -15.776],
      ];
      final poly = _polyWithHoles([_outer, crossingHole]);

      expect(DrawingUtils.arePolygonHolesValid(poly), isFalse);
      _expectInvalidHoleMessage(poly);
    });

    test('furos sobrepostos falham', () {
      const holeA = [
        [-47.928, -15.776],
        [-47.924, -15.776],
        [-47.924, -15.774],
        [-47.928, -15.774],
        [-47.928, -15.776],
      ];
      const holeB = [
        [-47.926, -15.7755],
        [-47.922, -15.7755],
        [-47.922, -15.7735],
        [-47.926, -15.7735],
        [-47.926, -15.7755],
      ];
      final poly = _polyWithHoles([_outer, holeA, holeB]);

      expect(DrawingUtils.arePolygonHolesValid(poly), isFalse);
      _expectInvalidHoleMessage(poly);
    });

    test('furo com auto-interseção falha', () {
      const bowtieHole = [
        [-47.927, -15.776],
        [-47.923, -15.774],
        [-47.927, -15.774],
        [-47.923, -15.776],
        [-47.927, -15.776],
      ];
      final poly = _polyWithHoles([_outer, bowtieHole]);

      expect(DrawingUtils.arePolygonHolesValid(poly), isFalse);
      _expectInvalidHoleMessage(poly);
    });
  });

  group('furo colinear com a borda do externo', () {
    // Investigação (30/10/2026): furo com aresta coincidente com aresta do externo
    // passa hoje. [_ringsHaveCrossingSegments] usa [_segmentsIntersect], que só
    // detecta cruzamento transversal — segmentos colineares sobrepostos retornam
    // false. [_holeFits] usa ray casting: vértices do furo no interior passam;
    // vértices sobre a borda compartilhada não disparam cruzamento. Resultado
    // observado: arePolygonHolesValid == true (não rejeitado). Comportamento
    // indefinido em GIS; o teste documenta o que o código faz, sem afrouxar
    // outras asserções.
    test('furo com aresta sobre a borda superior do externo é aceito hoje', () {
      const colinearOnTopEdge = [
        [-47.925, -15.78],
        [-47.922, -15.78],
        [-47.922, -15.775],
        [-47.925, -15.775],
        [-47.925, -15.78],
      ];
      final poly = _polyWithHoles([_outer, colinearOnTopEdge]);

      expect(DrawingUtils.arePolygonHolesValid(poly), isTrue);
      expect(DrawingUtils.validateTopology(poly).isValid, isTrue);
      expect(GeometryService.validatePolygon(poly).isValid, isTrue);
    });
  });

  group('KML innerBoundaryIs', () {
    test('gera área líquida menor que o anel externo', () async {
      const kml = '''<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2">
  <Document>
    <Placemark>
      <Polygon>
        <outerBoundaryIs>
          <LinearRing>
            <coordinates>
              -47.93,-15.78,0 -47.92,-15.78,0 -47.92,-15.77,0 -47.93,-15.77,0 -47.93,-15.78,0
            </coordinates>
          </LinearRing>
        </outerBoundaryIs>
        <innerBoundaryIs>
          <LinearRing>
            <coordinates>
              -47.927,-15.777,0 -47.923,-15.777,0 -47.923,-15.773,0 -47.927,-15.773,0 -47.927,-15.777,0
            </coordinates>
          </LinearRing>
        </innerBoundaryIs>
      </Polygon>
    </Placemark>
  </Document>
</kml>''';

      final dir = await Directory.systemTemp.createTemp('soloforte_kml_hole_');
      final file = File('${dir.path}/field_with_hole.kml');
      await file.writeAsString(kml);
      addTearDown(() async {
        await file.delete();
        await dir.delete();
      });

      final geometry = await DrawingUtils.parseFileOrThrow(
        PlatformFile(
          path: file.path,
          name: 'field_with_hole.kml',
          size: kml.length,
        ),
      );

      expect(geometry, isA<DrawingPolygon>());
      final poly = geometry as DrawingPolygon;
      expect(poly.coordinates.length, 2);
      expect(DrawingUtils.arePolygonHolesValid(poly), isTrue);

      final outerArea = DrawingUtils.calculateGeometryArea(
        DrawingPolygon(coordinates: [poly.coordinates.first]),
      );
      final netArea = DrawingUtils.calculateGeometryArea(poly);
      expect(netArea, greaterThan(0));
      expect(netArea, lessThan(outerArea));
    });
  });
}

void _expectInvalidHoleMessage(DrawingPolygon poly) {
  final topo = DrawingUtils.validateTopology(poly);
  expect(topo.isValid, isFalse);
  expect(topo.message, DrawingUtils.invalidHoleValidationMessage);

  final gs = GeometryService.validatePolygon(poly);
  expect(gs.isValid, isFalse);
  expect(gs.message, DrawingUtils.invalidHoleValidationMessage);
}
