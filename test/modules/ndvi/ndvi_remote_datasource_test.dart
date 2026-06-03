import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  late Directory tempDir;
  late NdviRemoteDatasource datasource;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('ndvi_remote_test_');
    datasource = NdviRemoteDatasource(
      SupabaseClient('https://example.supabase.co', 'anon-key'),
      fileStore: NdviImageFileStore(directoryProvider: () async => tempDir),
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('image_base64 retornado pela Edge Function vira localPath', () async {
    final pngBytes = <int>[137, 80, 78, 71, 13, 10, 26, 10];

    final model = await datasource.modelFromFunctionData(
      fieldId: 'talhao:01',
      data: {
        'date': '2026-06-01',
        'source': 'sentinel',
        'image_base64': base64Encode(pngBytes),
      },
    );

    expect(model.imageUrl, isNull);
    expect(model.localPath, isNotNull);

    final savedFile = File(model.localPath!);
    expect(await savedFile.exists(), isTrue);
    expect(await savedFile.readAsBytes(), pngBytes);
    expect(savedFile.path, contains('ndvi_color_talhao-01_2026-06-01.png'));
  });

  test(
    'image_url continua como fallback quando image_base64 não vem',
    () async {
      final model = await datasource.modelFromFunctionData(
        fieldId: 'talhao-01',
        data: {
          'date': '2026-06-01',
          'source': 'planet',
          'image_url': 'https://cdn.example.com/ndvi.png',
        },
      );

      expect(model.localPath, isNull);
      expect(model.imageUrl, 'https://cdn.example.com/ndvi.png');
    },
  );

  test('imagem colorida original e preservada ao salvar localPath', () async {
    final colored = img.Image(width: 3, height: 1)
      ..setPixelRgb(0, 0, 255, 0, 0)
      ..setPixelRgb(1, 0, 255, 255, 0)
      ..setPixelRgb(2, 0, 0, 180, 0);

    final model = await datasource.modelFromFunctionData(
      fieldId: 'talhao-01',
      data: {
        'date': '2026-06-01',
        'source': 'sentinel',
        'image_base64': base64Encode(img.encodePng(colored)),
      },
    );

    final saved = img.decodePng(await File(model.localPath!).readAsBytes());
    expect(saved, isNotNull);
    expect(saved!.getPixel(0, 0).r.toInt(), 255);
    expect(saved.getPixel(0, 0).g.toInt(), 0);
    expect(saved.getPixel(1, 0).r.toInt(), 255);
    expect(saved.getPixel(1, 0).g.toInt(), 255);
    expect(saved.getPixel(2, 0).r.toInt(), 0);
    expect(saved.getPixel(2, 0).g.toInt(), 180);
  });
}
