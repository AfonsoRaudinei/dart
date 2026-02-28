class FeedbackStats {
  final int bugCount;
  final int suggestionCount;
  final int praiseCount;

  const FeedbackStats({
    required this.bugCount,
    required this.suggestionCount,
    required this.praiseCount,
  });

  factory FeedbackStats.empty() {
    return const FeedbackStats(bugCount: 0, suggestionCount: 0, praiseCount: 0);
  }
}
