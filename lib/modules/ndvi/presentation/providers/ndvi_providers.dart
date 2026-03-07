import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/ndvi_repository_impl.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';

// ── Providers de infraestrutura ───────────────────────────────────────────────

final ndviLocalDatasourceProvider = Provider<NdviLocalDatasource>(
  (_) => NdviLocalDatasource(),
);

final ndviRemoteDatasourceProvider = Provider<NdviRemoteDatasource>(
  (_) => NdviRemoteDatasource(Supabase.instance.client),
);

final ndviRepositoryProvider = Provider<INdviRepository>((ref) {
  return NdviRepositoryImpl(
    remote: ref.watch(ndviRemoteDatasourceProvider),
    local: ref.watch(ndviLocalDatasourceProvider),
  );
});

// ── Provider principal: imagem NDVI por areaId + bbox + date ─────────────────

/// Agrupa os parâmetros do provider de imagem NDVI.
class NdviFetchParams {
  final String areaId;
  final List<double> bbox;
  final DateTime? date;

  const NdviFetchParams({
    required this.areaId,
    required this.bbox,
    this.date,
  });

  @override
  bool operator ==(Object other) =>
      other is NdviFetchParams &&
      other.areaId == areaId &&
      other.bbox.toString() == bbox.toString() &&
      other.date?.toIso8601String() == date?.toIso8601String();

  @override
  int get hashCode => Object.hash(areaId, bbox.toString(), date);
}

final ndviImageProvider = FutureProvider.family
    .autoDispose<NdviImage?, NdviFetchParams>((ref, params) async {
  final repo = ref.watch(ndviRepositoryProvider);
  return repo.fetchNdvi(
    areaId: params.areaId,
    bbox: params.bbox,
    date: params.date,
  );
});

// ── Índice de data selecionada na navegação ‹ › ─────────────────────────────
//
// ADR-008: StateProvider permitido para primitivos simples.
// A família é o areaId — índice independente por talhão.

final ndviDateIndexProvider =
    StateProvider.family.autoDispose<int, String>((ref, areaId) => 0);

// ── Talhão selecionado no dropdown do painel ──────────────────────────────────
//
// Inicializado com o areaId da sessão; pode ser trocado pelo usuário.

final ndviSelectedAreaProvider =
    StateProvider.family.autoDispose<String, String>(
        (ref, initialAreaId) => initialAreaId);
// ── Bbox por areaId: calculado do GeoJSON do talhão ──────────────────────────
//
// ndvi/ lê FieldRepository de consultoria/ apenas para obter a geometria.
// Esta é a única dependência ndvi → consultoria/ e é unidirecional.

final _ndviFieldRepositoryProvider = Provider<FieldRepository>(
  (_) => FieldRepository(),
);

/// Retorna a bounding box [lon_min, lat_min, lon_max, lat_max] do talhão ou
/// null se a geometria não estiver disponível.
final ndviAreaBboxProvider =
    FutureProvider.family.autoDispose<List<double>?, String>((ref, areaId) async {
  final repo = ref.watch(_ndviFieldRepositoryProvider);
  final field = await repo.getFieldById(areaId);
  if (field?.geometry == null) return null;
  return _computeBbox(field!.geometry!);
});

/// Calcula bbox a partir de GeoJSON [Polygon | MultiPolygon].
List<double>? _computeBbox(Map<String, dynamic> geometry) {
  final type = geometry['type'] as String?;
  final rawCoords = geometry['coordinates'];
  if (rawCoords == null || type == null) return null;

  double minLon = 180, maxLon = -180, minLat = 90, maxLat = -90;
  bool hasPoints = false;

  void processRing(List<dynamic> ring) {
    for (final point in ring) {
      if (point is List && point.length >= 2) {
        final lon = (point[0] as num).toDouble();
        final lat = (point[1] as num).toDouble();
        if (lon < minLon) minLon = lon;
        if (lon > maxLon) maxLon = lon;
        if (lat < minLat) minLat = lat;
        if (lat > maxLat) maxLat = lat;
        hasPoints = true;
      }
    }
  }

  try {
    if (type == 'Polygon') {
      for (final ring in rawCoords as List) {
        processRing(ring as List);
      }
    } else if (type == 'MultiPolygon') {
      for (final polygon in rawCoords as List) {
        for (final ring in polygon as List) {
          processRing(ring as List);
        }
      }
    }
  } catch (_) {
    return null;
  }

  if (!hasPoints) return null;
  return [minLon, minLat, maxLon, maxLat];
}