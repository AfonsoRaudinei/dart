/// Links de localização em relatórios HTML (`sfmap://` no app, Maps na exportação).
abstract final class ReportMapLinks {
  static const scheme = 'sfmap';

  static const _label = 'Ponto registrado no mapa';

  static final _mapAnchor = RegExp(
    r'<a class="sf-map-link" href="[^"]*"\s+data-sf-lat="([^"]+)"\s+data-sf-lng="([^"]+)"([^>]*)>',
    caseSensitive: false,
  );

  static final _externalMapsHost = RegExp(
    r'^https://(www\.)?google\.com/maps/',
    caseSensitive: false,
  );

  /// URL universal para abrir o ponto em apps de mapa (exportação / navegador).
  static String externalUrl(double lat, double lng) {
    final la = lat.toStringAsFixed(6);
    final ln = lng.toStringAsFixed(6);
    return 'https://www.google.com/maps/search/?api=1&query=$la,$ln';
  }

  static String linkFor(double lat, double lng) {
    return Uri(
      scheme: scheme,
      host: 'open',
      queryParameters: {
        'lat': lat.toStringAsFixed(6),
        'lng': lng.toStringAsFixed(6),
      },
    ).toString();
  }

  /// Âncora clicável para a ficha técnica (exportação usa [externalUrl]).
  static String anchorHtml(double lat, double lng) {
    if (!isValidCoordinate(lat, lng)) return '';
    final href = externalUrl(lat, lng);
    final la = lat.toStringAsFixed(6);
    final ln = lng.toStringAsFixed(6);
    return '<a class="sf-map-link" href="$href" '
        'data-sf-lat="$la" data-sf-lng="$ln">$_label</a>';
  }

  static bool isValidCoordinate(double? lat, double? lng) {
    if (lat == null || lng == null) return false;
    if (!lat.isFinite || !lng.isFinite) return false;
    if (lat == 0 && lng == 0) return false;
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }

  static double? _parseCoord(String? raw) {
    if (raw == null) return null;
    final value = double.tryParse(raw.trim());
    if (value == null || !value.isFinite) return null;
    return value;
  }

  /// Coordenadas de `sfmap://open?lat=&lng=` ou `null`.
  static ({double lat, double lng})? coordinatesFromUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || uri.scheme != scheme) return null;
    final lat = _parseCoord(uri.queryParameters['lat']);
    final lng = _parseCoord(uri.queryParameters['lng']);
    if (lat == null || lng == null) return null;
    if (!isValidCoordinate(lat, lng)) return null;
    return (lat: lat, lng: lng);
  }

  /// Extrai lat/lng de links Google Maps (`query=lat,lng`).
  static ({double lat, double lng})? coordinatesFromExternalUrl(String url) {
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !_externalMapsHost.hasMatch(uri.toString())) {
      return null;
    }
    final query = uri.queryParameters['query'];
    if (query == null) return null;
    final parts = query.split(',');
    if (parts.length < 2) return null;
    final lat = _parseCoord(parts[0]);
    final lng = _parseCoord(parts[1]);
    if (lat == null || lng == null) return null;
    if (!isValidCoordinate(lat, lng)) return null;
    return (lat: lat, lng: lng);
  }

  /// Na cópia in-app, troca href externo por `sfmap://` (WebView intercepta).
  static String rewriteForInApp(String html) {
    return html.replaceAllMapped(_mapAnchor, (match) {
      final lat = _parseCoord(match.group(1));
      final lng = _parseCoord(match.group(2));
      if (lat == null || lng == null) return match.group(0)!;
      final tail = match.group(3) ?? '';
      return '<a class="sf-map-link" href="${linkFor(lat, lng)}" '
          'data-sf-lat="${lat.toStringAsFixed(6)}" '
          'data-sf-lng="${lng.toStringAsFixed(6)}"$tail>';
    });
  }

  /// Coordenadas para foco no mapa (`sfmap://` ou Google Maps exportado).
  static ({double lat, double lng})? navigationCoordinatesForUrl(String url) {
    final custom = coordinatesFromUrl(url);
    if (custom != null) return custom;
    return coordinatesFromExternalUrl(url);
  }
}
