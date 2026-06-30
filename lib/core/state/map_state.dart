import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:convert';
import '../infra/preferences_service.dart';
import '../services/connectivity_service.dart';
import '../services/offline_tile_cache_service.dart';
import '../domain/map_models.dart';
import '../domain/publicacao.dart';
import '../data/map_repository.dart';
import '../utils/app_logger.dart';

part 'map_state.g.dart';

@Riverpod(keepAlive: true)
MapRepository mapRepository(Ref ref) {
  return MapRepository(
    ref.watch(preferencesServiceProvider),
    ref.watch(connectivityServiceProvider),
  );
}

final offlineTileCacheServiceProvider = Provider<OfflineTileCacheService>((
  ref,
) {
  return const OfflineTileCacheService();
});

final offlineTileCacheRootPathProvider = FutureProvider<String>((ref) async {
  final service = ref.watch(offlineTileCacheServiceProvider);
  return service.rootPath();
});

// State for active layer type
@Riverpod(keepAlive: true)
class ActiveLayer extends _$ActiveLayer {
  static const _kLayerKey = 'map_active_layer';

  @override
  LayerType build() {
    _loadPersistedLayer();
    return LayerType.satellite;
  }

  Future<void> _loadPersistedLayer() async {
    try {
      final prefs = ref.read(preferencesServiceProvider);
      final saved = prefs.getString(_kLayerKey);
      if (saved != null) {
        final savedLayer = LayerType.values.firstWhere(
          (e) => e.toString() == saved,
          orElse: () => LayerType.satellite,
        );
        final verify = savedLayer == LayerType.standard
            ? LayerType.satellite
            : savedLayer;
        if (verify != state) {
          state = verify;
          prefs.setString(_kLayerKey, verify.toString());
        }
      }
    } catch (e) {
      AppLogger.warning(
        'Falha ao restaurar layer persistida — usando padrão',
        tag: 'MapState',
        error: e,
      );
    }
  }

  void setLayer(LayerType type) {
    state = type;
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setString(_kLayerKey, type.toString());
  }
}

// State for markers toggle
@Riverpod(keepAlive: true)
class ShowMarkers extends _$ShowMarkers {
  static const _kKey = 'map_show_markers_v1';

  @override
  bool build() {
    final prefs = ref.read(preferencesServiceProvider);
    return prefs.getBool(_kKey) ?? true;
  }

  void toggle() {
    state = !state;
    ref.read(preferencesServiceProvider).setBool(_kKey, state);
  }
}

class ExternalWmsLayerConfig {
  final bool enabled;
  final String baseUrl;
  final String layers;
  final String format;
  final bool transparent;
  final String version;
  final String crs;

  const ExternalWmsLayerConfig({
    this.enabled = false,
    this.baseUrl = '',
    this.layers = '',
    this.format = 'image/png',
    this.transparent = true,
    this.version = '1.1.1',
    this.crs = 'EPSG:3857',
  });

  ExternalWmsLayerConfig copyWith({
    bool? enabled,
    String? baseUrl,
    String? layers,
    String? format,
    bool? transparent,
    String? version,
    String? crs,
  }) {
    return ExternalWmsLayerConfig(
      enabled: enabled ?? this.enabled,
      baseUrl: baseUrl ?? this.baseUrl,
      layers: layers ?? this.layers,
      format: format ?? this.format,
      transparent: transparent ?? this.transparent,
      version: version ?? this.version,
      crs: crs ?? this.crs,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'baseUrl': baseUrl,
    'layers': layers,
    'format': format,
    'transparent': transparent,
    'version': version,
    'crs': crs,
  };

  factory ExternalWmsLayerConfig.fromJson(Map<String, dynamic> json) {
    return ExternalWmsLayerConfig(
      enabled: json['enabled'] == true,
      baseUrl: (json['baseUrl'] ?? '') as String,
      layers: (json['layers'] ?? '') as String,
      format: (json['format'] ?? 'image/png') as String,
      transparent: json['transparent'] != false,
      version: (json['version'] ?? '1.1.1') as String,
      crs: (json['crs'] ?? 'EPSG:3857') as String,
    );
  }
}

class ExternalRasterLayerConfig {
  final bool enabled;
  final String urlTemplate;
  final double opacity;
  final bool isGeoTiff;
  final String geoTiffTileEndpoint;
  final String? localPngPath;
  final double? localSouth;
  final double? localWest;
  final double? localNorth;
  final double? localEast;

