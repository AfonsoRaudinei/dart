import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/report_export_service.dart';

import 'pptx_package_integrity.dart';

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
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/images/soloforte_logo.png') {
            return const StandardMessageCodec().encodeMessage(
              Uint8List.fromList([
                0x89,
                0x50,
                0x4E,
                0x47,
                0x0D,
                0x0A,
                0x1A,
                0x0A,
              ]),
            );
          }
          return null;
        });
  });

  tearDown(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(pathProviderChannel, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
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

  test('exportPack grava HTML CSV e JSON no diretório temporário', () async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final shared = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          shared.add(call);
          return null;
        });

    const service = ReportExportService();
    await service.exportPack(
      const ReportExportPayload(
        title: 'Pack Teste',
        html: '<html></html>',
        fileBaseName: 'pack_teste',
        json: {'ok': true},
        csv: 'a,b\n1,2',
      ),
    );

    expect(File('${tempDir.path}/pack_teste.html').existsSync(), isTrue);
    expect(File('${tempDir.path}/pack_teste.csv').existsSync(), isTrue);
    expect(File('${tempDir.path}/pack_teste.json').existsSync(), isTrue);
    expect(shared, isNotEmpty);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('exportPptx grava pptx não vazio e compartilha', () async {
    const channel = MethodChannel('dev.fluttercommunity.plus/share');
    final shared = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          shared.add(call);
          return null;
        });

    const html = '''
<html><body>
<header class="sf-letterhead"><h1 class="sf-title">Visita</h1></header>
<main><p>Conteúdo</p></main>
</body></html>
''';

    const service = ReportExportService();
    final result = await service.exportPptx(
      const ReportExportPayload(
        title: 'Visita campo',
        html: html,
        fileBaseName: 'visita_campo',
      ),
    );

    expect(result.format, ReportExportFormat.pptx);
    expect(result.path, isNotNull);
    final file = File(result.path!);
    expect(file.path, endsWith('visita_campo.pptx'));
    final bytes = await file.readAsBytes();
    expect(bytes.length, greaterThan(500));
    assertPptxPackageIntegrity(ZipDecoder().decodeBytes(bytes));
    expect(shared, isNotEmpty);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
}
