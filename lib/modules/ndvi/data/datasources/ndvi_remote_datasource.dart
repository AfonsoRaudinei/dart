import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';

/// Datasource remoto — chama a Edge Function `ndvi-fetch` no Supabase.
///
/// ⚠️ NUNCA chama Sentinel Hub ou Planet diretamente.
/// Credenciais ficam exclusivamente nos secrets do Supabase.
class NdviRemoteDatasource {
  final SupabaseClient _client;

  const NdviRemoteDatasource(this._client);

  /// Invoca `ndvi-fetch` e retorna [NdviImageModel] ou null em caso de erro.
  ///
  /// - [date] null → mais recente (Edge Function decide).
  Future<NdviImageModel?> fetchNdvi({
    required String areaId,
    required List<double> bbox,
    String? date,
    String source = 'auto',
  }) async {
    try {
      final body = <String, dynamic>{
        'area_id': areaId,
        'bbox': bbox,
        'source': source,
      };
      if (date != null) body['date'] = date;

      final response = await _client.functions.invoke(
        'ndvi-fetch',
        body: body,
      );

      // 404 = sem imagens — retorno silencioso (não é erro de infraestrutura)
      if (response.status == 404) return null;

      if (response.status != 200) {
        throw Exception(
          'ndvi-fetch retornou HTTP ${response.status}: ${response.data}',
        );
      }

      final data = response.data as Map<String, dynamic>;
      return NdviImageModel.fromEdgeJson(data);
    } catch (e) {
      // Falha de rede ou timeout — datasource reporta null para o repositório
      // aplicar fallback de cache.
      return null;
    }
  }
}
