import 'dart:io';

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import 'offline_tile_cache_service.dart';

/// Serve o tile gravado em Documents/offline_tiles sempre que o arquivo existe.
/// A rede só preenche o que ainda não foi baixado. Nada aqui apaga arquivo.
class PersistentOfflineTileProvider extends TileProvider {
  PersistentOfflineTileProvider({
    required String offlineRoot,
    required String layerKey,
    Map<String, String>? headers,
  }) : this._(
         offlineRoot: offlineRoot,
         layerKey: layerKey,
         headers: headers ?? <String, String>{},
       );

  PersistentOfflineTileProvider._({
    required this.offlineRoot,
    required this.layerKey,
    super.headers,
  }) : _network = NetworkTileProvider(headers: headers);

  final String offlineRoot;
  final String layerKey;
  final NetworkTileProvider _network;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final file = File(
      OfflineTileCacheService.tileFilePath(
        rootPath: offlineRoot,
        layerKey: layerKey,
        z: coordinates.z,
        x: coordinates.x,
        y: coordinates.y,
      ),
    );
    if (OfflineTileCacheService.shouldServePersistedOfflineTile(
      localTileExists: OfflineTileCacheService.persistedTileFileExists(file),
    )) {
      return FileImage(file);
    }
    return _network.getImage(coordinates, options);
  }

  @override
  Future<void> dispose() async {
    await _network.dispose();
    super.dispose();
  }
}
