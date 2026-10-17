import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:soloforte_app/core/utils/google_maps_link_parser.dart';

void main() {
  group('GoogleMapsLinkParser.parseCoordinatesFromUrl', () {
    test('extrai de @lat,lng na URL', () {
      const url =
          'https://www.google.com/maps/@-17.727234,-49.137892,15z?entry=ttu';
      final point = GoogleMapsLinkParser.parseCoordinatesFromUrl(url);
      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-17.727234, 0.000001));
      expect(point.longitude, closeTo(-49.137892, 0.000001));
    });

    test('extrai de !3d!4d (pin do lugar)', () {
      const url =
          'https://www.google.com/maps/place/Test/@-17.72,-49.13,15z/data=!3d-17.728!4d-49.138!5m1';
      final point = GoogleMapsLinkParser.parseCoordinatesFromUrl(url);
      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-17.728, 0.000001));
      expect(point.longitude, closeTo(-49.138, 0.000001));
    });

    test('extrai de query=api search', () {
      const url =
          'https://www.google.com/maps/search/?api=1&query=-10.500000,-48.200001';
      final point = GoogleMapsLinkParser.parseCoordinatesFromUrl(url);
      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-10.5, 0.000001));
      expect(point.longitude, closeTo(-48.200001, 0.000001));
    });

    test('looksLikeGoogleMapsLink reconhece maps.app.goo.gl', () {
      expect(
        GoogleMapsLinkParser.looksLikeGoogleMapsLink(
          'https://maps.app.goo.gl/myAe7MGdZ4LNrYPG9?g_st=ic',
        ),
        isTrue,
      );
    });
  });

  group('GoogleMapsLinkParser.resolve', () {
    test('segue redirect e extrai coordenadas', () async {
      final client = MockClient((request) async {
        expect(request.url.host, 'maps.app.goo.gl');
        return http.Response(
          'ok',
          200,
          request: http.Request(
            'GET',
            Uri.parse(
              'https://www.google.com/maps/place/@-17.727,-49.137,17z/data=!3d-17.7275!4d-49.1375',
            ),
          ),
        );
      });

      final parser = GoogleMapsLinkParser(client: client);
      final point = await parser.resolve(
        'https://maps.app.goo.gl/myAe7MGdZ4LNrYPG9?g_st=ic',
      );

      expect(point, isNotNull);
      expect(point!.latitude, closeTo(-17.7275, 0.000001));
      expect(point.longitude, closeTo(-49.1375, 0.000001));
    });
  });
}
