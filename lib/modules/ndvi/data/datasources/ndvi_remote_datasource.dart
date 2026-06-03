import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';

class NdviRemoteDatasource {
  final SupabaseClient _client;
  final NdviImageFileStore _fileStore;

  NdviRemoteDatasource(
    this._client, {
    NdviImageFileStore fileStore = const NdviImageFileStore(),
  }) : _fileStore = fileStore;

  Future<NdviImageModel?> fetchNdvi({
    required String fieldId,
    List<double>? bbox,
    String? geometry,
    String? date,
    String source = 'auto',
  }) async {
    try {
      final body = <String, dynamic>{'area_id': fieldId, 'source': source};
      if (bbox != null) body['bbox'] = bbox;
      final geometryJson = _decodeGeometry(geometry);
      if (geometryJson != null) body['geometry'] = geometryJson;
      if (date != null) body['date'] = date;

      final response = await _client.functions.invoke('ndvi-fetch', body: body);

      if (response.status == 404) return null;

      if (response.status != 200) {
        throw Exception(
          'ndvi-fetch retornou HTTP ${response.status}: ${response.data}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      return modelFromFunctionData(data: data, fieldId: fieldId);
    } catch (e) {
      return null;
    }
  }

  Future<NdviImageModel> modelFromFunctionData({
    required Map<String, dynamic> data,
    required String fieldId,
  }) async {
    final imageDate =
        data['date'] as String? ?? data['image_date'] as String? ?? '';
    final source = data['source'] as String? ?? 'auto';
    final id = data['id'] as String? ?? '${fieldId}_$imageDate';
    final imageBase64 = data['image_base64'] as String?;
    final localPath = imageBase64 == null || imageBase64.isEmpty
        ? null
        : await _fileStore.saveBase64Png(
            imageBase64: imageBase64,
            fieldId: fieldId,
            imageDate: imageDate,
          );

    return NdviImageModel(
      id: id,
      fieldId: fieldId,
      imageDate: imageDate,
      ndviMin: (data['ndvi_min'] as num?)?.toDouble() ?? 0.0,
      ndviMax: (data['ndvi_max'] as num?)?.toDouble() ?? 0.0,
      ndviMean: (data['ndvi_mean'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['image_url'] as String?,
      localPath: localPath,
      source: source,
      fetchedAt: DateTime.now().toIso8601String(),
      syncStatus: 0,
    );
  }
}

class NdviImageFileStore {
  final Future<Directory> Function()? _directoryProvider;

  const NdviImageFileStore({Future<Directory> Function()? directoryProvider})
    : _directoryProvider = directoryProvider;

  Future<String> saveBase64Png({
    required String imageBase64,
    required String fieldId,
    required String imageDate,
  }) async {
    final docs = _directoryProvider == null
        ? await getApplicationDocumentsDirectory()
        : await _directoryProvider();
    final dir = Directory(p.join(docs.path, 'ndvi'));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final fileName = [
      'ndvi_color',
      _safePathSegment(fieldId),
      _safePathSegment(imageDate),
    ].join('_');
    final file = File(p.join(dir.path, '$fileName.png'));
    await file.writeAsBytes(base64Decode(imageBase64), flush: true);
    return file.path;
  }

  String _safePathSegment(String value) {
    final sanitized = value.replaceAll(RegExp(r'[^a-zA-Z0-9._-]+'), '-');
    return sanitized.isEmpty ? 'unknown' : sanitized;
  }
}

Map<String, dynamic>? _decodeGeometry(String? geometry) {
  if (geometry == null || geometry.isEmpty) return null;
  try {
    final decoded = jsonDecode(geometry);
    return decoded is Map<String, dynamic> ? decoded : null;
  } catch (_) {
    return null;
  }
}
