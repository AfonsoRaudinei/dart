import 'dart:convert';

import '../../../../core/contracts/i_farm_lookup.dart';
import '../../../../core/contracts/i_field_lookup.dart';
import '../../../../core/contracts/i_visit_session_lookup.dart';

/// Fazenda/talhão resolvidos para o HTML de ocorrência. Vazio = desconhecido.
class OccurrenceLocationNames {
  const OccurrenceLocationNames({this.fazenda = '', this.talhao = ''});

  final String fazenda;
  final String talhao;
}

/// Ocorrência não persiste farmId/fieldId: resolve pela posição dentro da
/// geometria dos talhões do cliente e, na falta, pela sessão de visita.
Future<OccurrenceLocationNames> resolveOccurrenceLocationNames({
  required String? clientId,
  required double? lat,
  required double? lng,
  required String? visitSessionId,
  IFarmLookup? farmLookup,
  IFieldLookup? fieldLookup,
  IVisitSessionLookup? visitSessionLookup,
}) async {
  var fazenda = '';
  var talhao = '';

  final client = clientId?.trim() ?? '';
  if (client.isNotEmpty &&
      isValidOccurrencePoint(lat, lng) &&
      farmLookup != null &&
      fieldLookup != null) {
    try {
      final farms = await farmLookup.getFarmsByClient(client);
      search:
      for (final farm in farms) {
        final fields = await fieldLookup.listByFarmId(farm.id);
        for (final field in fields) {
          if (fieldContainsPoint(field, lat!, lng!)) {
            fazenda = farm.name.trim();
            talhao = field.name.trim();
            break search;
          }
        }
      }
    } catch (_) {
      fazenda = '';
      talhao = '';
    }
  }

  final sessionId = visitSessionId?.trim() ?? '';
  if (talhao.isEmpty && sessionId.isNotEmpty && visitSessionLookup != null) {
    VisitSessionSummary? session;
    try {
      session = await visitSessionLookup.findById(sessionId);
    } catch (_) {
      session = null;
    }
    var farmId = session?.farmId?.trim() ?? '';
    final areaId = session?.areaId?.trim() ?? '';
    if (areaId.isNotEmpty && fieldLookup != null) {
      try {
        final field = await fieldLookup.findById(areaId);
        if (field != null) {
          talhao = field.name.trim();
          if (farmId.isEmpty) farmId = field.farmId.trim();
        }
      } catch (_) {
        talhao = '';
      }
    }
    if (fazenda.isEmpty && farmId.isNotEmpty && farmLookup != null) {
      try {
        final farm = await farmLookup.findById(farmId);
        fazenda = farm?.name.trim() ?? '';
      } catch (_) {
        fazenda = '';
      }
    }
  }

  return OccurrenceLocationNames(fazenda: fazenda, talhao: talhao);
}

bool isValidOccurrencePoint(double? lat, double? lng) {
  if (lat == null || lng == null) return false;
  if (!lat.isFinite || !lng.isFinite) return false;
  return !(lat == 0 && lng == 0);
}

/// [FieldSummary.bbox] = `[minLon, minLat, maxLon, maxLat]` (pré-filtro).
bool fieldContainsPoint(FieldSummary field, double lat, double lng) {
  final bbox = field.bbox;
  if (bbox != null && bbox.length == 4) {
    if (lng < bbox[0] || lat < bbox[1] || lng > bbox[2] || lat > bbox[3]) {
      return false;
    }
  }
  return geoJsonContainsPoint(field.geometry, lat, lng);
}

/// Aceita Polygon, MultiPolygon, Feature e FeatureCollection.
/// Coordenadas GeoJSON são `[lon, lat]`.
bool geoJsonContainsPoint(String? geometryJson, double lat, double lng) {
  if (geometryJson == null || geometryJson.trim().isEmpty) return false;
  if (!isValidOccurrencePoint(lat, lng)) return false;
  Object? decoded;
  try {
    decoded = jsonDecode(geometryJson);
  } catch (_) {
    return false;
  }
  return _geoJsonObjectContains(decoded, lat, lng);
}

bool _geoJsonObjectContains(Object? node, double lat, double lng) {
  if (node is! Map) return false;
  switch (node['type']) {
    case 'Feature':
      return _geoJsonObjectContains(node['geometry'], lat, lng);
    case 'FeatureCollection':
      final features = node['features'];
      if (features is! List) return false;
      return features.any((f) => _geoJsonObjectContains(f, lat, lng));
    case 'Polygon':
      return _polygonContains(node['coordinates'], lat, lng);
    case 'MultiPolygon':
      final polygons = node['coordinates'];
      if (polygons is! List) return false;
      return polygons.any((p) => _polygonContains(p, lat, lng));
    default:
      return false;
  }
}

/// Primeiro anel = contorno externo; demais = furos.
bool _polygonContains(Object? rings, double lat, double lng) {
  if (rings is! List || rings.isEmpty) return false;
  if (!_ringContains(rings.first, lat, lng)) return false;
  for (final hole in rings.skip(1)) {
    if (_ringContains(hole, lat, lng)) return false;
  }
  return true;
}

bool _ringContains(Object? ring, double lat, double lng) {
  if (ring is! List || ring.length < 3) return false;
  final xs = <double>[];
  final ys = <double>[];
  for (final position in ring) {
    if (position is! List || position.length < 2) return false;
    final x = position[0];
    final y = position[1];
    if (x is! num || y is! num) return false;
    xs.add(x.toDouble());
    ys.add(y.toDouble());
  }

  var inside = false;
  for (var i = 0, j = xs.length - 1; i < xs.length; j = i++) {
    final crosses = (ys[i] > lat) != (ys[j] > lat);
    if (crosses &&
        lng < (xs[j] - xs[i]) * (lat - ys[i]) / (ys[j] - ys[i]) + xs[i]) {
      inside = !inside;
    }
  }
  return inside;
}
