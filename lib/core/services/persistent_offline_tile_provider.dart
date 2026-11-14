import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';

import '../network/network_policy.dart';
import '../utils/map_logger.dart';
import 'offline_tile_cache_service.dart';

/// 401/403 do provedor de tiles: chave de API inválida, apagada ou sem cota.
bool tileStatusMeansKeyRejected(int status) => status == 401 || status == 403;

/// Limita quantos tiles saem ao mesmo tempo.
///
/// No rádio lento, dezenas de pedidos juntos deixam a tela branca até o
/// primeiro JPEG voltar. Os primeiros pedidos (o que está na tela) passam;
/// o restante espera vaga. Se o tile sai da tela enquanto espera, sai da fila
/// sem ocupar vaga.
class TileFetchSlots {
  TileFetchSlots({this.limit = 4});

  final int limit;
  int _used = 0;
  final List<Completer<bool>> _queue = [];

  /// `true` quando a vaga foi concedida. `false` quando [cancel] disparou
  /// antes disso — nesse caso nenhuma vaga foi ocupada.
  Future<bool> acquire({Future<void>? cancel}) {
    if (_used < limit) {
      _used++;
      return Future<bool>.value(true);
    }
    final waiter = Completer<bool>();
    _queue.add(waiter);
    cancel?.then((_) {
      if (waiter.isCompleted) return;
      _queue.remove(waiter);
      waiter.complete(false);
    });
    return waiter.future;
  }

  void release() {
    while (_queue.isNotEmpty) {
      final next = _queue.removeAt(0);
      if (!next.isCompleted) {
        next.complete(true);
        return;
      }
    }
    if (_used > 0) _used--;
  }
}

/// Primeira leitura, uma nova tentativa da mesma URL e, se ainda falhar, o
/// fallback. [NetworkPolicy.kMaxRetries] já conta a primeira ida.
///
/// Cancelado no meio não abre outro pedido.
Future<List<int>?> readTileWithRetry({
  required Future<List<int>?> Function(String url) read,
  required String url,
  required String? fallbackUrl,
  required bool Function() isCancelled,
  int maxAttempts = NetworkPolicy.kMaxRetries,
}) async {
  for (var attempt = 0; attempt < maxAttempts; attempt++) {
    if (isCancelled()) return null;
    final bytes = await read(url);
    if (isCancelled()) return null;
    if (bytes != null && bytes.isNotEmpty) return bytes;
  }
  if (isCancelled()) return null;
  if (fallbackUrl == null || fallbackUrl.isEmpty) return null;
  final fallback = await read(fallbackUrl);
  if (isCancelled() || fallback == null || fallback.isEmpty) return null;
  return fallback;
}

/// Serve o tile gravado em Documents/offline_tiles sempre que o arquivo existe.
/// O que falta vai à rede, com prazo e uma nova tentativa, e fica no disco da
/// conta. Nada aqui apaga arquivo.
class PersistentOfflineTileProvider extends TileProvider {
  PersistentOfflineTileProvider({
    required String offlineRoot,
    required String layerKey,
    String? legacyRoot,
    TileFetchSlots? slots,
    HttpClient? httpClient,
    Duration requestTimeout = NetworkPolicy.kTimeout,
    int maxAttempts = NetworkPolicy.kMaxRetries,
    Map<String, String>? headers,
    void Function(int status)? onNetworkStatus,
  }) : this._(
         offlineRoot: offlineRoot,
         layerKey: layerKey,
         legacyRoot: legacyRoot,
         slots: slots ?? TileFetchSlots(),
         httpClient: httpClient ?? HttpClient(),
         ownsClient: httpClient == null,
         requestTimeout: requestTimeout,
         maxAttempts: maxAttempts,
         headers: headers ?? <String, String>{},
         onNetworkStatus: onNetworkStatus,
       );

  PersistentOfflineTileProvider._({
    required this.offlineRoot,
    required this.layerKey,
    required this.legacyRoot,
    required TileFetchSlots slots,
    required HttpClient httpClient,
    required bool ownsClient,
    required this.requestTimeout,
    required this.maxAttempts,
    required this.onNetworkStatus,
    super.headers,
  }) : _slots = slots,
       _httpClient = httpClient,
       _ownsClient = ownsClient {
    _httpClient.connectionTimeout = requestTimeout;
  }

  String offlineRoot;
  String layerKey;
  String? legacyRoot;

  /// Recebe o status HTTP de cada resposta de tile (200, 401, 403…).
  ///
  /// Chave de API recusada devolve 403 com uma imagem de erro; sem este aviso
  /// o tile some em silêncio e o mapa fica branco.
  void Function(int status)? onNetworkStatus;
  final Duration requestTimeout;
  final int maxAttempts;
  final TileFetchSlots _slots;
  final HttpClient _httpClient;
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
  bool get supportsCancelLoading => true;

  @override
  ImageProvider getImage(TileCoordinates coordinates, TileLayer options) {
    return _resolve(coordinates, options, Completer<void>().future);
  }

  @override
  ImageProvider getImageWithCancelLoadingSupport(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
    return _resolve(coordinates, options, cancelLoading);
  }

