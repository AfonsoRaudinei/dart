import 'package:supabase_flutter/supabase_flutter.dart';

class AgendaAiService {
  AgendaAiService(this._client);

  final SupabaseClient _client;

  Future<Map<String, dynamic>> recommend({
    required Map<String, dynamic> payload,
  }) async {
    final response = await _client.functions.invoke(
      'agenda-ai-recommend',
      body: payload,
    );

    if (response.status != 200) {
      throw Exception(
        'agenda-ai-recommend HTTP ${response.status}: ${response.data}',
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((k, v) => MapEntry(k.toString(), v));
    }

    throw Exception('Resposta inválida do agenda-ai-recommend.');
  }
}
