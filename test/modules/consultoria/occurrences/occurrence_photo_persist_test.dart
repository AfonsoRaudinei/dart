import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
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

    test('copia arquivo temporário para documents/media', () async {
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
      expect(persisted, contains('${p.separator}media${p.separator}'));
      expect(File(persisted!).existsSync(), isTrue);
      expect(await File(persisted).readAsBytes(), List<int>.filled(64, 7));
    });

    test('retorna null quando origem não existe', () async {
      final persisted = await ImageStorageService().persistLocalCopy(
        '/tmp/soloforte_does_not_exist_${DateTime.now().microsecondsSinceEpoch}.jpg',
      );
      expect(persisted, isNull);
    });
  });
}
