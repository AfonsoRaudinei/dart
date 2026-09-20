import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:soloforte_app/core/utils/local_media_path_resolver.dart';
import 'package:soloforte_app/modules/consultoria/relatorio_visita/data/image_storage_service.dart';

class _FakePathProvider extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  _FakePathProvider(this.documentsPath);

  final String documentsPath;

  @override
  Future<String?> getApplicationDocumentsPath() async => documentsPath;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ImageStorageService.persistLocalCopy', () {
    late Directory docsDir;

    setUp(() async {
      docsDir = await Directory.systemTemp.createTemp('occ_docs_');
      PathProviderPlatform.instance = _FakePathProvider(docsDir.path);
    });

    tearDown(() async {
      if (await docsDir.exists()) await docsDir.delete(recursive: true);
    });

    test('copia arquivo temporário para documents/media com path relativo', () async {
      final tmpDir = await Directory.systemTemp.createTemp('occ_photo_');
      addTearDown(() async {
        if (await tmpDir.exists()) await tmpDir.delete(recursive: true);
      });

      final tmpFile = File(p.join(tmpDir.path, 'picker_temp.jpg'));
      await tmpFile.writeAsBytes(List<int>.filled(64, 7));

      final persisted = await ImageStorageService().persistLocalCopy(
        tmpFile.path,
      );
      expect(persisted, isNotNull);
      expect(persisted, startsWith('media/'));

      final resolved = await ImageStorageService().resolveLocalPath(persisted!);
      expect(resolved, isNotNull);
      expect(File(resolved!).existsSync(), isTrue);
      expect(await File(resolved!).readAsBytes(), List<int>.filled(64, 7));
    });

    test('retorna null quando origem não existe', () async {
      final persisted = await ImageStorageService().persistLocalCopy(
        '/tmp/soloforte_does_not_exist_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      expect(persisted, isNull);
    });
  });

  group('LocalMediaPathResolver', () {
    late Directory docsDir;

    setUp(() async {
      docsDir = await Directory.systemTemp.createTemp('occ_docs_resolver_');
      PathProviderPlatform.instance = _FakePathProvider(docsDir.path);
    });

    tearDown(() async {
      if (await docsDir.exists()) await docsDir.delete(recursive: true);
    });

    test('resolve path relativo armazenado no SQLite', () async {
      final mediaDir = Directory(p.join(docsDir.path, 'media'));
      await mediaDir.create(recursive: true);
      final file = File(p.join(mediaDir.path, 'img_test.jpg'));
      await file.writeAsBytes([1, 2, 3]);

      final resolved =
          await LocalMediaPathResolver.resolveLocalPath('media/img_test.jpg');
      expect(resolved, file.path);
    });

    test('resolve path absoluto legado quando arquivo existe', () async {
      final mediaDir = Directory(p.join(docsDir.path, 'media'));
      await mediaDir.create(recursive: true);
      final file = File(p.join(mediaDir.path, 'legacy.jpg'));
      await file.writeAsBytes([4, 5, 6]);

      final resolved = await LocalMediaPathResolver.resolveLocalPath(file.path);
      expect(resolved, file.path);
    });

    test('toStoredPath normaliza absoluto para relativo', () {
      final absolute = p.join(docsDir.path, 'media', 'img_uuid.jpg');
      expect(
        LocalMediaPathResolver.toStoredPath(absolute),
        'media/img_uuid.jpg',
      );
    });

    test('remapeia path absoluto stale para media no container atual', () async {
      final mediaDir = Directory(p.join(docsDir.path, 'media'));
      await mediaDir.create(recursive: true);
      final file = File(p.join(mediaDir.path, 'legacy_stale.jpg'));
      await file.writeAsBytes([7, 8, 9]);

      final staleAbsolute = p.join(
        '/var/mobile/Containers/Data/Application/OLD-UUID/Documents',
        'media',
        'legacy_stale.jpg',
      );

      final resolved =
          await LocalMediaPathResolver.resolveLocalPath(staleAbsolute);
      expect(resolved, file.path);
    });
  });
}
