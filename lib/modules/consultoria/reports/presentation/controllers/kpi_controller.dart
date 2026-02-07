import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/kpi_metrics.dart';
import '../../../../visitas/presentation/controllers/visit_controller.dart'
    show sqliteReportRepositoryProvider;

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
