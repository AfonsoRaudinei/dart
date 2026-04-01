// lib/modules/consultoria/reports/infra/visit_report_adapter.dart
//
// Adapter autorizado: implementa IVisitReportRepository usando SQLiteReportRepository.
// É a única ponte entre core/contracts/IVisitReportRepository e consultoria/reports/.
//
// ADR-024 — DT-023-3
// NÃO importar este arquivo fora de consultoria/ ou da injeção de dependência.
//
// ReportType.semanal é hardcoded aqui — visitas técnicas sempre geram
// relatório do tipo semanal. Não expor ReportType na interface neutra.

import 'package:soloforte_app/core/contracts/i_visit_report_repository.dart';
import '../data/sqlite_report_repository.dart';
import '../domain/report_model.dart';

/// Implementação concreta de IVisitReportRepository.
/// Vive em consultoria/reports/infra/ — dona dos dados de relatório.
class VisitReportAdapter implements IVisitReportRepository {
  const VisitReportAdapter(this._repository);

  final SQLiteReportRepository _repository;

  @override
  Future<void> saveVisitReport(VisitReportData data, String sessionId) async {
    final report = Report(
      id: data.id,
      title: data.title,
      type: ReportType.semanal, // hardcode — visitas sempre geram tipo semanal
      clientId: data.clientId,
      startDate: data.startDate,
      endDate: data.endDate,
      content: data.content,
      createdAt: data.createdAt,
      author: data.author,
      observations: data.observations,
      // images não usadas em visitas técnicas
    );
    await _repository.saveReport(report, sessionId);
  }
}
