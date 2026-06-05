import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/network_policy.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/feedback_impact.dart';
import '../../domain/entities/feedback_module.dart';
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
            .select('type,module')
            .withConverter((rows) => rows as List<dynamic>),
      );

      int bugs = 0, suggestions = 0, praise = 0;
      final suggestionsByModule = <FeedbackModule, int>{};
      for (final row in response) {
        switch (row['type'] as String?) {
          case 'bug':
            bugs++;
          case 'suggestion':
            suggestions++;
            final module = FeedbackModule.fromStorageValue(
              row['module'] as String?,
            );
            suggestionsByModule[module] =
                (suggestionsByModule[module] ?? 0) + 1;
          case 'praise':
            praise++;
        }
      }
      return FeedbackStats(
        bugCount: bugs,
        suggestionCount: suggestions,
        praiseCount: praise,
        suggestionsByModule: suggestionsByModule,
      );
    } catch (e, st) {
      AppLogger.error(
        'Falha ao carregar estatísticas de feedback',
        tag: 'FeedbackRepository',
        error: e,
        stackTrace: st,
      );
      return FeedbackStats.unavailable();
    }
  }

  @override
  Future<void> sendFeedback({
    required FeedbackType type,
    required FeedbackModule module,
    required FeedbackImpact impact,
    required String message,
  }) async {
    final user = _client.auth.currentUser;
    await NetworkPolicy.withTimeout(
      () => _client.from('feedback').insert({
        'user_id': user?.id,
        'type': type.name,
        'module': module.storageValue,
        'impact': impact.storageValue,
        'message': message,
        'created_at': DateTime.now().toIso8601String(),
      }),
    );
  }
}
