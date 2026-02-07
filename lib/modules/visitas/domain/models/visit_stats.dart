class VisitStats {
  final int totalVisits;
  final int totalDurationMinutes;
  final double averageDurationMinutes;
  final Map<String, int> visitsByProducer;
  final Map<String, int> visitsByActivity;

  VisitStats({
    required this.totalVisits,
    required this.totalDurationMinutes,
    required this.averageDurationMinutes,
    required this.visitsByProducer,
    required this.visitsByActivity,
  });

  factory VisitStats.empty() {
    return VisitStats(
      totalVisits: 0,
      totalDurationMinutes: 0,
      averageDurationMinutes: 0,
      visitsByProducer: {},
      visitsByActivity: {},
    );
  }
}

class DashboardStats {
  final int totalVisitsToday;
  final int totalMinutesToday;
  final int activeVisits;
  final String? activeProducerId;
  final int activeDurationMinutes; // Duration only of the current active visit

  DashboardStats({
    required this.totalVisitsToday,
    required this.totalMinutesToday,
    required this.activeVisits,
    this.activeProducerId,
    required this.activeDurationMinutes,
  });

  factory DashboardStats.empty() {
    return DashboardStats(
      totalVisitsToday: 0,
      totalMinutesToday: 0,
      activeVisits: 0,
      activeDurationMinutes: 0,
    );
  }
}
