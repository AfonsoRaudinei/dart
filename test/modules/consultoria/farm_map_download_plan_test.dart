import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_plan.dart';

void main() {
  const cache = OfflineTileCacheService();

  test('retângulo cobre os vértices com margem e zoom cheio em fazenda pequena', () {
    final plan = buildFarmMapDownloadPlan(
      polygons: [
        const [
          LatLng(-10.00, -48.00),
          LatLng(-10.01, -48.00),
          LatLng(-10.01, -47.99),
          LatLng(-10.00, -47.99),
        ],
      ],
    );

    expect(plan, isNotNull);
    expect(plan!.south, lessThan(-10.01));
    expect(plan.north, greaterThan(-10.00));
    expect(plan.west, lessThan(-48.00));
    expect(plan.east, greaterThan(-47.99));
    expect(plan.minZoom, kFarmMapDownloadMinZoom);
    expect(plan.maxZoom, kFarmMapDownloadPreferredMaxZoom);
    expect(
      plan.tileCount,
      lessThanOrEqualTo(OfflineTileCacheService.maxTileDownloadCount),
    );
    expect(
      plan.tileCount,
      cache.estimateTileCount(
        south: plan.south,
        west: plan.west,
        north: plan.north,
        east: plan.east,
        minZoom: plan.minZoom,
        maxZoom: plan.maxZoom,
      ),
    );
  });

  test('reduz o zoom máximo quando o retângulo passa de 5000 tiles', () {
    final plan = buildFarmMapDownloadPlan(
      polygons: [
        const [
          LatLng(-10.20, -48.20),
          LatLng(-10.20, -47.90),
          LatLng(-9.90, -47.90),
          LatLng(-9.90, -48.20),
        ],
      ],
    );

    expect(plan, isNotNull);
    expect(plan!.maxZoom, lessThan(kFarmMapDownloadPreferredMaxZoom));
    expect(
      plan.tileCount,
      lessThanOrEqualTo(OfflineTileCacheService.maxTileDownloadCount),
    );
    expect(
      cache.estimateTileCount(
        south: plan.south,
        west: plan.west,
        north: plan.north,
        east: plan.east,
        minZoom: plan.minZoom,
        maxZoom: plan.maxZoom + 1,
      ),
      greaterThan(OfflineTileCacheService.maxTileDownloadCount),
    );
  });

  test('sem polígono desenhado não monta plano', () {
    expect(
      buildFarmMapDownloadPlan(polygons: const [<LatLng>[]]),
      isNull,
    );
    expect(
      buildFarmMapDownloadPlan(
        polygons: const [
          [LatLng(-10, -48), LatLng(-10.01, -48)],
        ],
      ),
      isNull,
    );
  });
}
