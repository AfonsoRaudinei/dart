import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/visit_session.dart';
import '../../domain/models/visit_stats.dart';
import 'visit_controller.dart';

// --- DASHBOARD ---
final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats>((
  ref,
) async {
  final repository = ref.watch(visitRepositoryProvider);
  // Force refresh when visit state changes (e.g. session starts/ends)
  ref.watch(visitControllerProvider);
  return repository.getDashboardStats();
});

// --- KPIs ---
class DateRangeFilter {
  final DateTime start;
  final DateTime end;
  const DateRangeFilter(this.start, this.end);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRangeFilter &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

final visitStatsProvider = FutureProvider.family
    .autoDispose<VisitStats, DateRangeFilter>((ref, filter) async {
      final repository = ref.watch(visitRepositoryProvider);
      return repository.getVisitStats(filter.start, filter.end);
    });

// --- HISTÓRICO ---
class HistoryFilter {
  final DateTime start;
  final DateTime end;
  final String? producerId;
  final String? activityType;

  const HistoryFilter({
    required this.start,
    required this.end,
    this.producerId,
    this.activityType,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryFilter &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end &&
          producerId == other.producerId &&
          activityType == other.activityType;

  @override
  int get hashCode =>
      start.hashCode ^
      end.hashCode ^
      producerId.hashCode ^
      activityType.hashCode;
}

final visitHistoryProvider = FutureProvider.family
    .autoDispose<List<VisitSession>, HistoryFilter>((ref, filter) async {
      final repository = ref.watch(visitRepositoryProvider);
      return repository.getHistory(
        start: filter.start,
        end: filter.end,
        producerId: filter.producerId,
        activityType: filter.activityType,
      );
    });
