import '../../../../core/contracts/i_farm_lookup.dart';
import '../../../../core/contracts/i_field_lookup.dart';
import '../../../../core/contracts/i_visit_session_lookup.dart';
import '../../../../core/geo/geo_json_polygon_geometry.dart';

export '../../../../core/geo/geo_json_polygon_geometry.dart'
    show geoJsonContainsPoint, isValidGeoPoint;

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

bool isValidOccurrencePoint(double? lat, double? lng) =>
    isValidGeoPoint(lat, lng);

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