  const ExternalRasterLayerConfig({
    this.enabled = false,
    this.urlTemplate = '',
    this.opacity = 0.75,
    this.isGeoTiff = false,
    this.geoTiffTileEndpoint = 'https://titiler.xyz',
    this.localPngPath,
    this.localSouth,
    this.localWest,
    this.localNorth,
    this.localEast,
  });

  bool get hasLocalGeoTiff =>
      localPngPath != null &&
      localSouth != null &&
      localWest != null &&
      localNorth != null &&
      localEast != null;

  ExternalRasterLayerConfig copyWith({
    bool? enabled,
    String? urlTemplate,
    double? opacity,
    bool? isGeoTiff,
    String? geoTiffTileEndpoint,
    String? localPngPath,
    double? localSouth,
    double? localWest,
    double? localNorth,
    double? localEast,
    bool clearLocalGeoTiff = false,
  }) {
    return ExternalRasterLayerConfig(
      enabled: enabled ?? this.enabled,
      urlTemplate: urlTemplate ?? this.urlTemplate,
      opacity: opacity ?? this.opacity,
      isGeoTiff: isGeoTiff ?? this.isGeoTiff,
      geoTiffTileEndpoint: geoTiffTileEndpoint ?? this.geoTiffTileEndpoint,
      localPngPath: clearLocalGeoTiff
          ? null
          : localPngPath ?? this.localPngPath,
      localSouth: clearLocalGeoTiff ? null : localSouth ?? this.localSouth,
      localWest: clearLocalGeoTiff ? null : localWest ?? this.localWest,
      localNorth: clearLocalGeoTiff ? null : localNorth ?? this.localNorth,
      localEast: clearLocalGeoTiff ? null : localEast ?? this.localEast,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'urlTemplate': urlTemplate,
    'opacity': opacity,
    'isGeoTiff': isGeoTiff,
    'geoTiffTileEndpoint': geoTiffTileEndpoint,
    'localPngPath': localPngPath,
    'localSouth': localSouth,
    'localWest': localWest,
    'localNorth': localNorth,
    'localEast': localEast,
  };

  factory ExternalRasterLayerConfig.fromJson(Map<String, dynamic> json) {
    return ExternalRasterLayerConfig(
      enabled: json['enabled'] == true,
      urlTemplate: (json['urlTemplate'] ?? '') as String,
      opacity: ((json['opacity'] ?? 0.75) as num).toDouble(),
      isGeoTiff: json['isGeoTiff'] == true,
      geoTiffTileEndpoint:
          (json['geoTiffTileEndpoint'] ?? 'https://titiler.xyz') as String,
      localPngPath: json['localPngPath'] as String?,
      localSouth: (json['localSouth'] as num?)?.toDouble(),
      localWest: (json['localWest'] as num?)?.toDouble(),
      localNorth: (json['localNorth'] as num?)?.toDouble(),
      localEast: (json['localEast'] as num?)?.toDouble(),
    );
  }
}

class ExternalWmsLayerNotifier extends Notifier<ExternalWmsLayerConfig> {
  static const _kKey = 'map_external_wms_v1';

  @override
  ExternalWmsLayerConfig build() {
    try {
      final prefs = ref.read(preferencesServiceProvider);
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return const ExternalWmsLayerConfig();
      return ExternalWmsLayerConfig.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const ExternalWmsLayerConfig();
    }
  }

