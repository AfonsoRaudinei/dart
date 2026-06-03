import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:soloforte_app/modules/ndvi/data/processing/ndvi_green_mask_processor.dart';

enum NdviDisplayMode { color, greenMask }

final ndviDisplayModeProvider = StateProvider.family
    .autoDispose<NdviDisplayMode, String>((ref, key) => NdviDisplayMode.color);

final ndviGreenMaskBytesProvider = FutureProvider.family
    .autoDispose<Uint8List?, String>((ref, path) async {
      final colorFile = File(path);
      if (!await colorFile.exists()) return null;

      final maskFile = File(_greenMaskPathFor(path));
      final colorStat = await colorFile.stat();
      if (await maskFile.exists()) {
        final maskStat = await maskFile.stat();
        if (!maskStat.modified.isBefore(colorStat.modified)) {
          return maskFile.readAsBytes();
        }
      }

      final bytes = await colorFile.readAsBytes();
      final source = img.decodeImage(bytes);
      if (source == null) return null;

      final mask = applyNdviGreenMask(source);
      final maskBytes = Uint8List.fromList(img.encodePng(mask));
      await maskFile.writeAsBytes(maskBytes, flush: true);
      return maskBytes;
    });

String _greenMaskPathFor(String colorPath) {
  final dir = p.dirname(colorPath);
  final extension = p.extension(colorPath);
  final basename = p.basenameWithoutExtension(colorPath);
  final maskBase = basename.startsWith('ndvi_color_')
      ? basename.replaceFirst('ndvi_color_', 'ndvi_green_mask_')
      : '${basename}_green_mask';
  return p.join(dir, '$maskBase${extension.isEmpty ? '.png' : extension}');
}
