import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;

import '../../../core/contracts/i_ndvi_latest_lookup.dart';
import '../../../core/contracts/ndvi_latest_summary.dart';
import '../data/processing/ndvi_green_mask_processor.dart';
import '../data/repositories/i_ndvi_repository.dart';
import '../domain/ndvi_image_utils.dart';

/// Lookup neutro da última imagem NDVI. ADR-045.
class NdviLatestLookupAdapter implements INdviLatestLookup {
  NdviLatestLookupAdapter(this._repository);

  final INdviRepository _repository;

  @override
  Future<NdviLatestSummary?> getLatest(String fieldId) async {
    final image = await _repository.getLatestByFieldId(fieldId);
    if (image == null || !ndviImageHasRenderableData(image)) return null;

    String? greenMaskLocalPath;
    final localPath = image.localPath;
    if (localPath != null &&
        localPath.isNotEmpty &&
        ndviSupportsGreenMask(image.source)) {
      greenMaskLocalPath = await _resolveGreenMaskPath(localPath);
    }

    return NdviLatestSummary(
      imageDate: image.imageDate,
      ndviMean: image.ndviMean,
      ndviMin: image.ndviMin,
      ndviMax: image.ndviMax,
      sourceLabel: ndviSourceLabel(image.source),
      source: normalizeNdviSource(image.source),
      isColormap: ndviIsColormapSource(image.source),
      localPath: image.localPath,
      imageUrl: image.imageUrl,
      greenMaskLocalPath: greenMaskLocalPath,
    );
  }

  Future<String?> _resolveGreenMaskPath(String colorPath) async {
    try {
      final colorFile = File(colorPath);
      if (!await colorFile.exists()) return null;

      final maskPath = _greenMaskPathFor(colorPath);
      final maskFile = File(maskPath);
      final colorStat = await colorFile.stat();
      if (await maskFile.exists()) {
        final maskStat = await maskFile.stat();
        if (!maskStat.modified.isBefore(colorStat.modified)) {
          return maskPath;
        }
      }

      final bytes = await colorFile.readAsBytes();
      final source = img.decodeImage(bytes);
      if (source == null) return null;

      final mask = applyNdviGreenMask(source);
      final maskBytes = Uint8List.fromList(img.encodePng(mask));
      await maskFile.writeAsBytes(maskBytes, flush: true);
      return maskPath;
    } catch (_) {
      return null;
    }
  }

  String _greenMaskPathFor(String colorPath) {
    final dir = p.dirname(colorPath);
    final extension = p.extension(colorPath);
    final basename = p.basenameWithoutExtension(colorPath);
    final maskBase = basename.startsWith('ndvi_color_')
        ? basename.replaceFirst('ndvi_color_', 'ndvi_green_mask_')
        : '${basename}_green_mask';
    return p.join(dir, '$maskBase${extension.isEmpty ? '.png' : extension}');
  }
}
