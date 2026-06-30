import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class OfflineTileCacheException implements Exception {
  final String message;

  const OfflineTileCacheException(this.message);

  @override
  String toString() => message;
}

class OfflinePrefetchProgress {
  final int total;
  final int processed;
  final int downloaded;
  final int skipped;
  final int failed;

  const OfflinePrefetchProgress({
    required this.total,
    required this.processed,
    required this.downloaded,
    required this.skipped,
    required this.failed,
  });

  double get fraction => total == 0 ? 0 : processed / total;
}

class OfflinePrefetchResult extends OfflinePrefetchProgress {
  final bool cancelled;

  const OfflinePrefetchResult({
    required super.total,
    required super.processed,
    required super.downloaded,
    required super.skipped,
    required super.failed,
    required this.cancelled,
  });

  bool get isComplete => !cancelled && failed == 0 && processed == total;
}

class OfflineTileCacheService {
  const OfflineTileCacheService();

  static const maxTileDownloadCount = 5000;
  static const maxZoom = 22;
  static const _maxWebMercatorLatitude = 85.05112878;

  String layerKeyFromTemplate(String template) =>
      sha256.convert(utf8.encode(template)).toString();

  Future<Directory> _baseDir() async {
    final dir = await getApplicationDocumentsDirectory();
    final root = Directory('${dir.path}/offline_tiles');
    if (!root.existsSync()) {
      root.createSync(recursive: true);
    }
    return root;
  }

  Future<String> rootPath() async => (await _baseDir()).path;

  Future<File> tileFile({
    required String layerKey,
    required int z,
    required int x,
    required int y,
  }) async {
    final root = await _baseDir();
    final d = Directory('${root.path}/$layerKey/$z/$x');
    if (!d.existsSync()) {
      d.createSync(recursive: true);
    }
    return File('${d.path}/$y.tile');
  }

  Future<bool> hasTile({
    required String layerKey,
    required int z,
    required int x,
    required int y,
  }) async {
    final root = await _baseDir();
    final file = File('${root.path}/$layerKey/$z/$x/$y.tile');
    return file.existsSync() && file.lengthSync() > 0;
  }

  Future<bool> hasTileAtPoint({
    required String layerKey,
    required double lat,
    required double lng,
    required int zoom,
  }) {
    _validateZoomRange(zoom, zoom);
    return hasTile(
      layerKey: layerKey,
      z: zoom,
      x: _long2tile(lng, zoom),
      y: _lat2tile(lat, zoom),
    );
  }

  Future<bool> hasTilesForArea({
    required String layerKey,
    required double south,
    required double west,
    required double north,
    required double east,
    required int zoom,
  }) async {
    _validateArea(south: south, west: west, north: north, east: east);
    _validateZoomRange(zoom, zoom);
    final range = _rangeFor(
      south: south,
      west: west,
      north: north,
      east: east,
      zoom: zoom,
    );
    for (int x = range.xMin; x <= range.xMax; x++) {
      for (int y = range.yMin; y <= range.yMax; y++) {
        if (!await hasTile(layerKey: layerKey, z: zoom, x: x, y: y)) {
          return false;
        }
      }
    }
    return true;
  }

  int estimateTileCount({
    required double south,
    required double west,
    required double north,
    required double east,
    required int minZoom,
    required int maxZoom,
  }) {
    _validateArea(south: south, west: west, north: north, east: east);
    _validateZoomRange(minZoom, maxZoom);
    int total = 0;
    for (int zoom = minZoom; zoom <= maxZoom; zoom++) {
      final range = _rangeFor(
        south: south,
        west: west,
        north: north,
        east: east,
        zoom: zoom,
      );
      total += (range.xMax - range.xMin + 1) * (range.yMax - range.yMin + 1);
    }
    return total;
  }

