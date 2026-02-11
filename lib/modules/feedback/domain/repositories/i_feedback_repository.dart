import '../entities/feedback_stats.dart';
import '../entities/feedback_type.dart';

abstract class IFeedbackRepository {
  Future<FeedbackStats> getStats();
  Future<void> sendFeedback({
    required FeedbackType type,
    required String message,
  });
}
