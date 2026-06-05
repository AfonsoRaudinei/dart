import '../entities/feedback_impact.dart';
import '../entities/feedback_module.dart';
import '../entities/feedback_stats.dart';
import '../entities/feedback_type.dart';

abstract class IFeedbackRepository {
  Future<FeedbackStats> getStats();
  Future<void> sendFeedback({
    required FeedbackType type,
    required FeedbackModule module,
    required FeedbackImpact impact,
    required String message,
  });
}
