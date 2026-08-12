import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/feedback_config.dart';
import '../../../../core/network/network_policy.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/entities/feedback_impact.dart';
import '../../domain/entities/feedback_module.dart';
import '../../domain/entities/feedback_stats.dart';
import '../../domain/entities/feedback_type.dart';
import '../../domain/feedback_submission_exception.dart';
import '../../domain/repositories/i_feedback_repository.dart';

class SupabaseFeedbackRepository implements IFeedbackRepository {
  SupabaseFeedbackRepository({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  static const _table = FeedbackConfig.supabaseTable;

  @override
  Future<FeedbackStats> getStats() async {
    try {
      final response = await NetworkPolicy.withTimeout(
        () => _client
            .from(_table)
            .select('tipo,modulo')
            .withConverter((rows) => rows as List<dynamic>),
      );

      int bugs = 0, suggestions = 0, praise = 0;
      final suggestionsByModule = <FeedbackModule, int>{};
      for (final row in response) {
        switch (row['tipo'] as String?) {
          case 'Bug':
            bugs++;
          case 'Sugestão':
            suggestions++;
            final module = FeedbackModule.fromLabel(row['modulo'] as String?);
            suggestionsByModule[module] =
                (suggestionsByModule[module] ?? 0) + 1;
          case 'Elogios':
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
    if (user == null) {
      throw const FeedbackSubmissionException(
        'Faça login para enviar feedback.',
      );
    }

    final normalizedMessage = message.trim();
    if (normalizedMessage.isEmpty) {
      throw const FeedbackSubmissionException(
        'Por favor, escreva sua mensagem.',
      );
    }

    final payload = {
      'user_id': user.id,
      'tipo': type.label,
      'modulo': module.label,
      'impacto': impact.label,
      'mensagem': normalizedMessage,
    };

    await NetworkPolicy.withTimeout(
      () => _client.from(_table).insert(payload),
    );

    await _notifyByEmail(
      tipo: type.label,
      modulo: module.label,
      impacto: impact.label,
      mensagem: normalizedMessage,
      userEmail: user.email,
    );
  }

  Future<void> _notifyByEmail({
    required String tipo,
    required String modulo,
    required String impacto,
    required String mensagem,
    required String? userEmail,
  }) async {
    try {
      await _client.functions.invoke(
        FeedbackConfig.notifyFunction,
        body: {
          'tipo': tipo,
          'modulo': modulo,
          'impacto': impacto,
          'mensagem': mensagem,
          'user_email': userEmail,
        },
      );
    } catch (e) {
      AppLogger.warning(
        'Notificação por e-mail falhou (feedback já salvo)',
        tag: 'FeedbackRepository',
        error: e,
      );
    }
  }
}
