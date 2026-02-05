import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/report_repository.dart';
import '../../domain/report_model.dart';

final reportRepositoryProvider = Provider((ref) => ReportRepository());

// Base List
final reportsListProvider = FutureProvider.autoDispose<List<Report>>((
  ref,
) async {
  final repo = ref.watch(reportRepositoryProvider);
  return repo.getReports();
});

// Filter
final reportFilterProvider = StateProvider<String>((ref) => 'Meus');

// Filtered List (Placeholder logic for now as requested: "placeholder visual, sem lógica")
final filteredReportsProvider = Provider.autoDispose<AsyncValue<List<Report>>>((
  ref,
) {
  final reportsAsync = ref.watch(reportsListProvider);
  final filter = ref.watch(reportFilterProvider);

  return reportsAsync.whenData((reports) {
    if (filter == 'Compartilhados') {
      return []; // Placeholder: empty or specific mock
    }
    return reports;
  });
});

final reportDetailProvider = FutureProvider.family.autoDispose<Report?, String>(
  (ref, id) async {
    final repo = ref.watch(reportRepositoryProvider);
    return repo.getReport(id);
  },
);

class ReportController {
  final Ref ref;
  ReportController(this.ref);

  Future<void> saveReport(Report report) async {
    final repo = ref.read(reportRepositoryProvider);
    await repo.saveReport(report);
    ref.invalidate(reportsListProvider);
    // Remove individual cache if exists
    ref.invalidate(reportDetailProvider(report.id));
  }
}

final reportControllerProvider = Provider((ref) => ReportController(ref));
