import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/kpi_metrics.dart';
import '../../data/sqlite_report_repository.dart';

// Provider local — SQLiteReportRepository vive em consultoria/, não em visitas/.
// Movido de visit_controller.dart para cá em ADR-024 PROMPT 06.
final sqliteReportRepositoryProvider = Provider<SQLiteReportRepository>((ref) {
  return SQLiteReportRepository();
});

// Params class for KPI filtering
class KpiFilter {
  final DateTime? start;
  final DateTime? end;

  const KpiFilter({this.start, this.end});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is KpiFilter &&
          runtimeType == other.runtimeType &&
          start == other.start &&
          end == other.end;

  @override
  int get hashCode => start.hashCode ^ end.hashCode;
}

// Global Provider for KPIs
final kpiMetricsProvider = FutureProvider.family
    .autoDispose<KpiMetrics, KpiFilter>((ref, filter) async {
      final repo = ref.watch(sqliteReportRepositoryProvider);
      return repo.getKpiMetrics(start: filter.start, end: filter.end);
    });
