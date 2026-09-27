import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';

/// Zoom mínimo útil no campo. O máximo começa em 18 e desce até caber no limite.
const int kFarmMapDownloadMinZoom = 14;
const int kFarmMapDownloadPreferredMaxZoom = 18;

/// Margem em graus ao redor dos talhões (~200 m).
const double kFarmMapDownloadPaddingDegrees = 0.002;

class FarmMapDownloadPlan {
  final double south;
  final double west;
  final double north;
  final double east;
  final int minZoom;
  final int maxZoom;
  final int tileCount;

  const FarmMapDownloadPlan({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.minZoom,
    required this.maxZoom,
    required this.tileCount,
  });
}

/// Retângulo só dos polígonos desenhados, com zoom que cabe em
/// [OfflineTileCacheService.maxTileDownloadCount].
///
/// Retorna null quando não há polígono com pelo menos 3 vértices.
/// Lança [OfflineTileCacheException] quando nem o zoom mínimo cabe no limite.
FarmMapDownloadPlan? buildFarmMapDownloadPlan({
  required Iterable<List<LatLng>> polygons,
  OfflineTileCacheService cache = const OfflineTileCacheService(),
  int minZoom = kFarmMapDownloadMinZoom,
  int preferredMaxZoom = kFarmMapDownloadPreferredMaxZoom,
  double paddingDegrees = kFarmMapDownloadPaddingDegrees,
}) {
  double? south;
  double? west;
  double? north;
  double? east;
  for (final ring in polygons) {
    if (ring.length < 3) continue;
    for (final point in ring) {
      final lat = point.latitude;
      final lng = point.longitude;
      if (!lat.isFinite || !lng.isFinite) continue;
      south = south == null || lat < south ? lat : south;
      north = north == null || lat > north ? lat : north;
      west = west == null || lng < west ? lng : west;
      east = east == null || lng > east ? lng : east;
    }
  }
  if (south == null || west == null || north == null || east == null) {
    return null;
  }

  const maxLat = 85.05112878;
  final paddedSouth = (south - paddingDegrees).clamp(-maxLat, maxLat);
  final paddedNorth = (north + paddingDegrees).clamp(-maxLat, maxLat);
  final paddedWest = (west - paddingDegrees).clamp(-180.0, 180.0);
  final paddedEast = (east + paddingDegrees).clamp(-180.0, 180.0);
  if (paddedSouth >= paddedNorth || paddedWest >= paddedEast) {
    return null;
  }

  for (var maxZoom = preferredMaxZoom; maxZoom >= minZoom; maxZoom--) {
    final tileCount = cache.estimateTileCount(
      south: paddedSouth,
      west: paddedWest,
      north: paddedNorth,
      east: paddedEast,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    if (tileCount <= OfflineTileCacheService.maxTileDownloadCount) {
      return FarmMapDownloadPlan(
        south: paddedSouth,
        west: paddedWest,
        north: paddedNorth,
        east: paddedEast,
        minZoom: minZoom,
        maxZoom: maxZoom,
        tileCount: tileCount,
      );
    }
  }

  throw OfflineTileCacheException(
    'A fazenda excede o limite de '
    '${OfflineTileCacheService.maxTileDownloadCount} tiles '
    'mesmo no zoom $minZoom.',
  );
}