  void update(ExternalWmsLayerConfig next) {
    state = next;
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setString(_kKey, jsonEncode(next.toJson()));
  }
}

class ExternalRasterLayerNotifier extends Notifier<ExternalRasterLayerConfig> {
  static const _kKey = 'map_external_raster_v1';

  @override
  ExternalRasterLayerConfig build() {
    try {
      final prefs = ref.read(preferencesServiceProvider);
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return const ExternalRasterLayerConfig();
      return ExternalRasterLayerConfig.fromJson(
        jsonDecode(raw) as Map<String, dynamic>,
      );
    } catch (_) {
      return const ExternalRasterLayerConfig();
    }
  }

  void update(ExternalRasterLayerConfig next) {
    state = next;
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setString(_kKey, jsonEncode(next.toJson()));
  }
}

class OfflineMapAreaConfig {
  final String id;
  final String layerKey;
  final double south;
  final double west;
  final double north;
  final double east;
  final double minZoom;
  final double maxZoom;
  final DateTime createdAt;

  const OfflineMapAreaConfig({
    required this.id,
    required this.layerKey,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.minZoom,
    required this.maxZoom,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'layerKey': layerKey,
    'south': south,
    'west': west,
    'north': north,
    'east': east,
    'minZoom': minZoom,
    'maxZoom': maxZoom,
    'createdAt': createdAt.toIso8601String(),
  };

  factory OfflineMapAreaConfig.fromJson(Map<String, dynamic> json) {
    return OfflineMapAreaConfig(
      id: (json['id'] ?? '') as String,
      layerKey: (json['layerKey'] ?? '') as String,
      south: ((json['south'] ?? 0.0) as num).toDouble(),
      west: ((json['west'] ?? 0.0) as num).toDouble(),
      north: ((json['north'] ?? 0.0) as num).toDouble(),
      east: ((json['east'] ?? 0.0) as num).toDouble(),
      minZoom: ((json['minZoom'] ?? 12.0) as num).toDouble(),
      maxZoom: ((json['maxZoom'] ?? 18.0) as num).toDouble(),
      createdAt:
          DateTime.tryParse((json['createdAt'] ?? '') as String) ??
          DateTime.now(),
    );
  }

  bool covers({
    required String layerKey,
    required double lat,
    required double lng,
    required double zoom,
  }) {
    return this.layerKey == layerKey &&
        lat >= south &&
        lat <= north &&
        lng >= west &&
        lng <= east &&
        zoom >= minZoom &&
        zoom <= maxZoom;
  }
}

class OfflineMapAreasNotifier extends Notifier<List<OfflineMapAreaConfig>> {
  static const _kKey = 'map_offline_areas_v1';

