import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/utils/coordinate_parser.dart';

void main() {
  group('CoordinateParser', () {
    test('aceita latitude e longitude decimais', () {
      final point = CoordinateParser.parse('-10.1823,-48.3331');

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-10.1823, 0.000001));
      expect(point.longitude, closeTo(-48.3331, 0.000001));
    });

    test('aceita DMS com hemisférios', () {
      final point = CoordinateParser.parse(
        '''10° 10' 56.28" S, 48° 19' 59.16" W''',
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-10.1823, 0.000001));
      expect(point.longitude, closeTo(-48.3331, 0.000001));
    });

    test('aceita DDM com hemisférios', () {
      final point = CoordinateParser.parse('''10° 10.938' S, 48° 19.986' W''');

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-10.1823, 0.000001));
      expect(point.longitude, closeTo(-48.3331, 0.000001));
    });

    test('aceita UTM com banda', () {
      final point = CoordinateParser.parse('22K 788000 8872000');

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-10.19, 0.1));
      expect(point.longitude, closeTo(-48.37, 0.1));
    });

    test('aceita EPSG WGS84 UTM sul sem repetir zona', () {
      final point = CoordinateParser.parse('EPSG:32722 788000 8872000');

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-10.19, 0.1));
      expect(point.longitude, closeTo(-48.37, 0.1));
    });

    test('aceita EPSG SIRGAS 2000 UTM brasileiro', () {
      final point = CoordinateParser.parse('EPSG:31982 788000 8872000');

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-10.19, 0.1));
      expect(point.longitude, closeTo(-48.37, 0.1));
    });

    test('rejeita UTM sem banda porque hemisfério é ambíguo', () {
      expect(CoordinateParser.parse('22 788000 8872000'), isNull);
    });
  });
}
