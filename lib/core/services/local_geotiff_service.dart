import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class LocalGeoTiffImportResult {
  final String pngPath;
  final double south;
  final double west;
  final double north;
  final double east;

  const LocalGeoTiffImportResult({
    required this.pngPath,
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });
}

class LocalGeoTiffException implements Exception {
  final String message;

  const LocalGeoTiffException(this.message);

  @override
  String toString() => message;
}

/// Importa GeoTIFF local norte-alinhado em EPSG:4326 como overlay persistente.
class LocalGeoTiffService {
  const LocalGeoTiffService();

  static const _maxSourceBytes = 250 * 1024 * 1024;
  static const _maxPixels = 40 * 1000 * 1000;
  static const _modelPixelScaleTag = 33550;
  static const _modelTiepointTag = 33922;
  static const _geoKeyDirectoryTag = 34735;
  static const _geographicTypeGeoKey = 2048;

  Future<LocalGeoTiffImportResult> importFile(String sourcePath) async {
    final source = File(sourcePath);
    if (await source.length() > _maxSourceBytes) {
      throw const LocalGeoTiffException(
        'GeoTIFF local excede 250 MB. Gere tiles XYZ ou use um endpoint TiTiler.',
      );
    }
    final bytes = await source.readAsBytes();
    final decoded = await Isolate.run(() => _decode(bytes));

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/local_geotiff');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    final path =
        '${dir.path}/geotiff_${DateTime.now().millisecondsSinceEpoch}.png';
    await File(path).writeAsBytes(decoded.pngBytes, flush: true);

    return LocalGeoTiffImportResult(
      pngPath: path,
      south: decoded.south,
      west: decoded.west,
      north: decoded.north,
      east: decoded.east,
    );
  }

  static ({
    List<int> pngBytes,
    double south,
    double west,
    double north,
    double east,
  })
  _decode(Uint8List bytes) {
    final decoder = img.TiffDecoder();
    final info = decoder.startDecode(bytes);
    if (info == null) {
      throw const LocalGeoTiffException(
        'Arquivo TIFF inválido ou não suportado.',
      );
    }
    if (info.width * info.height > _maxPixels) {
      throw const LocalGeoTiffException(
        'GeoTIFF local excede 40 megapixels. Gere tiles XYZ ou use um endpoint TiTiler.',
      );
    }
    final raster = decoder.decodeFrame(0);
    if (raster == null) {
      throw const LocalGeoTiffException(
        'Não foi possível decodificar o raster GeoTIFF.',
      );
    }

    final geo = const LocalGeoTiffService()._readGeoReference(
      bytes,
      raster.width,
      raster.height,
    );
    return (
      pngBytes: img.encodePng(raster),
      south: geo.south,
      west: geo.west,
      north: geo.north,
      east: geo.east,
    );
  }

  Future<void> deleteImportedOverlay(String? path) async {
    if (path == null || path.isEmpty) return;
    final file = File(path);
    if (file.existsSync()) await file.delete();
  }

  ({double south, double west, double north, double east}) _readGeoReference(
    Uint8List bytes,
    int width,
    int height,
  ) {
    final data = ByteData.sublistView(bytes);
    if (data.lengthInBytes < 8) {
      throw const LocalGeoTiffException('Cabeçalho GeoTIFF inválido.');
    }
    final marker = String.fromCharCodes(bytes.sublist(0, 2));
    final endian = marker == 'II'
        ? Endian.little
        : marker == 'MM'
        ? Endian.big
        : null;
    if (endian == null || data.getUint16(2, endian) != 42) {
      throw const LocalGeoTiffException('Cabeçalho TIFF inválido.');
    }

    final ifdOffset = data.getUint32(4, endian);
    if (ifdOffset + 2 > data.lengthInBytes) {
      throw const LocalGeoTiffException('Diretório GeoTIFF inválido.');
    }
    final count = data.getUint16(ifdOffset, endian);
    final tags = <int, List<num>>{};
    for (int i = 0; i < count; i++) {
      final offset = ifdOffset + 2 + (i * 12);
      if (offset + 12 > data.lengthInBytes) break;
      final tag = data.getUint16(offset, endian);
      final type = data.getUint16(offset + 2, endian);
      final valueCount = data.getUint32(offset + 4, endian);
      final values = _readValues(data, offset + 8, type, valueCount, endian);
      if (values != null) tags[tag] = values;
    }

    final scale = tags[_modelPixelScaleTag];
    final tiepoint = tags[_modelTiepointTag];
    final geoKeys = tags[_geoKeyDirectoryTag]?.map((e) => e.toInt()).toList();
    if (scale == null ||
        scale.length < 2 ||
        tiepoint == null ||
        tiepoint.length < 6) {
      throw const LocalGeoTiffException(
        'GeoTIFF sem ModelPixelScale/ModelTiepoint. Exporte como raster norte-alinhado.',
      );
    }
    if (!_isEpsg4326(geoKeys)) {
      throw const LocalGeoTiffException(
        'GeoTIFF local suporta EPSG:4326. Reprojete o mosaico antes de importar.',
      );
    }

    final west = tiepoint[3].toDouble() - (tiepoint[0].toDouble() * scale[0]);
    final north = tiepoint[4].toDouble() + (tiepoint[1].toDouble() * scale[1]);
    final east = west + (width * scale[0]);
    final south = north - (height * scale[1]);
    return (south: south, west: west, north: north, east: east);
  }

  bool _isEpsg4326(List<int>? keys) {
    if (keys == null || keys.length < 4) return false;
    final keyCount = keys[3];
    for (int i = 0; i < keyCount; i++) {
      final offset = 4 + (i * 4);
      if (offset + 3 >= keys.length) break;
      if (keys[offset] == _geographicTypeGeoKey &&
          keys[offset + 1] == 0 &&
          keys[offset + 3] == 4326) {
        return true;
      }
    }
    return false;
  }

  List<num>? _readValues(
    ByteData data,
    int inlineOffset,
    int type,
    int count,
    Endian endian,
  ) {
    final size = switch (type) {
      3 => 2,
      4 => 4,
      12 => 8,
      _ => 0,
    };
    if (size == 0) return null;
    final byteLength = size * count;
    final valueOffset = byteLength <= 4
        ? inlineOffset
        : data.getUint32(inlineOffset, endian);
    if (valueOffset + byteLength > data.lengthInBytes) return null;

    return List<num>.generate(count, (i) {
      final offset = valueOffset + (i * size);
      return switch (type) {
        3 => data.getUint16(offset, endian),
        4 => data.getUint32(offset, endian),
        12 => data.getFloat64(offset, endian),
        _ => 0,
      };
    });
  }
}