  Future<OfflinePrefetchResult> prefetchArea({
    required String layerKey,
    required String urlTemplate,
    required List<String> subdomains,
    required double south,
    required double west,
    required double north,
    required double east,
    required int minZoom,
    required int maxZoom,
    Map<String, String> headers = const {},
    void Function(OfflinePrefetchProgress progress)? onProgress,
    bool Function()? shouldCancel,
  }) async {
    final total = estimateTileCount(
      south: south,
      west: west,
      north: north,
      east: east,
      minZoom: minZoom,
      maxZoom: maxZoom,
    );
    if (total > maxTileDownloadCount) {
      throw OfflineTileCacheException(
        'Área excede o limite de $maxTileDownloadCount tiles ($total solicitados). '
        'Reduza o zoom máximo ou aproxime o mapa.',
      );
    }

    int processed = 0;
    int downloaded = 0;
    int skipped = 0;
    int failed = 0;
    bool cancelled = false;
    final client = http.Client();

    void emitProgress() {
      onProgress?.call(
        OfflinePrefetchProgress(
          total: total,
          processed: processed,
          downloaded: downloaded,
          skipped: skipped,
          failed: failed,
        ),
      );
    }

    emitProgress();
    try {
      for (int z = minZoom; z <= maxZoom && !cancelled; z++) {
        final range = _rangeFor(
          south: south,
          west: west,
          north: north,
          east: east,
          zoom: z,
        );
        for (int x = range.xMin; x <= range.xMax && !cancelled; x++) {
          for (int y = range.yMin; y <= range.yMax; y++) {
            if (shouldCancel?.call() ?? false) {
              cancelled = true;
              break;
            }
            final file = await tileFile(layerKey: layerKey, z: z, x: x, y: y);
            if (file.existsSync() && file.lengthSync() > 0) {
              skipped++;
              processed++;
              emitProgress();
              continue;
            }

            final url = _resolveUrl(
              urlTemplate: urlTemplate,
              z: z,
              x: x,
              y: y,
              subdomains: subdomains,
            );

            try {
              final res = await client.get(Uri.parse(url), headers: headers);
              if (res.statusCode >= 200 && res.statusCode < 300) {
                await file.writeAsBytes(res.bodyBytes, flush: true);
                downloaded++;
              } else {
                failed++;
              }
            } catch (_) {
              failed++;
            }
            processed++;
            emitProgress();
          }
        }
      }
    } finally {
      client.close();
    }
    return OfflinePrefetchResult(
      total: total,
      processed: processed,
      downloaded: downloaded,
      skipped: skipped,
      failed: failed,
      cancelled: cancelled,
    );
  }

  ({int xMin, int xMax, int yMin, int yMax}) _rangeFor({
    required double south,
    required double west,
    required double north,
    required double east,
    required int zoom,
  }) {
    return (
      xMin: _long2tile(west, zoom),
      xMax: _long2tile(east, zoom),
      yMin: _lat2tile(north, zoom),
      yMax: _lat2tile(south, zoom),
    );
  }

  void _validateArea({
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    if (!south.isFinite ||
        !west.isFinite ||
        !north.isFinite ||
        !east.isFinite ||
        south >= north ||
        west >= east ||
        south < -_maxWebMercatorLatitude ||
        north > _maxWebMercatorLatitude ||
        west < -180 ||
        east > 180) {
      throw const OfflineTileCacheException(
        'Área offline inválida. Use um bbox dentro dos limites do mapa.',
      );
    }
  }

  void _validateZoomRange(int minZoom, int maxZoom) {
    if (minZoom < 0 ||
        maxZoom > OfflineTileCacheService.maxZoom ||
        minZoom > maxZoom) {
      throw const OfflineTileCacheException(
        'Zoom offline inválido. Use valores entre 0 e 22, com mínimo menor ou igual ao máximo.',
      );
    }
  }

  String _resolveUrl({
    required String urlTemplate,
    required int z,
    required int x,
    required int y,
    required List<String> subdomains,
  }) {
    final subdomain = subdomains.isEmpty
        ? ''
        : subdomains[(x + y) % subdomains.length];
    return urlTemplate
        .replaceAll('{z}', '$z')
        .replaceAll('{x}', '$x')
        .replaceAll('{y}', '$y')
        .replaceAll('{s}', subdomain)
        .replaceAll('{r}', '');
  }

  int _long2tile(double lon, int zoom) {
    final maxIndex = (1 << zoom) - 1;
    final normalized = lon.clamp(-180.0, 180.0);
    return (((normalized + 180.0) / 360.0) * (1 << zoom)).floor().clamp(
      0,
      maxIndex,
    );
  }

  int _lat2tile(double lat, int zoom) {
    final maxIndex = (1 << zoom) - 1;
    final normalized = lat.clamp(
      -_maxWebMercatorLatitude,
      _maxWebMercatorLatitude,
    );
    final latRad = normalized * math.pi / 180.0;
    final n = math.pi - math.log(math.tan(math.pi / 4.0 + latRad / 2.0));
    return (((n / math.pi) / 2.0) * (1 << zoom)).floor().clamp(0, maxIndex);
  }
}
