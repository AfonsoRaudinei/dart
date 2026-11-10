import 'dart:convert';

import 'package:latlong2/latlong.dart';

import '../../../core/geo/geo_json_polygon_geometry.dart';
import 'producer_link_models.dart';

/// GeoJSON de `fields.bordadura_geo` como texto. O PostgREST devolve
/// string ou objeto; os dois viram o mesmo JSON para o mapa.
String? linkedFieldGeometryJson(Object? value) {
  if (value == null) return null;
  if (value is String) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
  if (value is Map) {
    return jsonEncode(value);
  }
  return null;
}

Map<String, dynamic>? linkedFieldGeometryMap(String? geometryJson) {
  final raw = geometryJson?.trim() ?? '';
  if (raw.isEmpty) return null;
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) return Map<String, dynamic>.from(decoded);
  } catch (_) {
    return null;
  }
  return null;
}

/// Vértices dos talhões liberados pelo consultor, para encaixar a câmera.
/// Não inclui a propriedade própria do produtor.
List<LatLng> focusPointsForLinkedClients(List<ProducerLinkedClient> clients) {
  final points = <LatLng>[];
  for (final client in clients) {
    for (final farm in client.farms) {
      for (final field in farm.fields) {
        points.addAll(geoJsonVerticesForBounds(field.geometryJson));
      }
    }
  }
  return points;
}
