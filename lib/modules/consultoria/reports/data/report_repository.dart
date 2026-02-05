import '../domain/report_model.dart';

class ReportRepository {
  // Simulating local database
  final List<Report> _reports = [];

  Future<List<Report>> getReports() async {
    // Return copy to avoid direct mutation
    return List.from(_reports);
  }

  Future<Report?> getReport(String id) async {
    try {
      return _reports.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveReport(Report report) async {
    final index = _reports.indexWhere((r) => r.id == report.id);
    if (index >= 0) {
      _reports[index] = report;
    } else {
      _reports.add(report);
    }
  }

  Future<void> deleteReport(String id) async {
    _reports.removeWhere((r) => r.id == id);
  }

  // Helper to generate dummy data if needed
  void seed() {
    if (_reports.isNotEmpty) return;
    // No dummy data by default as per "Estado isolado" and "Persistência simples"
  }
}
