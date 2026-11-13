import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/painting.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/services/persistent_offline_tile_provider.dart';

import '../../support/path_provider_test_bindings.dart';

void main() {
  const service = OfflineTileCacheService();

  group('OfflineTileCacheService.estimateTileCount', () {
    test('calcula um tile para bbox contido no zoom zero', () {
      final total = service.estimateTileCount(
        south: -10,
        west: -50,
        north: -9,
        east: -49,
        minZoom: 0,
        maxZoom: 0,
      );

      expect(total, 1);
    });

    test('rejeita intervalo de zoom invertido', () {
      expect(
        () => service.estimateTileCount(
          south: -10,
          west: -50,
          north: -9,
          east: -49,
          minZoom: 18,
          maxZoom: 12,
        ),
        throwsA(isA<OfflineTileCacheException>()),
      );
    });

    test('rejeita latitude fora do Web Mercator', () {
      expect(
        () => service.estimateTileCount(
          south: -90,
          west: -50,
          north: -9,
          east: -49,
          minZoom: 12,
          maxZoom: 12,
        ),
        throwsA(isA<OfflineTileCacheException>()),
      );
    });
  });

  group('OfflineTileCacheService.scopedUserId', () {
    test('usuários distintos gravam em pastas separadas', () async {
      installPathProviderTestBindings();
      const consultant = OfflineTileCacheService(scopedUserId: 'user-a');
      const producer = OfflineTileCacheService(scopedUserId: 'user-b');

      final consultantRoot = await consultant.rootPath();
      final producerRoot = await producer.rootPath();

      expect(consultantRoot, isNot(producerRoot));
      expect(consultantRoot, contains('/offline_tiles/users/user-a'));
      expect(producerRoot, contains('/offline_tiles/users/user-b'));
    });

    test('scopedUserId vazio mantém pasta legada offline_tiles', () async {
      installPathProviderTestBindings();
      const legacy = OfflineTileCacheService();
      final root = await legacy.rootPath();
      expect(root, endsWith('/offline_tiles'));
      expect(root, isNot(contains('/users/')));
    });
  });

  group('OfflineTileCacheService.prefetchArea concurrency', () {
    test('baixa tiles em paralelo até prefetchConcurrency', () async {
      installPathProviderTestBindings();
      var inFlight = 0;
      var maxInFlight = 0;

      Future<http.Response> fakeGet(
        http.Client client,
        Uri uri,
        Map<String, String> headers,
      ) async {
        inFlight++;
        maxInFlight = math.max(maxInFlight, inFlight);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        inFlight--;
        return http.Response.bytes(const [1, 2, 3], 200);
      }

      const south = -10.0;
      const west = -50.0;
      const north = -9.0;
      const east = -47.0;
      const zoom = 9;

      final total = service.estimateTileCount(
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
      );
      expect(total, greaterThan(OfflineTileCacheService.prefetchConcurrency));

      final result = await service.prefetchArea(
        layerKey: 'test-concurrency',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        forceRefresh: true,
        tileHttpGet: fakeGet,
      );

      expect(result.isComplete, isTrue);
      expect(maxInFlight, greaterThan(1));
      expect(
        maxInFlight,
        lessThanOrEqualTo(OfflineTileCacheService.prefetchConcurrency),
      );
    });
  });

  group('OfflineTileCacheService.prefetchArea resume', () {
    const south = -10.0;
    const west = -50.0;
    const north = -9.9;
    const east = -49.9;
    const zoom = 0;

    test('GET que nunca completa respeita timeout e não trava', () async {
      installPathProviderTestBindings();
      final started = DateTime.now();
      final result = await service.prefetchArea(
        layerKey: 'test-timeout-${started.microsecondsSinceEpoch}',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        forceRefresh: true,
        requestTimeout: const Duration(milliseconds: 40),
        pausePoll: const Duration(milliseconds: 5),
        tileHttpGet: (client, uri, headers) =>
            Completer<http.Response>().future,
      );

      expect(DateTime.now().difference(started).inSeconds, lessThan(3));
      expect(result.cancelled, isFalse);
      expect(result.failed, result.total);
      expect(result.isComplete, isFalse);
    });

    test('segundo prefetch pula tiles já gravados no disco', () async {
      installPathProviderTestBindings();
      final layerKey = 'test-skip-${DateTime.now().microsecondsSinceEpoch}';

      Future<http.Response> okGet(
        http.Client client,
        Uri uri,
        Map<String, String> headers,
      ) async {
        return http.Response.bytes(const [1, 2, 3], 200);
      }

      final first = await service.prefetchArea(
        layerKey: layerKey,
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        tileHttpGet: okGet,
      );
      expect(first.isComplete, isTrue);
      expect(first.downloaded, first.total);

      final second = await service.prefetchArea(
        layerKey: layerKey,
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        tileHttpGet: okGet,
      );
      expect(second.isComplete, isTrue);
      expect(second.skipped, second.total);
      expect(second.downloaded, 0);
      expect(second.failed, 0);
    });

    test('shouldPause não incrementa failed e retoma depois', () async {
      installPathProviderTestBindings();
      var paused = false;
      var downloads = 0;
      final pauseHit = Completer<void>();

      Future<http.Response> okGet(
        http.Client client,
        Uri uri,
        Map<String, String> headers,
      ) async {
        downloads++;
        if (downloads == 1 && !pauseHit.isCompleted) {
          paused = true;
          pauseHit.complete();
        }
        return http.Response.bytes(const [1, 2, 3], 200);
      }

      final future = service.prefetchArea(
        layerKey: 'test-pause-${DateTime.now().microsecondsSinceEpoch}',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: -10,
        west: -50,
        north: -9,
        east: -47,
        minZoom: 8,
        maxZoom: 8,
        forceRefresh: true,
        pausePoll: const Duration(milliseconds: 5),
        shouldPause: () => paused,
        tileHttpGet: okGet,
      );

      await pauseHit.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      paused = false;
      final result = await future;

      expect(result.failed, 0);
      expect(result.isComplete, isTrue);
      expect(result.cancelled, isFalse);
    });

    test('falha HTTP com pause logo depois não conta failed', () async {
      installPathProviderTestBindings();
      var paused = false;
      var calls = 0;

      Future<http.Response> flakyGet(
        http.Client client,
        Uri uri,
        Map<String, String> headers,
      ) async {
        calls++;
        if (calls == 1) {
          Future<void>.delayed(const Duration(milliseconds: 30), () {
            paused = true;
          });
          throw Exception('socket');
        }
        return http.Response.bytes(const [1, 2, 3], 200);
      }

      final future = service.prefetchArea(
        layerKey: 'test-fail-grace-${DateTime.now().microsecondsSinceEpoch}',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        forceRefresh: true,
        pausePoll: const Duration(milliseconds: 20),
        shouldPause: () => paused,
        tileHttpGet: flakyGet,
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));
      paused = false;
      final result = await future;
      expect(result.failed, 0);
      expect(result.isComplete, isTrue);
    });
  });

  group('OfflineTileCacheService.deleteTilesInRange', () {
    test(
      'exclusão manual apaga o tile e a área vizinha conserva o compartilhado',
      () async {
        installPathProviderTestBindings();
        const layer = 'persist-delete';
        final file = await service.tileFile(layerKey: layer, z: 0, x: 0, y: 0);
        await file.writeAsBytes(const [9]);

        final kept = await service.deleteTilesInRange(
          layerKey: layer,
          south: -10,
          west: -50,
          north: -9,
          east: -49,
          minZoom: 0,
          maxZoom: 0,
          keep: const [
            OfflineTileKeepRegion(
              layerKey: layer,
              south: -20,
              west: -40,
              north: -15,
              east: -30,
              minZoom: 0,
              maxZoom: 0,
            ),
          ],
        );
        expect(kept, 0);
        expect(file.existsSync(), isTrue);

        final removed = await service.deleteTilesInRange(
          layerKey: layer,
          south: -10,
          west: -50,
          north: -9,
          east: -49,
          minZoom: 0,
          maxZoom: 0,
        );
        expect(removed, 1);
        expect(file.existsSync(), isFalse);
      },
    );
  });

  group('OfflineTileCacheService.persistedTileFile', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('tile_readthrough');
    });

    tearDown(() async {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('pasta do usuário vazia serve o tile da pasta antiga', () {
      final legacyRoot = Directory('${tempDir.path}/offline_tiles')
        ..createSync(recursive: true);
      final userRoot = Directory('${tempDir.path}/offline_tiles/users/user-a')
        ..createSync(recursive: true);
      const layer = 'layer-sat';
      final legacyFile = File(
        OfflineTileCacheService.tileFilePath(
          rootPath: legacyRoot.path,
          layerKey: layer,
          z: 12,
          x: 1500,
          y: 2300,
        ),
      );
      legacyFile.parent.createSync(recursive: true);
      legacyFile.writeAsBytesSync(const [1, 2, 3, 4]);

      expect(
        OfflineTileCacheService.legacyRootBeside(userRoot.path),
        legacyRoot.path,
      );

      final resolved = OfflineTileCacheService.persistedTileFile(
        offlineRoot: userRoot.path,
        legacyRoot: OfflineTileCacheService.legacyRootBeside(userRoot.path),
        layerKey: layer,
        z: 12,
        x: 1500,
        y: 2300,
      );

      expect(resolved?.path, legacyFile.path);
      expect(legacyFile.existsSync(), isTrue);
    });

    test('arquivo do usuário vence a pasta antiga', () {
      final legacyRoot = Directory('${tempDir.path}/offline_tiles')
        ..createSync(recursive: true);
      final userRoot = Directory('${tempDir.path}/offline_tiles/users/user-a')
        ..createSync(recursive: true);
      const layer = 'layer-sat';
      final legacyFile = File(
        OfflineTileCacheService.tileFilePath(
          rootPath: legacyRoot.path,
          layerKey: layer,
          z: 12,
          x: 1,
          y: 2,
        ),
      );
      final userFile = File(
        OfflineTileCacheService.tileFilePath(
          rootPath: userRoot.path,
          layerKey: layer,
          z: 12,
          x: 1,
          y: 2,
        ),
      );
      legacyFile.parent.createSync(recursive: true);
      userFile.parent.createSync(recursive: true);
      legacyFile.writeAsBytesSync(const [1]);
      userFile.writeAsBytesSync(const [9]);

      final resolved = OfflineTileCacheService.persistedTileFile(
        offlineRoot: userRoot.path,
        legacyRoot: legacyRoot.path,
        layerKey: layer,
        z: 12,
        x: 1,
        y: 2,
      );

      expect(resolved?.path, userFile.path);
    });

    test('pasta sem usuário não aponta legado', () {
      expect(
        OfflineTileCacheService.legacyRootBeside(
          '${tempDir.path}/offline_tiles',
        ),
        isNull,
      );
    });

    test(
      'bytes baixados ficam no disco e a leitura seguinte acha o arquivo',
      () async {
        const layer = 'layer-sat';
        final file = File(
          OfflineTileCacheService.tileFilePath(
            rootPath: tempDir.path,
            layerKey: layer,
            z: 14,
            x: 8,
            y: 9,
          ),
        );

        expect(
          await OfflineTileCacheService.storeDownloadedTile(
            file: file,
            bytes: const [],
          ),
          isFalse,
        );
        expect(file.existsSync(), isFalse);

        expect(
          await OfflineTileCacheService.storeDownloadedTile(
            file: file,
            bytes: const [9, 8, 7],
          ),
          isTrue,
        );

        final resolved = OfflineTileCacheService.persistedTileFile(
          offlineRoot: tempDir.path,
          legacyRoot: null,
          layerKey: layer,
          z: 14,
          x: 8,
          y: 9,
        );
        expect(resolved?.path, file.path);
      },
    );
  });

  test('TileFetchSlots segura o pedido que passa do limite', () async {
    final slots = TileFetchSlots(limit: 1);
    await slots.acquire();
    var entered = false;
    final waiting = slots.acquire().then((_) {
      entered = true;
    });
    await Future<void>.delayed(Duration.zero);
    expect(entered, isFalse);
    slots.release();
    await waiting;
    expect(entered, isTrue);
    slots.release();
  });

  test('tile já gravado volta como arquivo, sem ir à rede', () async {
    final root = await Directory.systemTemp.createTemp('tile_provider_hit');
    addTearDown(() async {
      if (root.existsSync()) root.deleteSync(recursive: true);
    });
    const layer = 'layer-sat';
    final file = File(
      OfflineTileCacheService.tileFilePath(
        rootPath: root.path,
        layerKey: layer,
        z: 13,
        x: 4,
        y: 5,
      ),
    );
    await OfflineTileCacheService.storeDownloadedTile(
      file: file,
      bytes: const [1, 2, 3, 4],
    );
    final provider = PersistentOfflineTileProvider(
      offlineRoot: root.path,
      layerKey: layer,
    );
    addTearDown(provider.dispose);

    final image = provider.getImage(
      const TileCoordinates(4, 5, 13),
      TileLayer(urlTemplate: 'https://tiles.example/{z}/{x}/{y}.jpg'),
    );

    expect(image, isA<FileImage>());
    expect((image as FileImage).file.path, file.path);
  });

  test('TileFetchSlots tira da fila o tile que saiu da tela', () async {
    final slots = TileFetchSlots(limit: 1);
    expect(await slots.acquire(), isTrue);
    final cancel = Completer<void>();
    final waiting = slots.acquire(cancel: cancel.future);
    cancel.complete();
    expect(await waiting, isFalse);

    var entered = false;
    final next = slots.acquire().then((got) {
      entered = got;
    });
    await Future<void>.delayed(Duration.zero);
    expect(entered, isFalse);
    slots.release();
    await next;
    expect(entered, isTrue);
    slots.release();
  });

  test(
    'readTileWithRetry tenta a mesma URL de novo e depois o fallback',
    () async {
      final calls = <String>[];
      final bytes = await readTileWithRetry(
        read: (url) async {
          calls.add(url);
          if (url == 'fallback') return [9];
          return null;
        },
        url: 'primary',
        fallbackUrl: 'fallback',
        isCancelled: () => false,
        maxAttempts: 2,
      );
      expect(calls, ['primary', 'primary', 'fallback']);
      expect(bytes, [9]);
    },
  );

  test('readTileWithRetry a segunda tentativa da mesma URL vale', () async {
    var calls = 0;
    final bytes = await readTileWithRetry(
      read: (_) async {
        calls++;
        return calls == 1 ? null : [1, 2];
      },
      url: 'primary',
      fallbackUrl: 'fallback',
      isCancelled: () => false,
      maxAttempts: 2,
    );
    expect(calls, 2);
    expect(bytes, [1, 2]);
  });

  test('readTileWithRetry cancelado não abre outra tentativa', () async {
    var calls = 0;
    var cancelled = false;
    final bytes = await readTileWithRetry(
      read: (_) async {
        calls++;
        cancelled = true;
        return null;
      },
      url: 'primary',
      fallbackUrl: 'fallback',
      isCancelled: () => cancelled,
      maxAttempts: 2,
    );
    expect(calls, 1);
    expect(bytes, isNull);
  });

  test('fetchTileBody devolve o corpo 200 e ignora status vazio', () async {
    await _withRealHttpClient(() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      server.listen((request) async {
        final path = request.uri.path;
        if (path.endsWith('/ok.jpg')) {
          request.response.statusCode = 200;
          request.response.add([7, 8, 9]);
        } else {
          request.response.statusCode = 500;
        }
        await request.response.close();
      });
      final provider = PersistentOfflineTileProvider(
        offlineRoot: '/tmp/unused-tile-root',
        layerKey: 'layer',
        requestTimeout: const Duration(seconds: 2),
      );
      addTearDown(provider.dispose);

      final ok = await provider.fetchTileBody(
        uri: Uri.parse('http://127.0.0.1:${server.port}/ok.jpg'),
        headers: const {},
        cancel: Completer<void>().future,
      );
      final failed = await provider.fetchTileBody(
        uri: Uri.parse('http://127.0.0.1:${server.port}/fail.jpg'),
        headers: const {},
        cancel: Completer<void>().future,
      );
      expect(ok, [7, 8, 9]);
      expect(failed, isNull);
    });
  });

  test(
    'fetchTileBody estoura no prazo quando o servidor não responde',
    () async {
      await _withRealHttpClient(() async {
        final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
        addTearDown(() => server.close(force: true));
        server.listen((_) {});
        final provider = PersistentOfflineTileProvider(
          offlineRoot: '/tmp/unused-tile-root',
          layerKey: 'layer',
          requestTimeout: const Duration(milliseconds: 200),
        );
        addTearDown(provider.dispose);

        final elapsed = Stopwatch()..start();
        final bytes = await provider.fetchTileBody(
          uri: Uri.parse('http://127.0.0.1:${server.port}/hang.jpg'),
          headers: const {},
          cancel: Completer<void>().future,
        );
        elapsed.stop();
        expect(bytes, isNull);
        expect(elapsed.elapsed, lessThan(const Duration(seconds: 3)));
      });
    },
  );

  test('fetchTileBody para quando o tile sai da tela', () async {
    await _withRealHttpClient(() async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final gotRequest = Completer<void>();
      server.listen((_) {
        if (!gotRequest.isCompleted) gotRequest.complete();
      });
      final provider = PersistentOfflineTileProvider(
        offlineRoot: '/tmp/unused-tile-root',
        layerKey: 'layer',
        requestTimeout: const Duration(seconds: 15),
      );
      addTearDown(provider.dispose);
      final cancel = Completer<void>();
      final pending = provider.fetchTileBody(
        uri: Uri.parse('http://127.0.0.1:${server.port}/hang.jpg'),
        headers: const {},
        cancel: cancel.future,
      );
      await gotRequest.future.timeout(const Duration(seconds: 2));
      final elapsed = Stopwatch()..start();
      cancel.complete();
      final bytes = await pending;
      elapsed.stop();
      expect(bytes, isNull);
      expect(elapsed.elapsed, lessThan(const Duration(seconds: 2)));
    });
  });
}

/// O binding de teste troca o HttpClient por um que responde 400 sem rede.
/// `super.createHttpClient` devolve o cliente real, sem voltar ao mock.
Future<T> _withRealHttpClient<T>(Future<T> Function() body) {
  return HttpOverrides.runZoned(
    body,
    createHttpClient: _DirectHttpOverrides().createHttpClient,
  );
}

class _DirectHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context);
  }
}
