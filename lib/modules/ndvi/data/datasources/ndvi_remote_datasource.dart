import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';

class NdviRemoteDatasource {
  final SupabaseClient _client;

  const NdviRemoteDatasource(this._client);

  Future<NdviImageModel?> fetchNdvi({
    required String fieldId,
    required List<double> bbox,
    String? date,
    String source = 'auto',
  }) async {
    try {
      final body = <String, dynamic>{
        'field_id': fieldId,
        'bbox': bbox,
        'source': source,
      };
      if (date != null) body['date'] = date;

      final response = await _client.functions.invoke(
        'ndvi-fetch',
        body: body,
      );

      if (response.status == 404) return null;

      if (response.status != 200) {
        throw Exception(
          'ndvi-fetch retornou HTTP ${response.status}: ${response.data}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      
      return NdviImageModel(
        id: data['id'] as String? ?? '${fieldId}_${data['date']}',
        fieldId: fieldId,
        imageDate: data['date'] as String? ?? data['image_date'] as String? ?? '',
        ndviMin: (data['ndvi_min'] as num?)?.toDouble() ?? 0.0,
        ndviMax: (data['ndvi_max'] as num?)?.toDouble() ?? 0.0,
        ndviMean: (data['ndvi_mean'] as num?)?.toDouble() ?? 0.0,
        imageUrl: data['image_url'] as String?,
        localPath: null,
        source: data['source'] as String? ?? 'auto',
        fetchedAt: DateTime.now().toIso8601String(),
        syncStatus: 0,
      );
    } catch (e) {
      return null;
    }
  }
}
