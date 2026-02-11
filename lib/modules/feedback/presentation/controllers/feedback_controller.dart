import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/repositories/mock_feedback_repository.dart';
import '../../domain/entities/feedback_stats.dart';
import '../../domain/entities/feedback_type.dart';
import '../../domain/repositories/i_feedback_repository.dart';
import 'feedback_state.dart';

part 'feedback_controller.g.dart';

@riverpod
IFeedbackRepository feedbackRepository(Ref ref) {
  return MockFeedbackRepository();
}

// Separate provider for stats (FutureProvider pattern)
@riverpod
Future<FeedbackStats> feedbackStats(Ref ref) async {
  final repository = ref.watch(feedbackRepositoryProvider);
  return repository.getStats();
}

// Controller handles ONLY form submission
@riverpod
class FeedbackController extends _$FeedbackController {
  @override
  FeedbackFormState build() {
    return const FeedbackFormState();
  }

  Future<void> submitFeedback({
    required FeedbackType type,
    required String message,
  }) async {
    if (state.isSubmitting) return;

    state = state.copyWith(isSubmitting: true, errorMessage: null);

    try {
      final repository = ref.read(feedbackRepositoryProvider);
      await repository.sendFeedback(type: type, message: message);
      state = state.copyWith(isSubmitting: false, isSuccess: true);

      // Optional: Refresh stats after submission if needed
      // ref.invalidate(feedbackStatsProvider);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Falha ao enviar feedback. Tente novamente.',
      );
    }
  }

  void reset() {
    // Reset state to initial
    ref.invalidateSelf();
  }
}