  @override
  List<OfflineMapAreaConfig> build() {
    try {
      final prefs = ref.read(preferencesServiceProvider);
      final raw = prefs.getString(_kKey);
      if (raw == null || raw.isEmpty) return const [];
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .map((e) => OfflineMapAreaConfig.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  void addArea(OfflineMapAreaConfig area) {
    state = [...state, area];
    _persist();
  }

  void clear() {
    state = const [];
    _persist();
  }

  void _persist() {
    final prefs = ref.read(preferencesServiceProvider);
    prefs.setString(
      _kKey,
      jsonEncode(state.map((e) => e.toJson()).toList(growable: false)),
    );
  }
}

final externalWmsLayerProvider =
    NotifierProvider<ExternalWmsLayerNotifier, ExternalWmsLayerConfig>(
      ExternalWmsLayerNotifier.new,
    );

final externalRasterLayerProvider =
    NotifierProvider<ExternalRasterLayerNotifier, ExternalRasterLayerConfig>(
      ExternalRasterLayerNotifier.new,
    );

final offlineMapAreasProvider =
    NotifierProvider<OfflineMapAreasNotifier, List<OfflineMapAreaConfig>>(
      OfflineMapAreasNotifier.new,
    );

class OfflineCoverageQuery {
  final String layerKey;
  final double lat;
  final double lng;
  final double south;
  final double west;
  final double north;
  final double east;
  final int zoom;

  const OfflineCoverageQuery({
    required this.layerKey,
    required this.lat,
    required this.lng,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
    required this.zoom,
  });

  @override
  bool operator ==(Object other) {
    return other is OfflineCoverageQuery &&
        other.layerKey == layerKey &&
        other.lat == lat &&
        other.lng == lng &&
        other.south == south &&
        other.west == west &&
        other.north == north &&
        other.east == east &&
        other.zoom == zoom;
  }

  @override
  int get hashCode =>
      Object.hash(layerKey, lat, lng, south, west, north, east, zoom);
}

/// Só informa cobertura quando a área foi registrada e todos os tiles visíveis
/// existem fisicamente no cache local.
final offlineCoverageProvider = FutureProvider.autoDispose
    .family<bool, OfflineCoverageQuery>((ref, query) {
      final areas = ref.watch(offlineMapAreasProvider);
      final metadataCovers = areas.any(
        (area) => area.covers(
          layerKey: query.layerKey,
          lat: query.lat,
          lng: query.lng,
          zoom: query.zoom.toDouble(),
        ),
      );
      if (!metadataCovers) return false;

      return ref
          .watch(offlineTileCacheServiceProvider)
          .hasTilesForArea(
            layerKey: query.layerKey,
            south: query.south,
            west: query.west,
            north: query.north,
            east: query.east,
            zoom: query.zoom,
          );
    });

enum AreaDisplayUnit { hectare, squareMeter, alqueire }

enum DistanceDisplayUnit { kilometer, meter }

class AreaDisplayUnitNotifier extends Notifier<AreaDisplayUnit> {
  static const _kKey = 'map_area_display_unit_v1';

  @override
  AreaDisplayUnit build() {
    final raw = ref.read(preferencesServiceProvider).getString(_kKey);
    return AreaDisplayUnit.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => AreaDisplayUnit.hectare,
    );
  }

  void setUnit(AreaDisplayUnit unit) {
    state = unit;
    ref.read(preferencesServiceProvider).setString(_kKey, unit.name);
  }
}

class DistanceDisplayUnitNotifier extends Notifier<DistanceDisplayUnit> {
  static const _kKey = 'map_distance_display_unit_v1';

  @override
  DistanceDisplayUnit build() {
    final raw = ref.read(preferencesServiceProvider).getString(_kKey);
    return DistanceDisplayUnit.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => DistanceDisplayUnit.kilometer,
    );
  }

  void setUnit(DistanceDisplayUnit unit) {
    state = unit;
    ref.read(preferencesServiceProvider).setString(_kKey, unit.name);
  }
}

final areaDisplayUnitProvider =
    NotifierProvider<AreaDisplayUnitNotifier, AreaDisplayUnit>(
      AreaDisplayUnitNotifier.new,
    );

final distanceDisplayUnitProvider =
    NotifierProvider<DistanceDisplayUnitNotifier, DistanceDisplayUnit>(
      DistanceDisplayUnitNotifier.new,
    );

// State for publications data (Legacy — @deprecated)
@Deprecated('Use PublicacoesData instead — ADR-007')
@Riverpod(keepAlive: true)
class PublicationsData extends _$PublicationsData {
  @override
  Future<List<Publication>> build() async {
    final repo = ref.read(mapRepositoryProvider);
    // ignore: deprecated_member_use_from_same_package
    return repo.fetchPublications();
  }
}

// State for publicações data (Canonical — ADR-007)
@Riverpod(keepAlive: true)
class PublicacoesData extends _$PublicacoesData {
  @override
  Future<List<Publicacao>> build() async {
    final repo = ref.read(mapRepositoryProvider);
    return repo.fetchPublicacoes();
  }
}
