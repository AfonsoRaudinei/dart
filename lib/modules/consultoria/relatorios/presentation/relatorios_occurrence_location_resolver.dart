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

/// Id do talhão da ocorrência: geometria do cliente e, na falta, `areaId`
/// da sessão. Não persiste — só resolve para leitura.
Future<String?> resolveFieldIdForOccurrence({
  required String? clientId,
  required double? lat,
  required double? lng,
  required String? visitSessionId,
  IFarmLookup? farmLookup,
  IFieldLookup? fieldLookup,
  IVisitSessionLookup? visitSessionLookup,
}) async {
  final client = clientId?.trim() ?? '';
  if (client.isNotEmpty &&
      isValidOccurrencePoint(lat, lng) &&
      farmLookup != null &&
      fieldLookup != null) {
    try {
      final farms = await farmLookup.getFarmsByClient(client);
      for (final farm in farms) {
        final fields = await fieldLookup.listByFarmId(farm.id);
        for (final field in fields) {
          if (!fieldContainsPoint(field, lat!, lng!)) continue;
          final id = field.id.trim();
          if (id.isNotEmpty) return id;
        }
      }
    } catch (_) {
      // Segue para a sessão.
    }
  }

  final sessionId = visitSessionId?.trim() ?? '';
  if (sessionId.isEmpty || visitSessionLookup == null || fieldLookup == null) {
    return null;
  }
  try {
    final session = await visitSessionLookup.findById(sessionId);
    final areaId = session?.areaId?.trim() ?? '';
    if (areaId.isEmpty) return null;
    final field = await fieldLookup.findById(areaId);
    final resolved = field?.id.trim() ?? '';
    return resolved.isNotEmpty ? resolved : areaId;
  } catch (_) {
    return null;
  }
}

bool isValidOccurrencePoint(double? lat, double? lng) =>
    isValidGeoPoint(lat, lng);

/// Talhão (e fazenda) de uma ocorrência. [isKnown] exige `fieldId` preenchido.
class OccurrencePlace {
  const OccurrencePlace({this.fieldId, this.farmId});

  final String? fieldId;
  final String? farmId;

  bool get isKnown {
    final id = fieldId?.trim() ?? '';
    return id.isNotEmpty;
  }
}

/// Fazendas do produtor e talhões agrupados por fazenda.
class OccurrencePlaceCatalog {
  const OccurrencePlaceCatalog({
    this.farms = const [],
    this.fieldsByFarm = const {},
  });

  final List<FarmSummary> farms;
  final Map<String, List<FieldSummary>> fieldsByFarm;

  /// Talhões na ordem das fazendas do catálogo.
  List<FieldSummary> get fields {
    final ordered = <FieldSummary>[];
    final seen = <String>{};
    for (final farm in farms) {
      for (final field in fieldsByFarm[farm.id] ?? const <FieldSummary>[]) {
        if (seen.add(field.id)) ordered.add(field);
      }
    }
    return ordered;
  }
}

/// Dados mínimos para resolver o lugar, sem o tipo de ocorrência.
class OccurrencePlaceQuery {
  const OccurrencePlaceQuery({
    required this.id,
    this.persistedFieldId,
    this.lat,
    this.lng,
    this.visitSessionId,
  });

  final String id;
  final String? persistedFieldId;
  final double? lat;
  final double? lng;
  final String? visitSessionId;
}

/// 1. `persistedFieldId` no catálogo vence. Fora do catálogo → desconhecido
///    (não cai na geometria). 2. Ponto válido no primeiro talhão que contém.
/// 3. `session.areaId` no catálogo. 4. Desconhecido.
OccurrencePlace resolveOccurrencePlace({
  required OccurrencePlaceQuery query,
  required OccurrencePlaceCatalog catalog,
  VisitSessionSummary? session,
}) {
  final persisted = query.persistedFieldId?.trim() ?? '';
  if (persisted.isNotEmpty) {
    final field = _catalogField(catalog, persisted);
    if (field == null) return const OccurrencePlace();
    return OccurrencePlace(fieldId: field.id, farmId: field.farmId);
  }

  if (isValidOccurrencePoint(query.lat, query.lng)) {
    for (final field in catalog.fields) {
      if (!fieldContainsPoint(field, query.lat!, query.lng!)) continue;
      return OccurrencePlace(fieldId: field.id, farmId: field.farmId);
    }
  }

  final areaId = session?.areaId?.trim() ?? '';
  if (areaId.isNotEmpty) {
    final field = _catalogField(catalog, areaId);
    if (field != null) {
      return OccurrencePlace(fieldId: field.id, farmId: field.farmId);
    }
  }

  return const OccurrencePlace();
}

/// Fazendas do cliente e talhões de cada uma. Erro → catálogo vazio.
Future<OccurrencePlaceCatalog> loadOccurrencePlaceCatalog({
  required String clientId,
  required IFarmLookup farmLookup,
  required IFieldLookup fieldLookup,
}) async {
  try {
    final farms = await farmLookup.getFarmsByClient(clientId);
    final fieldsByFarm = <String, List<FieldSummary>>{};
    for (final farm in farms) {
      fieldsByFarm[farm.id] = await fieldLookup.listByFarmId(farm.id);
    }
    return OccurrencePlaceCatalog(farms: farms, fieldsByFarm: fieldsByFarm);
  } catch (_) {
    return const OccurrencePlaceCatalog();
  }
}

/// Resolve cada query. Só chama [IVisitSessionLookup.findById] quando o
/// fieldId persistido e a geometria não resolvem e há `visitSessionId`.
/// Erro de lookup = sessão null. Cache por id de sessão.
Future<Map<String, OccurrencePlace>> indexOccurrencePlaces({
  required List<OccurrencePlaceQuery> queries,
  required OccurrencePlaceCatalog catalog,
  IVisitSessionLookup? visitSessionLookup,
}) async {
  final places = <String, OccurrencePlace>{};
  final sessions = <String, VisitSessionSummary?>{};

  for (final query in queries) {
    VisitSessionSummary? session;
    final sessionId = _sessionIdIfNeeded(query, catalog);
    if (sessionId != null) {
      if (!sessions.containsKey(sessionId)) {
        sessions[sessionId] = await _findVisitSession(
          visitSessionLookup,
          sessionId,
        );
      }
      session = sessions[sessionId];
    }
    places[query.id] = resolveOccurrencePlace(
      query: query,
      catalog: catalog,
      session: session,
    );
  }
  return places;
}

FieldSummary? _catalogField(OccurrencePlaceCatalog catalog, String id) {
  final wanted = id.trim();
  if (wanted.isEmpty) return null;
  for (final field in catalog.fields) {
    if (field.id.trim() == wanted) return field;
  }
  return null;
}

/// Null quando o passo 1 ou o passo 2 já resolvem, ou não há sessão.
String? _sessionIdIfNeeded(
  OccurrencePlaceQuery query,
  OccurrencePlaceCatalog catalog,
) {
  final sessionId = query.visitSessionId?.trim() ?? '';
  if (sessionId.isEmpty) return null;
  final persisted = query.persistedFieldId?.trim() ?? '';
  if (persisted.isNotEmpty) return null;
  if (isValidOccurrencePoint(query.lat, query.lng)) {
    for (final field in catalog.fields) {
      if (fieldContainsPoint(field, query.lat!, query.lng!)) return null;
    }
  }
  return sessionId;
}

Future<VisitSessionSummary?> _findVisitSession(
  IVisitSessionLookup? lookup,
  String sessionId,
) async {
  if (lookup == null) return null;
  try {
    return await lookup.findById(sessionId);
  } catch (_) {
    return null;
  }
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
