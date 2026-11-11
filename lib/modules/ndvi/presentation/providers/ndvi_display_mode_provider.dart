import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:soloforte_app/modules/ndvi/data/processing/ndvi_green_mask_processor.dart';

enum NdviDisplayMode { color, greenMask }

/// Parâmetro da família: caminho do PNG colorido + modo refinado (Ouro).
typedef NdviGreenMaskRequest = ({String path, bool refined});

final ndviDisplayModeProvider = StateProvider.family
    .autoDispose<NdviDisplayMode, String>((ref, key) => NdviDisplayMode.color);

final ndviGreenMaskBytesProvider = FutureProvider.family
    .autoDispose<Uint8List?, NdviGreenMaskRequest>((ref, request) async {
      final path = request.path;
      final refined = request.refined;
      final colorFile = File(path);
      if (!await colorFile.exists()) return null;

      final maskFile = File(_greenMaskPathFor(path, refined: refined));
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

      final mask = applyNdviGreenMask(source, refined: refined);
      final maskBytes = Uint8List.fromList(img.encodePng(mask));
      await maskFile.writeAsBytes(maskBytes, flush: true);
      return maskBytes;
    });

String _greenMaskPathFor(String colorPath, {bool refined = false}) {
  final dir = p.dirname(colorPath);
  final extension = p.extension(colorPath);
  final basename = p.basenameWithoutExtension(colorPath);
  final maskBase = basename.startsWith('ndvi_color_')
      ? basename.replaceFirst('ndvi_color_', 'ndvi_green_mask_')
      : '${basename}_green_mask';
  final refinedTag = refined ? '_refined' : '';
  return p.join(dir, '$maskBase$refinedTag${extension.isEmpty ? '.png' : extension}');
}
