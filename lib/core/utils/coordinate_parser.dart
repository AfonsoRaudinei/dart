import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

class CoordinateParser {
  static LatLng? parse(String raw) {
    final input = raw.trim();
    if (input.isEmpty) return null;

    final epsg = _parseEpsg(input);
    if (epsg != null) return epsg;

    final utm = _parseUtm(input);
    if (utm != null) return utm;

    final parts = input.split(RegExp(r'[;,]')).map((e) => e.trim()).toList();
    if (parts.length == 2) {
      final lat = _parseSingleCoordinate(parts[0], isLatitude: true);
      final lng = _parseSingleCoordinate(parts[1], isLatitude: false);
      if (lat != null && lng != null) {
        return _validLatLng(lat, lng) ? LatLng(lat, lng) : null;
      }
    }

    final decimal = _parseDecimalPair(input);
    if (decimal != null) return decimal;

    final hemiPair = _parseHemispherePair(input);
    if (hemiPair != null) return hemiPair;

    return null;
  }

  static LatLng? _parseDecimalPair(String input) {
    final normalized = input.replaceAll(',', '.');
    final values = RegExp(r'[-+]?\d+(?:\.\d+)?')
        .allMatches(normalized)
        .map((m) => double.tryParse(m.group(0)!))
        .whereType<double>()
        .toList();
    if (values.length < 2) return null;
    final lat = values[0];
    final lng = values[1];
    return _validLatLng(lat, lng) ? LatLng(lat, lng) : null;
  }

  static LatLng? _parseHemispherePair(String input) {
    final normalized = input.toUpperCase().replaceAll(',', '.');
    final matches = RegExp(
      r'([NS][^,;]+|[^,;]+[NS]|[EW][^,;]+|[^,;]+[EW])',
    ).allMatches(normalized);
    if (matches.length < 2) return null;

    String? latPart;
    String? lngPart;
    for (final m in matches) {
      final v = m.group(0)!.trim();
      if (RegExp(r'[NS]').hasMatch(v) && latPart == null) latPart = v;
      if (RegExp(r'[EW]').hasMatch(v) && lngPart == null) lngPart = v;
    }
    if (latPart == null || lngPart == null) return null;
    final lat = _parseSingleCoordinate(latPart, isLatitude: true);
    final lng = _parseSingleCoordinate(lngPart, isLatitude: false);
    if (lat == null || lng == null) return null;
    return _validLatLng(lat, lng) ? LatLng(lat, lng) : null;
  }

  static double? _parseSingleCoordinate(
    String part, {
    required bool isLatitude,
  }) {
    final up = part.toUpperCase().replaceAll(',', '.').trim();
    final nums = RegExp(r'[-+]?\d+(?:\.\d+)?')
        .allMatches(up)
        .map((m) => double.tryParse(m.group(0)!))
        .whereType<double>()
        .toList();
    if (nums.isEmpty) return null;

    final hasHemisphere = RegExp(isLatitude ? r'[NS]' : r'[EW]').hasMatch(up);
    final isNegativeByHemisphere = isLatitude
        ? up.contains('S')
        : up.contains('W');

    double value;
    if (up.contains('°') || up.contains("'") || up.contains('"')) {
      final deg = nums[0].abs();
      final min = nums.length > 1 ? nums[1].abs() : 0.0;
      final sec = nums.length > 2 ? nums[2].abs() : 0.0;
      value = deg + (min / 60.0) + (sec / 3600.0);
    } else if (nums.length >= 2 && hasHemisphere) {
      final deg = nums[0].abs();
      final min = nums[1].abs();
      value = deg + (min / 60.0);
    } else {
      value = nums[0];
    }

    if (isNegativeByHemisphere) value = -value;
    if (!hasHemisphere && nums[0] < 0) value = -value.abs();

    return value;
  }

  static LatLng? _parseUtm(String input) {
    final up = input.toUpperCase().replaceAll(',', '.');
    final m = RegExp(
      r'^(\d{1,2})([C-HJ-NP-X])\s+(\d+(?:\.\d+)?)\s+(\d+(?:\.\d+)?)$',
    ).firstMatch(up);
    if (m == null) return null;

    final zone = int.tryParse(m.group(1) ?? '');
    final band = m.group(2)!;
    final easting = double.tryParse(m.group(3) ?? '');
    final northing = double.tryParse(m.group(4) ?? '');
    if (zone == null || easting == null || northing == null) return null;

    final northernHemisphere = band.compareTo('N') >= 0;
    return _utmToLatLng(zone, easting, northing, northernHemisphere);
  }

