import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Extrai coordenadas de links do Google Maps (incl. maps.app.goo.gl).
class GoogleMapsLinkParser {
  GoogleMapsLinkParser({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static final _mapsHostPattern = RegExp(
    r'(maps\.app\.goo\.gl|goo\.gl/maps|google\.[^/]+/maps|maps\.google\.)',
    caseSensitive: false,
  );

  static bool looksLikeGoogleMapsLink(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return false;
    final uri = Uri.tryParse(input);
    if (uri == null || !uri.hasScheme) {
      return _mapsHostPattern.hasMatch(input);
    }
    return _mapsHostPattern.hasMatch(uri.host + uri.path);
  }

  /// Tenta extrair lat/lng de uma URL já expandida (sem rede).
  static LatLng? parseCoordinatesFromUrl(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    final candidates = <String>[input];
    final uri = Uri.tryParse(input);
    if (uri != null) {
      candidates.add(uri.toString());
      if (uri.hasQuery) {
        candidates.add(uri.query);
      }
    }

    for (final candidate in candidates) {
      final place = _matchPlaceCoords(candidate);
      if (place != null) return place;

      final at = _matchAtCoords(candidate);
      if (at != null) return at;

      final param = _matchQueryPair(candidate);
      if (param != null) return param;
    }
    return null;
  }

  /// Resolve links curtos via redirect HTTP e extrai coordenadas.
  Future<LatLng?> resolve(String raw) async {
    final input = raw.trim();
    if (input.isEmpty) return null;

    final direct = parseCoordinatesFromUrl(input);
    if (direct != null) return direct;

    if (!looksLikeGoogleMapsLink(input)) return null;

    try {
      final expanded = await _expandUrl(input);
      return parseCoordinatesFromUrl(expanded);
    } on TimeoutException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<String> _expandUrl(String url) async {
    final response = await _client
        .get(Uri.parse(url), headers: const {'User-Agent': 'SoloForte'})
        .timeout(const Duration(seconds: 10));

    final finalUri = response.request?.url;
    if (finalUri != null) {
      return finalUri.toString();
    }
    return url;
  }

  static LatLng? _matchPlaceCoords(String input) {
    final m = RegExp(
      r'!3d(-?\d+(?:\.\d+)?)!4d(-?\d+(?:\.\d+)?)',
    ).firstMatch(input);
    if (m == null) return null;
    return _toLatLng(m.group(1), m.group(2));
  }

  static LatLng? _matchAtCoords(String input) {
    final m = RegExp(
      r'@(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)',
    ).firstMatch(input);
    if (m == null) return null;
    return _toLatLng(m.group(1), m.group(2));
  }

  static LatLng? _matchQueryPair(String input) {
    final patterns = [
      RegExp(r'[?&]query=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)'),
      RegExp(r'[?&]q=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)'),
      RegExp(r'[?&]ll=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)'),
      RegExp(r'[?&]center=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)'),
      RegExp(r'[?&]destination=(-?\d+(?:\.\d+)?),(-?\d+(?:\.\d+)?)'),
    ];
    for (final pattern in patterns) {
      final m = pattern.firstMatch(input);
      if (m != null) {
        final point = _toLatLng(m.group(1), m.group(2));
        if (point != null) return point;
      }
    }
    return null;
  }

  static LatLng? _toLatLng(String? latRaw, String? lngRaw) {
    final lat = double.tryParse(latRaw ?? '');
    final lng = double.tryParse(lngRaw ?? '');
    if (lat == null || lng == null) return null;
    if (lat < -90 || lat > 90 || lng < -180 || lng > 180) return null;
    return LatLng(lat, lng);
  }
}
