class FeedbackStats {
  final int bugCount;
  final int suggestionCount;
  final int praiseCount;

  const FeedbackStats({
    required this.bugCount,
    required this.suggestionCount,
    required this.praiseCount,
  });

  // Factory constructor for mock data
  factory FeedbackStats.mock() {
    return const FeedbackStats(
      bugCount: 12,
      suggestionCount: 28,
      praiseCount: 45,
    );
  }
}
