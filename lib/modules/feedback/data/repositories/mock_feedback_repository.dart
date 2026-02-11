import '../../domain/entities/feedback_stats.dart';
import '../../domain/entities/feedback_type.dart';
import '../../domain/repositories/i_feedback_repository.dart';

class MockFeedbackRepository implements IFeedbackRepository {
  @override
  Future<FeedbackStats> getStats() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 800));
    return FeedbackStats.mock();
  }

  @override
  Future<void> sendFeedback({
    required FeedbackType type,
    required String message,
  }) async {
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    // Success scenario
    return;
  }
}
