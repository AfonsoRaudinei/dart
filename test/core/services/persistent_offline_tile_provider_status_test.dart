import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/persistent_offline_tile_provider.dart';

void main() {
  group('tileStatusMeansKeyRejected', () {
    test('401 e 403 indicam chave recusada', () {
      expect(tileStatusMeansKeyRejected(401), isTrue);
      expect(tileStatusMeansKeyRejected(403), isTrue);
    });

    test('200, 404 e 5xx não dizem nada sobre a chave', () {
      expect(tileStatusMeansKeyRejected(200), isFalse);
      expect(tileStatusMeansKeyRejected(404), isFalse);
      expect(tileStatusMeansKeyRejected(503), isFalse);
    });
  });

  group('PersistentOfflineTileProvider.onNetworkStatus', () {
    late HttpServer server;
    late int nextStatus;
    late PersistentOfflineTileProvider provider;
    late List<int> seen;

    setUp(() async {
      nextStatus = 200;
      seen = [];
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      server.listen((request) {
        request.response.statusCode = nextStatus;
        request.response.add(const [1, 2, 3]);
        request.response.close();
      });
      provider = PersistentOfflineTileProvider(
        offlineRoot: Directory.systemTemp.path,
        layerKey: 'teste',
      )..onNetworkStatus = seen.add;
    });

    tearDown(() async {
      provider.dispose();
      await server.close(force: true);
    });

    Future<List<int>?> fetch() => provider.fetchTileBody(
      uri: Uri.parse(
        'http://${server.address.host}:${server.port}/12/1/2.jpg?key=segredo',
      ),
      headers: const {},
      cancel: Completer<void>().future,
    );

    test('403 devolve null e avisa o status', () async {
      nextStatus = 403;
      expect(await fetch(), isNull);
      expect(seen, [403]);
    });

    test('200 devolve os bytes e avisa 200', () async {
      expect(await fetch(), [1, 2, 3]);
      expect(seen, [200]);
    });
  });
}
