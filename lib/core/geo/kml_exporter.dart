import 'dart:convert';

import 'package:archive/archive.dart';

/// Polígono a exportar. [geometry] é GeoJSON Polygon/MultiPolygon
/// (`{type, coordinates}`), Feature (usa `geometry`) ou a mesma coisa em JSON.
class KmlPlacemark {
  const KmlPlacemark({required this.name, this.areaHa, required this.geometry});

  final String name;
  final double? areaHa;
  final Object? geometry;
}

class KmlExportException implements Exception {
  const KmlExportException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Polygon ou MultiPolygon com pelo menos um anel de 3 pontos distintos.
bool kmlGeometryHasValidPolygon(Object? geometry) {
  return _polygonsFromGeometry(geometry).isNotEmpty;
}

/// KML 2.2. Lança [KmlExportException] se nenhum polígono sobreviver ao filtro.
String buildKmlDocument({
  required String documentName,
  required List<KmlPlacemark> placemarks,
}) {
  final blocks = <String>[];
  for (final placemark in placemarks) {
    final polygons = _polygonsFromGeometry(placemark.geometry);
    if (polygons.isEmpty) continue;
    blocks.add(_placemarkXml(placemark, polygons));
  }
  if (blocks.isEmpty) {
    throw const KmlExportException('Nenhum polígono válido para exportar.');
  }

  final buffer = StringBuffer()
    ..writeln('<?xml version="1.0" encoding="UTF-8"?>')
    ..writeln('<kml xmlns="http://www.opengis.net/kml/2.2">')
    ..writeln('  <Document>')
    ..writeln('    <name>${_escapeXml(documentName)}</name>')
    ..write(blocks.join())
    ..writeln('  </Document>')
    ..write('</kml>');
  return buffer.toString();
}

/// ZIP com um único `doc.kml`.
List<int> buildKmzBytes({
  required String documentName,
  required List<KmlPlacemark> placemarks,
}) {
  final kml = buildKmlDocument(
    documentName: documentName,
    placemarks: placemarks,
  );
  final bytes = utf8.encode(kml);
  final archive = Archive()
    ..addFile(ArchiveFile('doc.kml', bytes.length, bytes));
  return ZipEncoder().encode(archive);
}

String _placemarkXml(KmlPlacemark placemark, List<_KmlPolygon> polygons) {
  final buffer = StringBuffer()
    ..writeln('    <Placemark>')
    ..writeln('      <name>${_escapeXml(placemark.name)}</name>');
  final areaHa = placemark.areaHa;
  if (areaHa != null) {
    buffer.writeln(
      '      <description>${_escapeXml('${areaHa.toStringAsFixed(2)} ha')}</description>',
    );
  }
  if (polygons.length == 1 && !polygons.first.fromMulti) {
    buffer.write(_polygonXml(polygons.first, indent: '      '));
  } else {
    buffer.writeln('      <MultiGeometry>');
    for (final polygon in polygons) {
      buffer.write(_polygonXml(polygon, indent: '        '));
    }
    buffer.writeln('      </MultiGeometry>');
  }
  buffer.writeln('    </Placemark>');
  return buffer.toString();
}

String _polygonXml(_KmlPolygon polygon, {required String indent}) {
  final buffer = StringBuffer()
    ..writeln('$indent<Polygon>')
    ..writeln(
      '$indent  <outerBoundaryIs><LinearRing><coordinates>${polygon.outer}</coordinates></LinearRing></outerBoundaryIs>',
    );
  for (final hole in polygon.holes) {
    buffer.writeln(
      '$indent  <innerBoundaryIs><LinearRing><coordinates>$hole</coordinates></LinearRing></innerBoundaryIs>',
    );
  }
  buffer.writeln('$indent</Polygon>');
  return buffer.toString();
}

class _KmlPolygon {
  const _KmlPolygon({
    required this.outer,
    required this.holes,
    required this.fromMulti,
  });

  final String outer;
  final List<String> holes;
  final bool fromMulti;
}

List<_KmlPolygon> _polygonsFromGeometry(Object? geometry) {
  final map = _geometryMap(geometry);
  if (map == null) return const [];
  final type = map['type'];
  final coordinates = map['coordinates'];
  if (type == 'Polygon') {
    final polygon = _polygonFromCoordinates(coordinates, fromMulti: false);
    return polygon == null ? const [] : [polygon];
  }
  if (type == 'MultiPolygon') {
    if (coordinates is! List) return const [];
    final polygons = <_KmlPolygon>[];
    for (final part in coordinates) {
      final polygon = _polygonFromCoordinates(part, fromMulti: true);
      if (polygon != null) polygons.add(polygon);
    }
    return polygons;
  }
  return const [];
}

Map<String, dynamic>? _geometryMap(Object? geometry) {
  if (geometry == null) return null;
  Object? decoded = geometry;
  if (geometry is String) {
    final raw = geometry.trim();
    if (raw.isEmpty) return null;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      return null;
    }
  }
  if (decoded is! Map) return null;
  final map = <String, dynamic>{};
  decoded.forEach((key, value) {
    map[key.toString()] = value;
  });
  if (map['type'] == 'Feature') {
    final inner = map['geometry'];
    if (inner is! Map) return null;
    final geometryMap = <String, dynamic>{};
    inner.forEach((key, value) {
      geometryMap[key.toString()] = value;
    });
    return geometryMap;
  }
  return map;
}

_KmlPolygon? _polygonFromCoordinates(
  Object? coordinates, {
  required bool fromMulti,
}) {
  if (coordinates is! List || coordinates.isEmpty) return null;
  final outer = _ringCoordinates(coordinates.first);
  if (outer == null) return null;
  final holes = <String>[];
  for (var i = 1; i < coordinates.length; i++) {
    final hole = _ringCoordinates(coordinates[i]);
    if (hole != null) holes.add(hole);
  }
  return _KmlPolygon(outer: outer, holes: holes, fromMulti: fromMulti);
}

/// Anel GeoJSON `[lng, lat]` → `lng,lat` fechado, ou null se < 3 pontos distintos.
String? _ringCoordinates(Object? ring) {
  if (ring is! List) return null;
  final points = <(double, double)>[];
  for (final raw in ring) {
    if (raw is! List || raw.length < 2) continue;
    final lng = raw[0];
    final lat = raw[1];
    if (lng is! num || lat is! num) continue;
    final lngValue = lng.toDouble();
    final latValue = lat.toDouble();
    if (!lngValue.isFinite || !latValue.isFinite) continue;
    points.add((lngValue, latValue));
  }
  if (points.isEmpty) return null;
  final first = points.first;
  final last = points.last;
  if (first.$1 != last.$1 || first.$2 != last.$2) {
    points.add(first);
  }
  final distinct = <String>{
    for (final point in points)
      '${_formatCoord(point.$1)}|${_formatCoord(point.$2)}',
  };
  if (distinct.length < 3) return null;
  return points
      .map((point) => '${_formatCoord(point.$1)},${_formatCoord(point.$2)}')
      .join(' ');
}

String _formatCoord(double value) => value.toStringAsFixed(7);

String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}
