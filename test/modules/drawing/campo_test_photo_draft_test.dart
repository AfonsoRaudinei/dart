import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/domain/models/campo_test_photo_draft.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

void main() {
  group('resolveCampoTestSketchGeo', () {
    test('retorna centro do anel externo', () {
      final geometry = DrawingPolygon(
        coordinates: [
          [
            [-47.0, -15.0],
            [-47.001, -15.0],
            [-47.001, -15.001],
            [-47.0, -15.0],
          ],
        ],
      );
      final geo = resolveCampoTestSketchGeo(geometry);
      expect(geo, isNotNull);
      expect(geo!.latitude, closeTo(-15.000333333333334, 0.0001));
      expect(geo.longitude, closeTo(-47.00066666666667, 0.0001));
    });

    test('primeiro vértice válido quando só há um ponto', () {
      final geometry = DrawingPolygon(
        coordinates: [
          [
            [-47.5, -15.5],
          ],
        ],
      );
      final geo = resolveCampoTestSketchGeo(geometry);
      expect(geo, const LatLng(-15.5, -47.5));
    });

    test('null sem geometria', () {
      expect(resolveCampoTestSketchGeo(null), isNull);
    });
  });
}