  static LatLng? _parseEpsg(String input) {
    final up = input.toUpperCase().replaceAll(',', '.');
    final m = RegExp(
      r'^EPSG:\s*(\d{4,5})\s+([-+]?\d+(?:\.\d+)?)\s+([-+]?\d+(?:\.\d+)?)$',
    ).firstMatch(up);
    if (m == null) return null;

    final epsg = int.tryParse(m.group(1) ?? '');
    final first = double.tryParse(m.group(2) ?? '');
    final second = double.tryParse(m.group(3) ?? '');
    if (epsg == null || first == null || second == null) return null;

    if (epsg == 4326 || epsg == 4674) {
      return _validLatLng(first, second) ? LatLng(first, second) : null;
    }
    if (epsg >= 32601 && epsg <= 32660) {
      return _utmToLatLng(epsg - 32600, first, second, true);
    }
    if (epsg >= 32701 && epsg <= 32760) {
      return _utmToLatLng(epsg - 32700, first, second, false);
    }
    if (epsg >= 31977 && epsg <= 31985) {
      return _utmToLatLng(epsg - 31960, first, second, false);
    }
    return null;
  }

  static LatLng? _utmToLatLng(
    int zone,
    double easting,
    double northing,
    bool northernHemisphere,
  ) {
    if (zone < 1 ||
        zone > 60 ||
        easting < 100000 ||
        easting > 1000000 ||
        northing < 0 ||
        northing > 10000000) {
      return null;
    }

    const a = 6378137.0;
    const f = 1 / 298.257223563;
    const k0 = 0.9996;
    final e = math.sqrt(f * (2 - f));
    final e1sq = e * e / (1 - e * e);

    final x = easting - 500000.0;
    var y = northing;
    if (!northernHemisphere) y -= 10000000.0;

    final m = y / k0;
    final mu =
        m /
        (a *
            (1 -
                e * e / 4 -
                3 * math.pow(e, 4) / 64 -
                5 * math.pow(e, 6) / 256));

    final e1 = (1 - math.sqrt(1 - e * e)) / (1 + math.sqrt(1 - e * e));

    final j1 = 3 * e1 / 2 - 27 * math.pow(e1, 3) / 32;
    final j2 = 21 * math.pow(e1, 2) / 16 - 55 * math.pow(e1, 4) / 32;
    final j3 = 151 * math.pow(e1, 3) / 96;
    final j4 = 1097 * math.pow(e1, 4) / 512;

    final fp =
        mu +
        j1 * math.sin(2 * mu) +
        j2 * math.sin(4 * mu) +
        j3 * math.sin(6 * mu) +
        j4 * math.sin(8 * mu);

    final sinFp = math.sin(fp);
    final cosFp = math.cos(fp);
    final tanFp = math.tan(fp);

    final c1 = e1sq * cosFp * cosFp;
    final t1 = tanFp * tanFp;
    final n1 = a / math.sqrt(1 - e * e * sinFp * sinFp);
    final r1 = a * (1 - e * e) / math.pow(1 - e * e * sinFp * sinFp, 1.5);
    final d = x / (n1 * k0);

    final lat =
        fp -
        (n1 * tanFp / r1) *
            (d * d / 2 -
                (5 + 3 * t1 + 10 * c1 - 4 * c1 * c1 - 9 * e1sq) *
                    math.pow(d, 4) /
                    24 +
                (61 +
                        90 * t1 +
                        298 * c1 +
                        45 * t1 * t1 -
                        252 * e1sq -
                        3 * c1 * c1) *
                    math.pow(d, 6) /
                    720);

    final lonOrigin = ((zone - 1) * 6 - 180 + 3) * math.pi / 180.0;
    final lon =
        lonOrigin +
        (d -
                (1 + 2 * t1 + c1) * math.pow(d, 3) / 6 +
                (5 - 2 * c1 + 28 * t1 - 3 * c1 * c1 + 8 * e1sq + 24 * t1 * t1) *
                    math.pow(d, 5) /
                    120) /
            cosFp;

    final latDeg = lat * 180 / math.pi;
    final lonDeg = lon * 180 / math.pi;
    return _validLatLng(latDeg, lonDeg) ? LatLng(latDeg, lonDeg) : null;
  }

  static bool _validLatLng(double lat, double lng) {
    return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
  }
}
