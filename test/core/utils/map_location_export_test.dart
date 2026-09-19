import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/utils/map_location_export.dart';

void main() {
  group('MapLocationExport.isValidCoordinate', () {
    test('aceita coordenadas válidas', () {
      expect(MapLocationExport.isValidCoordinate(-10.5, -48.2), isTrue);
    });

    test('rejeita (0,0)', () {
      expect(MapLocationExport.isValidCoordinate(0, 0), isFalse);
    });

    test('rejeita NaN', () {
      expect(MapLocationExport.isValidCoordinate(double.nan, -48.2), isFalse);
    });
  });

  group('MapLocationExport URLs', () {
    const lat = -10.5;
    const lng = -48.200001;

    test('formatDecimalLatLng usa 6 decimais', () {
      expect(
        MapLocationExport.formatDecimalLatLng(lat, lng),
        '-10.500000, -48.200001',
      );
    });

    test('googleMapsUrl', () {
      expect(
        MapLocationExport.googleMapsUrl(lat, lng),
        'https://www.google.com/maps/search/?api=1&query=-10.500000,-48.200001',
      );
    });

    test('appleMapsUrl', () {
      expect(
        MapLocationExport.appleMapsUrl(lat, lng),
        'https://maps.apple.com/?ll=-10.500000,-48.200001',
      );
    });

    test('wazeUrl', () {
      expect(
        MapLocationExport.wazeUrl(lat, lng),
        'https://waze.com/ul?ll=-10.500000,-48.200001&navigate=yes',
      );
    });

    test('shareText inclui label, coordenadas e link', () {
      final text = MapLocationExport.shareText(
        lat,
        lng,
        label: 'Área Visitada',
      );
      expect(text, contains('Área Visitada'));
      expect(text, contains('-10.500000, -48.200001'));
      expect(text, contains('google.com/maps'));
    });

    test('lança para coordenadas inválidas', () {
      expect(
        () => MapLocationExport.googleMapsUrl(0, 0),
        throwsArgumentError,
      );
    });
  });
}
