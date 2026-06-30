import 'feedback_module.dart';

class FeedbackStats {
  final int bugCount;
  final int suggestionCount;
  final int praiseCount;
  final Map<FeedbackModule, int> suggestionsByModule;
  final bool isUnavailable;

  const FeedbackStats({
    required this.bugCount,
    required this.suggestionCount,
    required this.praiseCount,
    this.suggestionsByModule = const {},
    this.isUnavailable = false,
  });

  factory FeedbackStats.empty() {
    return const FeedbackStats(bugCount: 0, suggestionCount: 0, praiseCount: 0);
  }

  factory FeedbackStats.unavailable() {
    return const FeedbackStats(
      bugCount: 0,
      suggestionCount: 0,
      praiseCount: 0,
      isUnavailable: true,
    );
  }
}
