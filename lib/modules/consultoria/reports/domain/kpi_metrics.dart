class KpiMetrics {
  final int totalVisits;
  final int totalDaysWorked;
  final double averageVisitsPerDay;
  final double totalHoursInField;
  final double averageVisitDurationMinutes;

  // Client Efficiency
  final int uniqueClientsVisited;
  final double averageVisitsPerClient;
  final String? mostVisitedClientId;

  // Operational
  final double percentageLongVisits; // > 4h

  // Technical Intensity (Requires joining with occurrences which we simulated in report content,
  // but for proper metrics we should query the occurrences table. Here we use report count if available or separate query).
  // Use a map for dynamic indicators
  final Map<String, int> visitsByActivityType;

  KpiMetrics({
    required this.totalVisits,
    required this.totalDaysWorked,
    required this.averageVisitsPerDay,
    required this.totalHoursInField,
    required this.averageVisitDurationMinutes,
    required this.uniqueClientsVisited,
    required this.averageVisitsPerClient,
    this.mostVisitedClientId,
    required this.percentageLongVisits,
    required this.visitsByActivityType,
  });

  factory KpiMetrics.empty() {
    return KpiMetrics(
      totalVisits: 0,
      totalDaysWorked: 0,
      averageVisitsPerDay: 0,
      totalHoursInField: 0,
      averageVisitDurationMinutes: 0,
      uniqueClientsVisited: 0,
      averageVisitsPerClient: 0,
      percentageLongVisits: 0,
      visitsByActivityType: {},
    );
  }
}
