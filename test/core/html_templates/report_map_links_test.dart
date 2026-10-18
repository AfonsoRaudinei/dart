import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/report_map_links.dart';
import 'package:soloforte_app/core/html_templates/report_photo_links.dart';

void main() {
  group('ReportMapLinks', () {
    test('anchorHtml gera link Google Maps com data-sf-lat/lng', () {
      final html = ReportMapLinks.anchorHtml(-10.123456, -48.987654);

      expect(html, contains('class="sf-map-link"'));
      expect(html, contains('Ponto registrado no mapa'));
      expect(
        html,
        contains(
          'href="https://www.google.com/maps/search/?api=1&query=-10.123456,-48.987654"',
        ),
      );
      expect(html, contains('data-sf-lat="-10.123456"'));
      expect(html, contains('data-sf-lng="-48.987654"'));
    });

    test('rewriteForInApp troca href por sfmap://', () {
      const exportHtml =
          '<a class="sf-map-link" href="https://www.google.com/maps/search/?api=1&query=-10.1,-48.2" '
          'data-sf-lat="-10.100000" data-sf-lng="-48.200000">Ponto</a>';
      final inApp = ReportMapLinks.rewriteForInApp(exportHtml);

      expect(inApp, contains('href="sfmap://open?lat=-10.100000&lng=-48.200000"'));
      expect(inApp, isNot(contains('google.com/maps')));
    });

    test('navigationCoordinatesForUrl lê sfmap e Google Maps', () {
      final external = ReportMapLinks.externalUrl(-3.5, -45.2);
      final fromExternal = ReportMapLinks.navigationCoordinatesForUrl(external);
      expect(fromExternal?.lat, -3.5);
      expect(fromExternal?.lng, -45.2);

      final fromSfmap = ReportMapLinks.navigationCoordinatesForUrl(
        ReportMapLinks.linkFor(-3.5, -45.2),
      );
      expect(fromSfmap?.lat, -3.5);
      expect(fromSfmap?.lng, -45.2);
    });
  });

  group('decideNavigation — mapa', () {
    test('sfmap e Google Maps abrem foco no mapa', () {
      final sfmap = ReportMapLinks.linkFor(-10.1, -48.2);
      final decisionSf = ReportPhotoLinks.decideNavigation(sfmap);
      expect(decisionSf.action, ReportNavigationAction.openMap);
      expect(decisionSf.mapLat, -10.1);
      expect(decisionSf.mapLng, -48.2);

      final maps = ReportMapLinks.externalUrl(-10.1, -48.2);
      final decisionMaps = ReportPhotoLinks.decideNavigation(maps);
      expect(decisionMaps.action, ReportNavigationAction.openMap);
    });
  });
}
