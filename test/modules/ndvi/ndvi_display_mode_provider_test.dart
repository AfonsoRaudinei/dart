import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_display_mode_provider.dart';

void main() {
  test(
    'ndviGreenMaskBytesProvider gera mascara a partir do PNG local',
    () async {
      final tempDir = await Directory.systemTemp.createTemp(
        'ndvi_mask_provider_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });

      final source = img.Image(width: 2, height: 1)
        ..setPixelRgb(0, 0, 0, 180, 0)
        ..setPixelRgb(1, 0, 255, 0, 0);
      final file = File('${tempDir.path}/ndvi_color_talhao-01_2026-06-01.png');
      await file.writeAsBytes(img.encodePng(source));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final bytes = await container.read(
        ndviGreenMaskBytesProvider(file.path).future,
      );
      final mask = img.decodePng(bytes!);
      final maskFile = File(
        '${tempDir.path}/ndvi_green_mask_talhao-01_2026-06-01.png',
      );

      expect(mask, isNotNull);
      expect(await maskFile.exists(), isTrue);
      expect(mask!.getPixel(0, 0).r.toInt(), 255);
      expect(mask.getPixel(1, 0).r.toInt(), 0);
    },
  );

  test('ndviGreenMaskBytesProvider reutiliza cache vigente', () async {
    final tempDir = await Directory.systemTemp.createTemp('ndvi_mask_cache_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final source = img.Image(width: 1, height: 1)..setPixelRgb(0, 0, 0, 180, 0);
    final file = File('${tempDir.path}/ndvi_color_talhao-01_2026-06-01.png');
    await file.writeAsBytes(img.encodePng(source));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(ndviGreenMaskBytesProvider(file.path).future);
    final maskFile = File(
      '${tempDir.path}/ndvi_green_mask_talhao-01_2026-06-01.png',
    );
    final firstModified = (await maskFile.stat()).modified;

    container.invalidate(ndviGreenMaskBytesProvider(file.path));
    await container.read(ndviGreenMaskBytesProvider(file.path).future);
    final secondModified = (await maskFile.stat()).modified;

    expect(secondModified, firstModified);
  });

  test('ndviGreenMaskBytesProvider regenera cache se original mudar', () async {
    final tempDir = await Directory.systemTemp.createTemp('ndvi_mask_regen_');
    addTearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    final firstSource = img.Image(width: 1, height: 1)
      ..setPixelRgb(0, 0, 0, 180, 0);
    final file = File('${tempDir.path}/ndvi_color_talhao-01_2026-06-01.png');
    await file.writeAsBytes(img.encodePng(firstSource));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(ndviGreenMaskBytesProvider(file.path).future);

    final secondSource = img.Image(width: 1, height: 1)
      ..setPixelRgb(0, 0, 255, 0, 0);
    await file.writeAsBytes(img.encodePng(secondSource), flush: true);
    await file.setLastModified(DateTime.now().add(const Duration(seconds: 2)));

    container.invalidate(ndviGreenMaskBytesProvider(file.path));
    final bytes = await container.read(
      ndviGreenMaskBytesProvider(file.path).future,
    );
    final mask = img.decodePng(bytes!);

    expect(mask, isNotNull);
    expect(mask!.getPixel(0, 0).r.toInt(), 0);
  });
}
