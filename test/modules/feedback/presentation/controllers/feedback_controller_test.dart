import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/feedback/domain/entities/feedback_impact.dart';
import 'package:soloforte_app/modules/feedback/domain/entities/feedback_module.dart';
import 'package:soloforte_app/modules/feedback/domain/entities/feedback_stats.dart';
import 'package:soloforte_app/modules/feedback/domain/entities/feedback_type.dart';
import 'package:soloforte_app/modules/feedback/domain/repositories/i_feedback_repository.dart';
import 'package:soloforte_app/modules/feedback/presentation/controllers/feedback_controller.dart';

// Manual Fake implementation
class FakeFeedbackRepository implements IFeedbackRepository {
  FeedbackStats? statsResponse;
  bool shouldThrowError = false;
  Map<String, dynamic>? lastSubmission;

  @override
  Future<FeedbackStats> getStats() async {
    if (shouldThrowError) throw Exception('Fake error');
    return statsResponse ?? FeedbackStats.empty();
  }

  @override
  Future<void> sendFeedback({
    required FeedbackType type,
    required FeedbackModule module,
    required FeedbackImpact impact,
    required String message,
  }) async {
    if (shouldThrowError) throw Exception('Fake error');
    lastSubmission = {
      'type': type,
      'module': module,
      'impact': impact,
      'message': message,
    };
  }
}

void main() {
  late FakeFeedbackRepository fakeRepository;
  late ProviderContainer container;

  setUp(() {
    fakeRepository = FakeFeedbackRepository();

    // Override the repository provider
    container = ProviderContainer(
      overrides: [feedbackRepositoryProvider.overrideWithValue(fakeRepository)],
    );
  });

  tearDown(() {
    container.dispose();
  });

  test('feedbackStatsProvider should load stats', () async {
    final stats = const FeedbackStats(
      bugCount: 1,
      suggestionCount: 1,
      praiseCount: 1,
      suggestionsByModule: {FeedbackModule.agenda: 1},
    );
    fakeRepository.statsResponse = stats;

    final asyncValue = await container.read(feedbackStatsProvider.future);

    expect(asyncValue, stats);
  });

  test('FeedbackController - Submit success', () async {
    final controller = container.read(feedbackControllerProvider.notifier);

    await controller.submitFeedback(
      type: FeedbackType.bug,
      module: FeedbackModule.agenda,
      impact: FeedbackImpact.high,
      message: ' Test ',
    );

    final state = container.read(feedbackControllerProvider);
    expect(state.isSuccess, true);
    expect(state.isSubmitting, false);
    expect(fakeRepository.lastSubmission!['module'], FeedbackModule.agenda);
    expect(fakeRepository.lastSubmission!['impact'], FeedbackImpact.high);
    expect(fakeRepository.lastSubmission!['message'], 'Test');
  });

  test('FeedbackController - Submit error', () async {
    fakeRepository.shouldThrowError = true;
    final controller = container.read(feedbackControllerProvider.notifier);

    await controller.submitFeedback(
      type: FeedbackType.bug,
      module: FeedbackModule.agenda,
      impact: FeedbackImpact.high,
      message: 'Test',
    );

    final state = container.read(feedbackControllerProvider);
    expect(state.isSuccess, false);
    expect(state.errorMessage, isNotNull);
  });
}
