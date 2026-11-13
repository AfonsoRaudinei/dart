import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import 'offline_tile_cache_service.dart';

/// Serve o tile gravado em Documents/offline_tiles sempre que o arquivo existe.
/// A rede só preenche o que ainda não foi baixado. Nada aqui apaga arquivo.
class PersistentOfflineTileProvider extends TileProvider {
  PersistentOfflineTileProvider({
    required String offlineRoot,
    required String layerKey,
    String? legacyRoot,
    Map<String, String>? headers,
  }) : this._(
         offlineRoot: offlineRoot,
         layerKey: layerKey,
         legacyRoot: legacyRoot,
         headers: headers ?? <String, String>{},
       );

  PersistentOfflineTileProvider._({
    required this.offlineRoot,
    required this.layerKey,
    required this.legacyRoot,
    super.headers,
  }) : _network = NetworkTileProvider(headers: headers);

  String offlineRoot;
  String layerKey;
  String? legacyRoot;
  final NetworkTileProvider _network;

  /// Troca a pasta sem descartar a instância que o TileLayer já segura.
  void retarget({
    required String offlineRoot,
    required String layerKey,
    String? legacyRoot,
  }) {
    this.offlineRoot = offlineRoot;
    this.layerKey = layerKey;
    this.legacyRoot = legacyRoot;
  }

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    final file = OfflineTileCacheService.persistedTileFile(
      offlineRoot: offlineRoot,
      legacyRoot: legacyRoot,
      layerKey: layerKey,
      z: coordinates.z,
      x: coordinates.x,
      y: coordinates.y,
    );
    if (file != null) return FileImage(file);
    return _network.getImage(coordinates, options);
  }

  @override
  Future<void> dispose() async {
    await _network.dispose();
    super.dispose();
  }
}
