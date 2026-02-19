import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/network_policy.dart';
import '../../domain/entities/feedback_stats.dart';
import '../../domain/entities/feedback_type.dart';
import '../../domain/repositories/i_feedback_repository.dart';

class SupabaseFeedbackRepository implements IFeedbackRepository {
  final _client = Supabase.instance.client;

  @override
  Future<FeedbackStats> getStats() async {
    try {
      final response = await NetworkPolicy.withTimeout(
        () => _client
            .from('feedback')
            .select('type')
            .withConverter((rows) => rows as List<dynamic>),
      );

      int bugs = 0, suggestions = 0, praise = 0;
      for (final row in response) {
        switch (row['type'] as String?) {
          case 'bug':
            bugs++;
          case 'suggestion':
            suggestions++;
          case 'praise':
            praise++;
        }
      }
      return FeedbackStats(
        bugCount: bugs,
        suggestionCount: suggestions,
        praiseCount: praise,
      );
    } catch (_) {
      // Tabela ainda não existe ou usuário sem acesso — retorna zerado sem crash
      return FeedbackStats.empty();
    }
  }

  @override
  Future<void> sendFeedback({
    required FeedbackType type,
    required String message,
  }) async {
    final user = _client.auth.currentUser;
    await NetworkPolicy.withTimeout(
      () => _client.from('feedback').insert({
        'user_id': user?.id,
        'type': type.name,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      }),
    );
  }
}
