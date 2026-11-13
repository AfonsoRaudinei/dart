import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;

import 'offline_tile_cache_service.dart';

/// Limita quantos tiles saem ao mesmo tempo.
///
/// No rádio lento, dezenas de pedidos juntos deixam a tela branca até o
/// primeiro JPEG voltar. Os primeiros pedidos (o que está na tela) passam;
/// o restante espera vaga.
class TileFetchSlots {
  TileFetchSlots({this.limit = 4});

  final int limit;
  int _used = 0;
  final List<Completer<void>> _queue = [];

  Future<void> acquire() {
    if (_used < limit) {
      _used++;
      return Future<void>.value();
    }
    final waiter = Completer<void>();
    _queue.add(waiter);
    return waiter.future;
  }

  void release() {
    if (_queue.isNotEmpty) {
      _queue.removeAt(0).complete();
      return;
    }
    if (_used > 0) _used--;
  }
}

/// Serve o tile gravado em Documents/offline_tiles sempre que o arquivo existe.
/// O que falta vai à rede e fica no disco da conta. Nada aqui apaga arquivo.
class PersistentOfflineTileProvider extends TileProvider {
  PersistentOfflineTileProvider({
    required String offlineRoot,
    required String layerKey,
    String? legacyRoot,
    TileFetchSlots? slots,
    http.Client? httpClient,
    Map<String, String>? headers,
  }) : this._(
         offlineRoot: offlineRoot,
         layerKey: layerKey,
         legacyRoot: legacyRoot,
         slots: slots ?? TileFetchSlots(),
         httpClient: httpClient ?? http.Client(),
         ownsClient: httpClient == null,
         headers: headers ?? <String, String>{},
       );

  PersistentOfflineTileProvider._({
    required this.offlineRoot,
    required this.layerKey,
    required this.legacyRoot,
    required TileFetchSlots slots,
    required http.Client httpClient,
    required bool ownsClient,
    super.headers,
  }) : _slots = slots,
       _httpClient = httpClient,
       _ownsClient = ownsClient;

  String offlineRoot;
  String layerKey;
  String? legacyRoot;
  final TileFetchSlots _slots;
  final http.Client _httpClient;
  final bool _ownsClient;

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
    if (offlineRoot.isNotEmpty) {
      final file = OfflineTileCacheService.persistedTileFile(
        offlineRoot: offlineRoot,
        legacyRoot: legacyRoot,
        layerKey: layerKey,
        z: coordinates.z,
        x: coordinates.x,
        y: coordinates.y,
      );
      if (file != null) return FileImage(file);
    }
    final destination = offlineRoot.isEmpty
        ? null
        : File(
            OfflineTileCacheService.tileFilePath(
              rootPath: offlineRoot,
              layerKey: layerKey,
              z: coordinates.z,
              x: coordinates.x,
              y: coordinates.y,
            ),
          );
    return PersistingTileImage(
      url: getTileUrl(coordinates, options),
      fallbackUrl: options.fallbackUrl == null
          ? null
          : getTileFallbackUrl(coordinates, options),
      headers: Map<String, String>.from(headers),
      destination: destination,
      client: _httpClient,
      slots: _slots,
    );
  }

  @override
  Future<void> dispose() async {
    if (_ownsClient) {
      _httpClient.close();
    }
    super.dispose();
  }
}

/// Baixa o tile uma vez, grava no disco e decodifica esses mesmos bytes.
class PersistingTileImage extends ImageProvider<PersistingTileImage> {
  PersistingTileImage({
    required this.url,
    required this.fallbackUrl,
    required this.headers,
    required this.destination,
    required this.client,
    required this.slots,
  });

  final String url;
  final String? fallbackUrl;
  final Map<String, String> headers;
  final File? destination;
  final http.Client client;
  final TileFetchSlots slots;

  @override
  Future<PersistingTileImage> obtainKey(ImageConfiguration configuration) {
    return SynchronousFuture<PersistingTileImage>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    PersistingTileImage key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1,
      debugLabel: url,
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    await slots.acquire();
    try {
      final bytes = await _read(url) ?? await _read(fallbackUrl);
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Tile vazio: $url');
      }
      final file = destination;
      if (file != null) {
        try {
          await OfflineTileCacheService.storeDownloadedTile(
            file: file,
            bytes: bytes,
          );
        } catch (_) {
          // A imagem desta sessão segue mesmo se o disco falhar.
        }
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        Uint8List.fromList(bytes),
      );
      return decode(buffer);
    } finally {
      slots.release();
    }
  }

  Future<List<int>?> _read(String? target) async {
    if (target == null || target.isEmpty) return null;
    try {
      final response = await client.get(Uri.parse(target), headers: headers);
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        return null;
      }
      return response.bodyBytes;
    } catch (_) {
      return null;
    }
  }

  @override
  bool operator ==(Object other) {
    return other is PersistingTileImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}
