import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/report_export_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('report_export_test_');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, (call) async {
          if (call.method == 'getTemporaryDirectory') return tempDir.path;
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('gera nome seguro para arquivo HTML', () async {
    const service = ReportExportService();

    final file = await service.writeTempFile(
      baseName: 'Relatório: Visita / Fazenda São José',
      extension: 'html',
      content: '<html><body>ok</body></html>',
    );

    expect(file.path, endsWith('relat_rio_visita_fazenda_s_o_jos.html'));
    expect(await file.readAsString(), contains('<body>ok</body>'));
  });

  test('safeFileBaseName remove caracteres inseguros', () {
    expect(
      ReportExportService.safeFileBaseName('  Ocorrência #42 / CSV  '),
      'ocorr_ncia_42_csv',
    );
    expect(ReportExportService.safeFileBaseName('///'), 'relatorio');
  });
}