  ImageProvider _resolve(
    TileCoordinates coordinates,
    TileLayer options,
    Future<void> cancelLoading,
  ) {
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
    final headers = Map<String, String>.from(this.headers);
    return PersistingTileImage(
      url: getTileUrl(coordinates, options),
      fallbackUrl: options.fallbackUrl == null
          ? null
          : getTileFallbackUrl(coordinates, options),
      destination: destination,
      slots: _slots,
      cancel: cancelLoading,
      maxAttempts: maxAttempts,
      read: (target, cancel) => fetchTileBody(
        uri: Uri.parse(target),
        headers: headers,
        cancel: cancel,
      ),
    );
  }

  /// Uma ida à rede. Estoura em [requestTimeout] e para se [cancel] completar.
  @visibleForTesting
  Future<List<int>?> fetchTileBody({
    required Uri uri,
    required Map<String, String> headers,
    required Future<void> cancel,
    Duration? timeout,
  }) async {
    final limit = timeout ?? requestTimeout;
    _httpClient.connectionTimeout = limit;
    late final HttpClientRequest request;
    try {
      request = await _httpClient.getUrl(uri).timeout(limit);
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } on HttpException {
      return null;
    }

    for (final entry in headers.entries) {
      request.headers.set(entry.key, entry.value);
    }

    var aborted = false;
    void abort() {
      if (aborted) return;
      aborted = true;
      try {
        request.abort();
      } catch (_) {}
    }

    final subscription = cancel.asStream().listen((_) => abort());
    try {
      final response = await request.close().timeout(
        limit,
        onTimeout: () {
          abort();
          throw TimeoutException('tile');
        },
      );
      if (!aborted) _reportStatus(uri, response.statusCode);
      if (aborted || response.statusCode != 200) {
        abort();
        try {
          await response.drain<void>().timeout(limit);
        } catch (_) {}
        return null;
      }
      final chunks = <int>[];
      await for (final chunk in response.timeout(
        limit,
        onTimeout: (sink) {
          abort();
          sink.close();
        },
      )) {
        if (aborted) return null;
        chunks.addAll(chunk);
      }
      if (aborted || chunks.isEmpty) return null;
      return chunks;
    } on TimeoutException {
      return null;
    } on SocketException {
      return null;
    } on HttpException {
      return null;
    } finally {
      await subscription.cancel();
    }
  }

  void _reportStatus(Uri uri, int status) {
    if (status != 200) {
      // Sem query: a URL do tile carrega a chave da API.
      MapLogger.logError('Tile HTTP $status em ${uri.host}${uri.path}', null);
    }
    onNetworkStatus?.call(status);
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _httpClient.close(force: true);
    }
    super.dispose();
  }
}

/// Baixa o tile, tenta de novo uma vez e decodifica sem esperar o disco.
class PersistingTileImage extends ImageProvider<PersistingTileImage> {
  PersistingTileImage({
    required this.url,
    required this.fallbackUrl,
    required this.destination,
    required this.slots,
    required this.cancel,
    required this.maxAttempts,
    required this.read,
  });

  final String url;
  final String? fallbackUrl;
  final File? destination;
  final TileFetchSlots slots;
  final Future<void> cancel;
  final int maxAttempts;
  final Future<List<int>?> Function(String url, Future<void> cancel) read;

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
    final gate = _TileCancel(cancel);
    final gotSlot = await slots.acquire(cancel: cancel);
    if (!gotSlot) {
      _dropCache();
      return _transparent(decode);
    }
    try {
      await Future<void>.value();
      if (gate.cancelled) {
        _dropCache();
        return _transparent(decode);
      }
      final bytes = await readTileWithRetry(
        read: (target) => read(target, cancel),
        url: url,
        fallbackUrl: fallbackUrl,
        isCancelled: () => gate.cancelled,
        maxAttempts: maxAttempts,
      );
      if (gate.cancelled) {
        _dropCache();
        return _transparent(decode);
      }
      if (bytes == null || bytes.isEmpty) {
        throw StateError('Tile vazio: $url');
      }
      final buffer = await ui.ImmutableBuffer.fromUint8List(
        Uint8List.fromList(bytes),
      );
      final codec = await decode(buffer);
      if (gate.cancelled) {
        _dropCache();
        return _transparent(decode);
      }
      final file = destination;
      if (file != null) {
        unawaited(
          OfflineTileCacheService.storeDownloadedTile(
            file: file,
            bytes: bytes,
          ).then<void>((_) {}, onError: (Object _, StackTrace _) {}),
        );
      }
      return codec;
    } catch (_) {
      _dropCache();
      rethrow;
    } finally {
      slots.release();
    }
  }

  Future<ui.Codec> _transparent(ImageDecoderCallback decode) async {
    final buffer = await ui.ImmutableBuffer.fromUint8List(
      TileProvider.transparentImage,
    );
    return decode(buffer);
  }

  void _dropCache() {
    scheduleMicrotask(() {
      PaintingBinding.instance.imageCache.evict(this);
    });
  }

  @override
  bool operator ==(Object other) {
    return other is PersistingTileImage && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}

class _TileCancel {
  _TileCancel(Future<void> signal) {
    signal.then((_) => cancelled = true);
  }

  bool cancelled = false;
}
